#!/usr/bin/perl
# db_maintainer_run.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:scripts/db_maintainer_run.py
# Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use File::Path qw(make_path);
use File::Copy;
use Digest::MD5;
use JSON;
use POSIX qw(strftime);
use Time::Piece;
use Time::Seconds;
use Cwd qw(abs_path);
use File::Find;
use File::Spec;
use IPC::Run3;

=head1 Database Maintainer Sub-Agent

Automated database maintenance with 30min checks, hourly backups (3 days retention),
band tree command execution for important/openclaw-tree.txt

=cut

my $WORKSPACE = abs_path('/workspace');
my $DB_DIR = "$WORKSPACE/db";
my $BACKUP_DIR = "$DB_DIR/backups";
my $LOG_DIR = "$WORKSPACE/logs/db-maintainer";
my $IMPORTANT_DIR = "$WORKSPACE/important";

# Verzeichnisse erstellen
make_path($BACKUP_DIR, {verbose => 0}) unless -d $BACKUP_DIR;
make_path($LOG_DIR, {verbose => 0}) unless -d $LOG_DIR;


package Logger {
    sub new {
        my ($class) = @_;
        my $self = {};
        bless $self, $class;
        return $self;
    }
    
    sub _get_log_file {
        my ($self) = @_;
        my $today = strftime('%Y-%m-%d', localtime);
        return "$LOG_DIR/$today.log";
    }
    
    sub log {
        my ($self, $level, $message) = @_;
        my $timestamp = strftime('%Y-%m-%d %H:%M:%S', localtime);
        my $line = "[$timestamp] [$level] $message\n";
        print $line;
        open(my $fh, '>>', $self->_get_log_file()) or die "Could not open log file: $!";
        print $fh $line;
        close($fh);
    }
    
    sub info { my ($self, $msg) = @_; $self->log('INFO', $msg); }
    sub warn { my ($self, $msg) = @_; $self->log('WARN', $msg); }
    sub error { my ($self, $msg) = @_; $self->log('ERROR', $msg); }
}


