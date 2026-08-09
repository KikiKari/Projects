#!/usr/bin/perl
# db_maintainer.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:skills/db-maintainer/scripts/db_maintainer.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use DBI;
use Digest::MD5 qw(md5_hex);
use JSON;
use File::Path qw(make_path);
use File::Copy qw(copy);
use File::Find;
use File::Spec;
use File::Basename;
use Cwd qw(abs_path);
use POSIX qw(strftime);

# Konfiguration
my $WORKSPACE = "/home/openclaw/.openclaw/workspace";
my $DB_DIR = "$WORKSPACE/db";
my $BACKUP_DIR = "$DB_DIR/backups";
my $LOG_DIR = "$WORKSPACE/logs/db-maintainer";
my $IMPORTANT_DIR = "$WORKSPACE/important";

# Verzeichnisse erstellen
make_path($BACKUP_DIR) unless -d $BACKUP_DIR;
make_path($LOG_DIR) unless -d $LOG_DIR;

# Logger-Klasse
package Logger {
    sub new {
        my $class = shift;
        my $self = {
            log_file => undef
        };
        bless $self, $class;
        $self->_init();
        return $self;
    }
    
    sub _init {
        my $self = shift;
        my $today = strftime('%Y-%m-%d', localtime);
        $self->{log_file} = "$LOG_DIR/$today.log";
    }
    
    sub log {
        my ($self, $level, $message) = @_;
        my $timestamp = strftime('%Y-%m-%d %H:%M:%S', localtime);
        my $line = "[$timestamp] [$level] $message\n";
        print $line;
        open(my $fh, '>>', $self->{log_file}) or die "Kann Log-Datei nicht öffnen: $!";
        print $fh $line;
        close($fh);
    }
    
    sub info { my $self = shift; $self->log('INFO', @_); }
    sub warn { my $self = shift; $self->log('WARN', @_); }
    sub error { my $self = shift; $self->log('ERROR', @_); }
}

