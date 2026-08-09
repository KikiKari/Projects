#!/usr/bin/perl
# log_collector.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/log-collector/scripts/log_collector.py
# auch in: OpenClaw@gateway2:skills/log-collector/scripts/log_collector.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use DBI;
use JSON;
use File::Path qw(make_path);
use File::Spec;
use POSIX qw(strftime);

# Log Collector Sub-Agent
# Sammelt Logs von allen Nodes via SSH/VPN alle 3 Stunden

my $WORKSPACE = "/home/openclaw/.openclaw/workspace";
my $DB_PATH = File::Spec->catfile($WORKSPACE, "db", "logs.db");
my $LOG_DIR = File::Spec->catfile($WORKSPACE, "logs", "log-collector");

# Erstelle LOG_DIR falls nicht existiert
make_path($LOG_DIR) unless -d $LOG_DIR;

package Logger;

sub new {
    my $class = shift;
    my $self = {};
    my $today = strftime('%Y-%m-%d', localtime);
    $self->{log_file} = File::Spec->catfile($LOG_DIR, "$today.log");
    bless $self, $class;
    return $self;
}

sub log {
    my ($self, $level, $msg) = @_;
    my $ts = strftime('%Y-%m-%dT%H:%M:%S', localtime);
    my $line = "[$ts] [$level] $msg\n";
    print $line;
    open(my $fh, '>>', $self->{log_file}) or die "Could not open log file: $!";
    print $fh $line;
    close($fh);
}

sub info {
    my ($self, $msg) = @_;
    $self->log('INFO', $msg);
}

sub error {
    my ($self, $msg) = @_;
    $self->log('ERROR', $msg);
}

package LogCollector;

sub new {
    my $class = shift;
    my $self = {
        logger => Logger->new(),
        conn => undef
    };
    bless $self, $class;
    return $self;
}

sub connect_db {
    my $self = shift;
    $self->{conn} = DBI->connect("dbi:SQLite:dbname=$DB_PATH", "", "", { RaiseError => 1, AutoCommit => 1 });
    $self->{conn}->{sqlite_unicode} = 1;
    # Schema initialisieren falls nicht existiert
    $self->_init_schema();
    return $self->{conn};
}

sub _init_schema {
    my $self = shift;
    my $sth = $self->{conn}->prepare("SELECT name FROM sqlite_master WHERE type='table'");
    $sth->execute();
    my $rows = $sth->fetchall_arrayref();
    if (@$rows == 0) {
        my $schema_path = File::Spec->catfile($WORKSPACE, "db", "logs.db.schema.sql");
        if (-e $schema_path) {
            open(my $fh, '<', $schema_path) or die "Could not open schema file: $!";
            my $schema_sql = do { local $/; <$fh> };
            close($fh);
            $self->{conn}->do($schema_sql);
        }
    }
}

sub get_nodes {
    my $self = shift;
    my $sth = $self->{conn}->prepare("SELECT * FROM nodes");
    $sth->execute();
    my $rows = $sth->fetchall_arrayref({});
    return $rows;
}

sub check_vpn {
    my ($self, $ip) = @_;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(10);
        my $result = system("ping -c 1 -W 3 $ip > /dev/null 2>&1");
        alarm(0);
        return $result == 0;
    };
    if ($@) {
        return 0;
    }
    return 0;
}

sub ssh_connect_and_collect {
    my ($self, $node) = @_;
    my $node_id = $node->{node_id};
    my $vpn_ip = $node->{vpn_ip} || $node->{tailscale_ip} || $node->{wireguard_ip};
    
    if (!$vpn_ip) {
        $self->{logger}->error("$node_id: Keine VPN-IP konfiguriert");
        return undef;
    }
    
    # 1. VPN-Check
    $self->{logger}->info("$node_id: Prüfe VPN $vpn_ip...");
    if (!$self->check_vpn($vpn_ip)) {
        $self->{logger}->error("$node_id: VPN nicht erreichbar");
        $self->_log_ssh_connection($node_id, 'tailscale', 0, 'VPN unreachable');
        return undef;
    }
    
    # 2. SSH-Verbindung
    $self->{logger}->info("$node_id: Verbinde via SSH...");
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(30);
        
        my @log_commands = (
            "journalctl -n 500 --no-pager",
            "tail -n 200 /var/log/syslog 2>/dev/null || echo 'no syslog'",
            "tail -n 200 ~/.openclaw/logs/*.log 2>/dev/null || echo 'no openclaw logs'"
        );
        
        my @logs_collected = ();
        foreach my $cmd (@log_commands) {
            my $ssh_cmd = "ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no openclaw\@$vpn_ip '$cmd'";
            my $output = `$ssh_cmd`;
            my $exit_code = $? >> 8;
            
            if ($exit_code == 0) {
                push @logs_collected, {
                    command => $cmd,
                    output => $output,
                    timestamp => strftime('%Y-%m-%dT%H:%M:%S', localtime)
                };
            }
        }
        
        alarm(0);
        
        # Erfolg loggen
        $self->_log_ssh_connection($node_id, 'ssh', 1, undef);
        
        # In DB speichern
        $self->_insert_logs($node_id, \@logs_collected);
        
        return scalar(@logs_collected);
    };
    
    if ($@) {
        alarm(0);
        if ($@ eq "timeout\n") {
            $self->{logger}->error("$node_id: SSH Timeout");
            $self->_log_ssh_connection($node_id, 'ssh', 0, 'Timeout');
            return undef;
        } else {
            $self->{logger}->error("$node_id: SSH Fehler: $@");
            $self->_log_ssh_connection($node_id, 'ssh', 0, $@);
            return undef;
        }
    }
    
    return undef;
}

