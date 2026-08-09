#!/usr/bin/perl
# db_maintainer.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/db_maintainer.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use DBI;
use Digest::MD5 qw(md5_hex);
use JSON;
use File::Path qw(make_path);
use File::Copy qw(copy);
use File::Basename qw(basename dirname);
use File::Find qw(find);
use POSIX qw(strftime);
use Time::Piece;
use Time::Seconds;
use Cwd qw(abs_path);
use File::Spec::Functions qw(catfile catdir);

# Konfiguration
my $WORKSPACE = "/home/openclaw/.openclaw/workspace";
my $DB_DIR = catdir($WORKSPACE, "db");
my $BACKUP_DIR = catdir($DB_DIR, "backups");
my $LOG_DIR = catdir($WORKSPACE, "logs", "db-maintainer");
my $IMPORTANT_DIR = catdir($WORKSPACE, "important");

# Verzeichnisse erstellen
make_path($BACKUP_DIR, { verbose => 0 });
make_path($LOG_DIR, { verbose => 0 });

# Logger-Klasse
package Logger;
sub new {
    my $class = shift;
    my $self = {};
    my $today = strftime('%Y-%m-%d', localtime);
    $self->{log_file} = catfile($LOG_DIR, "$today.log");
    bless $self, $class;
    return $self;
}

sub log {
    my ($self, $level, $message) = @_;
    my $timestamp = strftime('%Y-%m-%d %H:%M:%S', localtime);
    my $line = "[$timestamp] [$level] $message\n";
    print $line;
    open my $fh, '>>', $self->{log_file} or die "Kann Log-Datei nicht öffnen: $!";
    print $fh $line;
    close $fh;
}

sub info { my ($self, $msg) = @_; $self->log('INFO', $msg); }
sub warn { my ($self, $msg) = @_; $self->log('WARN', $msg); }
sub error { my ($self, $msg) = @_; $self->log('ERROR', $msg); }

# Hauptklasse
package DatabaseMaintainer;
sub new {
    my $class = shift;
    my $self = {
        logger => Logger->new(),
        state_file => catfile($DB_DIR, "maintainer_state.json"),
        retention_days => 3
    };
    bless $self, $class;
    return $self;
}

sub load_state {
    my $self = shift;
    if (-f $self->{state_file}) {
        open my $fh, '<', $self->{state_file} or die "Kann State-Datei nicht öffnen: $!";
        my $content = do { local $/; <$fh> };
        close $fh;
        return decode_json($content);
    }
    return {
        last_check => undef,
        last_backup => undef,
        last_tree_update => undef,
        file_hashes => {}
    };
}

sub save_state {
    my ($self, $state) = @_;
    open my $fh, '>', $self->{state_file} or die "Kann State-Datei nicht öffnen: $!";
    print $fh encode_json($state);
    close $fh;
}

sub get_file_hash {
    my ($self, $filepath) = @_;
    if (-f $filepath) {
        open my $fh, '<', $filepath or return undef;
        binmode $fh;
        my $digest = md5_hex(<$fh>);
        close $fh;
        return $digest;
    }
    return undef;
}

sub run_tree_command {
    my $self = shift;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 60;
        my $cmd = "tree -a -L 8 " . quotemeta($WORKSPACE);
        my $output = `$cmd 2>/dev/null`;
        my $exit_code = $? >> 8;
        alarm 0;
        if ($exit_code == 0) {
            $self->{logger}->info("tree -a -L 8 erfolgreich ausgeführt");
            return $output;
        } else {
            $self->{logger}->error("tree command fehlgeschlagen: $!");
            return undef;
        }
    };
    if ($@) {
        $self->{logger}->error("tree command Exception: $@");
        return undef;
    }
}

sub update_tree_file {
    my ($self, $tree_output) = @_;
    return 0 unless defined $tree_output;
    
    my $tree_file = catfile($IMPORTANT_DIR, "openclaw-tree.txt");
    my $timestamp = localtime->strftime('%Y-%m-%dT%H:%M:%S');
    
    my $header = "# OpenClaw Workspace Tree\n";
    $header .= "# Generiert: $timestamp\n";
    $header .= "# Befehl: tree -a -L 8 $WORKSPACE\n";
    $header .= "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n";
    
    eval {
        open my $fh, '>', $tree_file or die "Kann Tree-Datei nicht öffnen: $!";
        print $fh $header;
        print $fh $tree_output;
        close $fh;
        $self->{logger}->info("openclaw-tree.txt aktualisiert: $tree_file");
        return 1;
    };
    if ($@) {
        $self->{logger}->error("Fehler beim Schreiben von openclaw-tree.txt: $@");
        return 0;
    }
}