# Hauptklasse
package DatabaseMaintainer {
    sub new {
        my $class = shift;
        my $self = {
            logger => Logger->new(),
            state_file => "$DB_DIR/maintainer_state.json",
            retention_days => 3
        };
        bless $self, $class;
        return $self;
    }
    
    sub load_state {
        my $self = shift;
        if (-f $self->{state_file}) {
            open(my $fh, '<', $self->{state_file}) or return $self->_default_state();
            my $content = do { local $/; <$fh> };
            close($fh);
            my $data = eval { decode_json($content) };
            return $data if $data;
        }
        return $self->_default_state();
    }
    
    sub _default_state {
        return {
            last_check => undef,
            last_backup => undef,
            last_tree_update => undef,
            file_hashes => {}
        };
    }
    
    sub save_state {
        my ($self, $state) = @_;
        open(my $fh, '>', $self->{state_file}) or die "Kann State-Datei nicht öffnen: $!";
        print $fh encode_json($state);
        close($fh);
    }
    
    sub get_file_hash {
        my ($self, $filepath) = @_;
        return unless -f $filepath;
        open(my $fh, '<', $filepath) or return;
        binmode($fh);
        my $digest = Digest::MD5->new;
        while (read($fh, my $buffer, 4096)) {
            $digest->add($buffer);
        }
        close($fh);
        return $digest->hexdigest;
    }
    
    sub run_tree_command {
        my $self = shift;
        eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm(60);
            my $cmd = "tree -a -L 6 '$WORKSPACE'";
            my $output = `$cmd 2>&1`;
            my $exit_code = $? >> 8;
            alarm(0);
            if ($exit_code == 0) {
                $self->{logger}->info("tree -a -L 6 erfolgreich ausgeführt");
                return $output;
            } else {
                $self->{logger}->error("tree command fehlgeschlagen: $output");
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
        
        my $tree_file = "$IMPORTANT_DIR/openclaw-tree.txt";
        my $timestamp = strftime('%Y-%m-%dT%H:%M:%S', localtime);
        my $header = "# OpenClaw Workspace Tree
# Generiert: $timestamp
# Befehl: tree -a -L 6 $WORKSPACE
# Diese Datei wird automatisch von db-maintainer aktualisiert

";
        
        eval {
            open(my $fh, '>', $tree_file) or die "Kann $tree_file nicht öffnen: $!";
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
    }
    
    sub scan_documentations {
        my $self = shift;
        my @docs;
        my %seen;
        
        sub wanted {
            my $file = $File::Find::name;
            return unless -f $file;
            return if -l $file;
            return unless $file =~ /\.md$/;
            return if $file =~ /db\/backups/;
            return if $file =~ /node_modules/;
            
            my $rel_path = File::Spec->abs2rel($file, $WORKSPACE);
            return if $seen{$rel_path}++;
            
            my $mtime = (stat($file))[9];
            my $hash = $self->get_file_hash($file);
            
            push @docs, {
                path => $rel_path,
                hash => $hash,
                mtime => $mtime
            };
        }
        
        find(\&wanted, $WORKSPACE);
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
            alarm(60);
            my $script = "$WORKSPACE/scripts/update_docs_db.py";
            my $cmd = "python3 '$script'";
            my $output = `$cmd 2>&1`;
            my $exit_code = $? >> 8;
            alarm(0);
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
            alarm(120);
            my $script = "$WORKSPACE/scripts/tree_indexer_v2.py";
            my $cmd = "python3 '$script'";
            my $output = `$cmd 2>&1`;
            my $exit_code = $? >> 8;
            alarm(0);
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
        
        for my $db_name (qw(docs.db tree.db)) {
            my $source = "$DB_DIR/$db_name";
            if (-f $source) {
                my $backup_name = "${timestamp}_${db_name}.bak";
                my $backup_path = "$BACKUP_DIR/$backup_name";
                copy($source, $backup_path) or do {
                    $self->{logger}->error("Konnte Backup nicht erstellen: $!");
                    next;
                };
                $self->{logger}->info("Backup erstellt: $backup_name");
            }
        }
        
        return $timestamp;
    }
    
    sub cleanup_old_backups {
        my $self = shift;
        my $cutoff = time() - ($self->{retention_days} * 24 * 60 * 60);
        my $deleted = 0;
        
        for my $db_name (qw(docs.db tree.db)) {
            opendir(my $dh, $BACKUP_DIR) or next;
            my @backups = grep { /\.bak$/ && -f "$BACKUP_DIR/$_" && $_ =~ /_${db_name}\.bak$/ } readdir($dh);
            closedir($dh);
            
            for my $backup (@backups) {
                # Extrahiere Datum aus Filename (Format: YYYY-MM-DD_HH-MM)
                if ($backup =~ /^(\d{4}-\d{2}-\d{2})_(\d{2}-\d{2})_/) {
                    my $date_str = $1;
                    my $time_str = $2;
                    my $backup_time_str = "${date_str}_${time_str}";
                    my $backup_time = eval { 
                        my ($year, $month, $day, $hour, $minute) = 
                            $backup_time_str =~ /(\d{4})-(\d{2})-(\d{2})_(\d{2})-(\d{2})/;
                        return undef unless defined $year;
                        return timelocal(0, $minute, $hour, $day, $month-1, $year);
                    };
                    
                    if ($backup_time && $backup_time < $cutoff) {
                        my $backup_path = "$BACKUP_DIR/$backup";
                        if (unlink($backup_path)) {
                            $deleted++;
                            $self->{logger}->info("Altes Backup gelöscht: $backup");
                        } else {
                            $self->{logger}->warn("Konnte Backup nicht löschen: $backup");
                        }
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
            $state->{last_tree_update} = strftime('%Y-%m-%dT%H:%M:%S', localtime);
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
                $self->{logger}->info("  ... und " . (@$changes - 10) . " weitere");
            }
            
            # 4. docs.db aktualisieren
            $self->{logger}->info("Aktualisiere docs.db...");
            if ($self->update_databases()) {
                $state->{last_check} = strftime('%Y-%m-%dT%H:%M:%S', localtime);
                $state->{file_hashes} = $current_hashes;
            }
        } else {
            $self->{logger}->info("Keine Dokumentations-Änderungen gefunden");
        }
        
        # 5. Prüfe ob Backup fällig (stündlich)
        my $do_backup = 1;
        if ($state->{last_backup}) {
            my ($year, $month, $day, $hour, $minute, $second) = 
                $state->{last_backup} =~ /(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})/;
            if (defined $year) {
                my $last_backup_time = timelocal($second, $minute, $hour, $day, $month-1, $year);
                my $diff = time() - $last_backup_time;
                $do_backup = ($diff >= 3600); # 1 Stunde
            }
        }
        
        if ($do_backup) {
            $self->{logger}->info("Erstelle stündliches Backup...");
            my $timestamp = $self->create_backup();
            $state->{last_backup} = strftime('%Y-%m-%dT%H:%M:%S', localtime);
            
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

# Hauptfunktion
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

main() if __FILE__ eq $0;