sub _log_ssh_connection {
    my ($self, $node_id, $conn_type, $success, $error) = @_;
    my $sth = $self->{conn}->prepare(q{
        INSERT INTO ssh_connections (node_id, connection_type, success, error_message)
        VALUES (?, ?, ?, ?)
    });
    $sth->execute($node_id, $conn_type, $success, $error);
}

sub _insert_logs {
    my ($self, $node_id, $logs) = @_;
    my $sth = $self->{conn}->prepare(q{
        INSERT INTO logs (node_id, log_type, source, content, severity, 
                         collected_by, collection_method, retention_until)
        VALUES (?, 'system', ?, ?, 'info', ?, 'ssh', ?)
    });
    
    my $retention = strftime('%Y-%m-%d %H:%M:%S', localtime(time + 30*24*60*60));
    
    foreach my $log_entry (@$logs) {
        my $source = substr($log_entry->{command}, 0, 50);
        my $content = substr($log_entry->{output}, 0, 10000);
        $sth->execute($node_id, $source, $content, 'node1', $retention);
    }
    
    $self->{logger}->info("$node_id: " . scalar(@$logs) . " Log-Einträge gespeichert");
}

sub cleanup_retention {
    my $self = shift;
    my $sth = $self->{conn}->prepare(q{
        DELETE FROM logs WHERE retention_until < datetime('now')
    });
    $sth->execute();
    my $deleted = $sth->rows;
    $self->{logger}->info("Retention-Cleanup: $deleted alte Logs gelöscht");
    return $deleted;
}

sub run_collection_cycle {
    my $self = shift;
    $self->{logger}->info("=" x 60);
    $self->{logger}->info("LOG COLLECTOR CYCLE START");
    $self->{logger}->info("=" x 60);
    
    $self->connect_db();
    
    # 1. Nodes holen
    my $nodes = $self->get_nodes();
    $self->{logger}->info("Gefunden: " . scalar(@$nodes) . " Nodes");
    
    # 2. Collection-Run starten
    my $sth = $self->{conn}->prepare(q{
        INSERT INTO collection_runs (started_at, nodes_total)
        VALUES (CURRENT_TIMESTAMP, ?)
    });
    $sth->execute(scalar(@$nodes));
    my $run_id = $self->{conn}->last_insert_id("", "", "collection_runs", "");
    
    # 3. Für jeden Node sammeln
    my $success_count = 0;
    my $failed_count = 0;
    my $total_logs = 0;
    
    foreach my $node (@$nodes) {
        if ($node->{node_id} eq 'node1') {
            # Lokale Logs (Gateway selbst)
            $self->{logger}->info("node1: Lokale Collection (Gateway)");
            $success_count++;
        } else {
            # Remote-Node abfragen
            my $result = $self->ssh_connect_and_collect($node);
            if (defined $result) {
                $success_count++;
                $total_logs += $result;
            } else {
                $failed_count++;
            }
        }
    }
    
    # 4. Run abschließen
    $sth = $self->{conn}->prepare(q{
        UPDATE collection_runs SET
            finished_at = CURRENT_TIMESTAMP,
            nodes_success = ?,
            nodes_failed = ?,
            logs_collected = ?
        WHERE run_id = ?
    });
    $sth->execute($success_count, $failed_count, $total_logs, $run_id);
    
    # 5. Retention-Cleanup
    $self->{logger}->info("Retention-Cleanup (30 Tage)...");
    $self->cleanup_retention();
    
    $self->{logger}->info("=" x 60);
    $self->{logger}->info("SUMMARY: $success_count OK, $failed_count Failed, $total_logs Logs");
    $self->{logger}->info("=" x 60);
}

package main;

sub main {
    print "=" x 60 . "\n";
    print "LOG COLLECTOR\n";
    print "=" x 60 . "\n";
    
    my $collector = LogCollector->new();
    
    eval {
        $collector->run_collection_cycle();
    };
    if ($@) {
        print "CRITICAL ERROR: $@\n";
        exit(1);
    }
}

main() if __FILE__ eq $0;