sub scan_documentations {
    my $self = shift;
    my @docs;
    
    find(sub {
        return unless /\.md$/;
        return if -l $_;  # Keine Symlinks
        my $full_path = $File::Find::name;
        return if $full_path =~ /db\/backups/;
        return if $full_path =~ /node_modules/;
        
        my $rel_path = $full_path;
        $rel_path =~ s/^\Q$WORKSPACE\E\/?//;
        push @docs, {
            path => $rel_path,
            hash => $self->get_file_hash($full_path),
            mtime => (stat($full_path))[9]
        };
    }, $WORKSPACE);
    
    return \@docs;
}

sub check_for_changes {
    my ($self, $state) = @_;
    my $current_docs = $self->scan_documentations();
    my @changes;
    my %current_hashes;
    
    for my $doc (@$current_docs) {
        my $path = $doc->{path};
        $current_hashes{$path} = $doc->{hash};
        
        if (!exists $state->{file_hashes}->{$path}) {
            push @changes, "NEW: $path";
        } elsif ($state->{file_hashes}->{$path} ne $doc->{hash}) {
            push @changes, "CHANGED: $path";
        }
    }
    
    # Prüfe auf gelöschte Dateien
    for my $old_path (keys %{$state->{file_hashes}}) {
        if (!exists $current_hashes{$old_path}) {
            push @changes, "DELETED: $old_path";
        }
    }
    
    return (\@changes, \%current_hashes);
}

sub update_databases {
    my $self = shift;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 60;
        my $script = catfile($WORKSPACE, 'scripts', 'update_docs_db.py');
        my $cmd = "python3 " . quotemeta($script);
        my $output = `$cmd 2>&1`;
        my $exit_code = $? >> 8;
        alarm 0;
        if ($exit_code == 0) {
            $self->{logger}->info("docs.db aktualisiert");
            return 1;
        } else {
            $self->{logger}->error("DB-Update fehlgeschlagen: $output");
            return 0;
        }
    };
    if ($@) {
        $self->{logger}->error("DB-Update Exception: $@");
        return 0;
    }
}

sub update_tree_db_v2 {
    my $self = shift;
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm 120;
        my $script = catfile($WORKSPACE, 'scripts', 'tree_indexer_v2.py');
        my $cmd = "python3 " . quotemeta($script);
        my $output = `$cmd 2>&1`;
        my $exit_code = $? >> 8;
        alarm 0;
        if ($exit_code == 0) {
            $self->{logger}->info("tree.db v2 aktualisiert");
            return 1;
        } else {
            $self->{logger}->error("Tree-DB v2 fehlgeschlagen: $output");
            return 0;
        }
    };
    if ($@) {
        $self->{logger}->error("Tree-DB v2 Exception: $@");
        return 0;
    }
}

sub create_backup {
    my $self = shift;
    my $timestamp = strftime('%Y-%m-%d_%H-%M', localtime);
    
    for my $db_name ('docs.db', 'tree.db') {
        my $source = catfile($DB_DIR, $db_name);
        if (-f $source) {
            my $backup_name = "${timestamp}_${db_name}.bak";
            my $backup_path = catfile($BACKUP_DIR, $backup_name);
            copy($source, $backup_path) or warn "Kann Backup nicht erstellen: $!";
            $self->{logger}->info("Backup erstellt: $backup_name");
        }
    }
    
    return $timestamp;
}