package DatabaseMaintainer {
    sub new {
        my ($class) = @_;
        my $self = {
            logger => Logger->new(),
            state_file => "$DB_DIR/maintainer_state.json",
            retention_days => 3
        };
        bless $self, $class;
        return $self;
    }
    
    sub load_state {
        my ($self) = @_;
        if (-f $self->{state_file}) {
            open(my $fh, '<', $self->{state_file}) or die "Cannot open state file: $!";
            local $/;
            my $json_text = <$fh>;
            close($fh);
            return decode_json($json_text // '{}');
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
        open(my $fh, '>', $self->{state_file}) or die "Cannot write state file: $!";
        print $fh encode_json($state);
        close($fh);
    }
    
    sub get_file_hash {
        my ($self, $filepath) = @_;
        if (!-f $filepath) {
            return undef;
        }
        open(my $fh, '<', $filepath) or return undef;
        binmode($fh);
        my $md5 = Digest::MD5->new;
        $md5->addfile($fh);
        close($fh);
        return $md5->hexdigest;
    }
    
    sub run_tree_command {
        my ($self) = @_;
        eval {
            my ($stdout, $stderr);
            run3(['tree', '-a', '-L', '6', $WORKSPACE], \$stdout, \$stderr);
            if ($? == 0) {
                $self->{logger}->info("tree -a -L 6 erfolgreich ausgeführt");
                return $stdout;
            } else {
                $self->{logger}->error("tree command fehlgeschlagen: $stderr");
                return undef;
            }
        };
        if ($@) {
            $self->{logger}->error("tree command Exception: $@");
            return undef;
        }
        return undef;
    }
    
    sub update_tree_file {
        my ($self, $tree_output) = @_;
        return 0 unless defined $tree_output;
        
        my $tree_file = "$IMPORTANT_DIR/openclaw-tree.txt";
        my $timestamp = strftime('%Y-%m-%dT%H:%M:%S', localtime);
        my $header = "# OpenClaw Workspace Tree\n# Generiert: $timestamp\n# Befehl: tree -a -L 6 $WORKSPACE\n# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n";
        
        eval {
            open(my $fh, '>', $tree_file) or die "Cannot write to tree file: $!";
            print $fh $header;
            print $fh $tree_output;
            close($fh);
            $self->{logger}->info("openclaw-tree.txt aktualisiert: $tree_file");
            return 1;
        };
        if ($@) {
            $self->{logger}->error("Fehler beim Schreiben von openclaw-tree.txt: $@");
            return 0;
        }
        return 0;
    }
    
    sub scan_documentations {
        my ($self) = @_;
        my @docs;
        my @files;
        
        find(sub {
            return unless /\.md$/;
            return if -l $_;  # skip symlinks
            my $full_path = $File::Find::name;
            return if $full_path =~ m{/db/backups/};
            return if $full_path =~ m{/node_modules/};
            push @files, $full_path;
        }, $WORKSPACE);
        
        for my $file (@files) {
            my $rel_path = $file;
            $rel_path =~ s{^\Q$WORKSPACE\E/*}{};
            push @docs, {
                path => $rel_path,
                hash => $self->get_file_hash($file),
                mtime => (stat($file))[9]
            };
        }
        return \@docs;
    }
    
    sub check_for_changes {
        my ($self) = @_;
        my $state = $self->load_state();
        my $current_docs = $self->scan_documentations();
        
        my @changes;
        my %current_hashes;
        
        for my $doc (@$current_docs) {
            my $path = $doc->{path};
            $current_hashes{$path} = $doc->{hash};
            
            if (!exists $state->{file_hashes}{$path}) {
                push @changes, "NEW: $path";
            } elsif ($state->{file_hashes}{$path} ne $doc->{hash}) {
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
        my ($self) = @_;
        eval {
            my ($stdout, $stderr);
            run3(['python3', "$WORKSPACE/scripts/update_docs_db.py"], \$stdout, \$stderr);
            
            if ($? == 0) {
                $self->{logger}->info("docs.db aktualisiert");
                return 1;
            } else {
                $self->{logger}->error("DB-Update fehlgeschlagen: $stderr");
                return 0;
            }
        };
        if ($@) {
            $self->{logger}->error("DB-Update Exception: $@");
            return 0;
        }
        return 0;
    }
    
    sub update_tree_db_v2 {
        my ($self) = @_;
        eval {
            my ($stdout, $stderr);
            run3(['python3', "$WORKSPACE/scripts/tree_indexer_v2.py"], \$stdout, \$stderr);
            
            if ($? == 0) {
                $self->{logger}->info("tree.db v2 aktualisiert");
                return 1;
            } else {
                $self->{logger}->error("Tree-DB v2 fehlgeschlagen: $stderr");
                return 0;
            }
        };
        if ($@) {
            $self->{logger}->error("Tree-DB v2 Exception: $@");
            return 0;
        }
        return 0;
    }
    
    sub create_backup {
        my ($self) = @_;
        my $timestamp = strftime('%Y-%m-%d_%H-%M', localtime);
        
        for my $db_name ('docs.db', 'tree.db') {
            my $source = "$DB_DIR/$db_name";
            if (-f $source) {
                my $backup_name = "${timestamp}_${db_name}.bak";
                my $backup_path = "$BACKUP_DIR/$backup_name";
                copy($source, $backup_path) or warn "Failed to copy $source to $backup_path: $!";
                $self->{logger}->info("Backup erstellt: $backup_name") if -f $backup_path;
            }
        }
        return $timestamp;
    }
    
    sub cleanup_old_backups {
        my ($self) = @_;
        my $cutoff = localtime() - (ONE_DAY * $self->{retention_days});
        my $deleted = 0;
        
        for my $db_name ('docs.db', 'tree.db') {
            opendir(my $dh, $BACKUP_DIR) or die "Cannot open backup directory: $!";
            my @backups = grep { /\.bak$/ && /_$db_name\.bak$/ } readdir($dh);
            closedir($dh);
            
            for my $backup (@backups) {
                # Extrahiere Datum aus Filename (Format: YYYY-MM-DD_HH-MM)
                if ($backup =~ /^(\d{4}-\d{2}-\d{2})_(\d{2}-\d{2})_/) {
                    my ($date_part, $time_part) = ($1, $2);
                    my $backup_time_str = "${date_part}_${time_part}";
                    my $backup_time = Time::Piece->strptime($backup_time_str, '%Y-%m-%d_%H-%M');
                    
                    if ($backup_time < $cutoff) {
                        unlink("$BACKUP_DIR/$backup") or warn "Failed to delete $backup: $!";
                        $deleted++;
                        $self->{logger}->info("Altes Backup gelöscht: $backup");
                    }
                } else {
                    $self->{logger}->warn("Konnte Backup-Datum nicht parsen: $backup");
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
        my ($self) = @_;
        $self->{logger}->info("=" x 60);
        $self->{logger}->info("DB MAINTAINER CYCLE START");
        $self->{logger}->info("=" x 60);
        
        my $state = $self->load_state();
        
        # 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
        $self->{logger}->info("Führe tree -a -L 8 aus...");
        my $tree_output = $self->run_tree_command();
        if (defined $tree_output) {
            $self->update_tree_file($tree_output);
            $state->{last_tree_update} = localtime()->datetime;
        }
        
        # 2. tree.db aktualisieren (intern v2)
        $self->{logger}->info("Aktualisiere tree.db v2...");
        $self->update_tree_db_v2();
        
        # 3. Änderungen prüfen
        $self->{logger}->info("Prüfe auf Dokumentations-Änderungen...");
        my ($changes_ref, $current_hashes_ref) = $self->check_for_changes();
        my @changes = @$changes_ref;
        my %current_hashes = %$current_hashes_ref;
        
        if (@changes) {
            $self->{logger}->info(scalar(@changes) . " Änderungen gefunden:");
            for my $i (0 .. 9) {
                last if $i >= @changes;
                $self->{logger}->info("  - $changes[$i]");
            }
            if (@changes > 10) {
                $self->{logger}->info("  ... und " . (@changes - 10) . " weitere");
            }
            
            # 4. docs.db aktualisieren
            $self->{logger}->info("Aktualisiere docs.db...");
            if ($self->update_databases()) {
                $state->{last_check} = localtime()->datetime;
                $state->{file_hashes} = \%current_hashes;
            }
        } else {
            $self->{logger}->info("Keine Dokumentations-Änderungen gefunden");
        }
        
        # 5. Prüfe ob Backup fällig (stündlich)
        my $do_backup = 1;
        if (defined $state->{last_backup}) {
            my $last_backup_time = Time::Piece->strptime($state->{last_backup}, '%Y-%m-%d %H:%M:%S');
            $do_backup = (localtime() - $last_backup_time) >= ONE_HOUR;
        }
        
        if ($do_backup) {
            $self->{logger}->info("Erstelle stündliches Backup...");
            my $timestamp = $self->create_backup();
            $state->{last_backup} = localtime()->datetime;
            
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
}

sub main {
    my $maintainer = DatabaseMaintainer->new();
    
    eval {
        $maintainer->run_cycle();
    };
    if ($@) {
        $maintainer->{logger}->error("CRITICAL ERROR: $@");
        exit(1);
    }
}

main() unless caller;