sub cleanup_old_backups {
    my $self = shift;
    my $cutoff = localtime(time - ($self->{retention_days} * 24 * 60 * 60));
    my $deleted = 0;
    
    for my $db_name ('docs.db', 'tree.db') {
        opendir my $dh, $BACKUP_DIR or next;
        my @backups = grep { /\.bak$/ && /_$db_name\.bak$/ } readdir($dh);
        closedir $dh;
        
        for my $backup (@backups) {
            # Extrahiere Datum aus Filename (Format: YYYY-MM-DD_HH-MM)
            if ($backup =~ /^(\d{4}-\d{2}-\d{2})_(\d{2}-\d{2})/) {
                my ($date_part, $time_part) = ($1, $2);
                my $backup_time_str = "${date_part}_${time_part}";
                eval {
                    my $backup_time = Time::Piece->strptime($backup_time_str, '%Y-%m-%d_%H-%M');
                    if ($backup_time < $cutoff) {
                        my $backup_path = catfile($BACKUP_DIR, $backup);
                        unlink $backup_path or warn "Kann Backup nicht löschen: $!";
                        $deleted++;
                        $self->{logger}->info("Altes Backup gelöscht: $backup");
                    }
                };
                if ($@) {
                    $self->{logger}->warn("Konnte Backup-Datum nicht parsen: $backup");
                }
            }
        }
    }
    
    if ($deleted == 0) {
        $self->{logger}->info("Keine alten Backups zum Löschen");
    } else {
        $self->{logger}->info("$deleted alte Backups gelöscht (< 3 Tage)");
    }
}

sub run_cycle {
    my $self = shift;
    $self->{logger}->info("=" x 60);
    $self->{logger}->info("DB MAINTAINER CYCLE START");
    $self->{logger}->info("=" x 60);
    
    my $state = $self->load_state();
    
    # 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
    $self->{logger}->info("Führe tree -a -L 8 aus...");
    my $tree_output = $self->run_tree_command();
    if ($tree_output) {
        $self->update_tree_file($tree_output);
        $state->{last_tree_update} = localtime->datetime();
    }
    
    # 2. tree.db aktualisieren (intern v2)
    $self->{logger}->info("Aktualisiere tree.db v2...");
    $self->update_tree_db_v2();
    
    # 3. Änderungen prüfen
    $self->{logger}->info("Prüfe auf Dokumentations-Änderungen...");
    my ($changes, $current_hashes) = $self->check_for_changes($state);
    
    if (@$changes) {
        $self->{logger}->info(scalar(@$changes) . " Änderungen gefunden:");
        my $count = 0;
        for my $change (@$changes) {
            last if $count >= 10;
            $self->{logger}->info("  - $change");
            $count++;
        }
        if (@$changes > 10) {
            $self->{logger}->info("  ... und " . (scalar(@$changes) - 10) . " weitere");
        }
        
        # 4. docs.db aktualisieren
        $self->{logger}->info("Aktualisiere docs.db...");
        if ($self->update_databases()) {
            $state->{last_check} = localtime->datetime();
            $state->{file_hashes} = $current_hashes;
        }
    } else {
        $self->{logger}->info("Keine Dokumentations-Änderungen gefunden");
    }
    
    # 5. Prüfe ob Backup fällig (stündlich)
    my $do_backup = 1;
    if ($state->{last_backup}) {
        my $last_backup_time = Time::Piece->strptime($state->{last_backup}, '%Y-%m-%dT%H:%M:%S');
        my $diff = localtime - $last_backup_time;
        $do_backup = ($diff >= 3600);  # 1 Stunde in Sekunden
    }
    
    if ($do_backup) {
        $self->{logger}->info("Erstelle stündliches Backup...");
        my $timestamp = $self->create_backup();
        $state->{last_backup} = localtime->datetime();
        
        # 6. Alte Backups aufräumen (3 Tage Retention)
        $self->{logger}->info("Räume alte Backups auf (3 Tage Retention)...");
        $self->cleanup_old_backups();
    } else {
        $self->{logger}->info("Backup nicht nötig (letztes < 1h)");
    }
    
    $self->save_state($state);
    
    $self->{logger}->info("=" x 60);
    $self->{logger}->info("DB MAINTAINER CYCLE END");
    $self->{logger}->info("=" x 60);
}

# Hauptfunktion
package main;
sub main {
    my $maintainer = DatabaseMaintainer->new();
    
    eval {
        $maintainer->run_cycle();
    };
    if ($@) {
        $maintainer->{logger}->error("CRITICAL ERROR: $@");
        exit 1;
    }
}

main() if __FILE__ eq $0;
