#!/usr/bin/env perl
# db_maintainer.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:scripts/db_maintainer.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use File::Path qw(make_path);
use File::Copy;
use File::Find;
use File::Spec;
use Digest::MD5;
use JSON;
use Time::Piece;
use Time::Seconds;
use Cwd qw(abs_path);
use File::Basename;

# Dokumentation
# Database Maintainer Sub-Agent
# Automated database maintenance with 30min checks, hourly backups (3 days retention),
# band tree command execution for important/openclaw-tree.txt

# Konstanten und Pfade
my $script_dir = dirname(abs_path(__FILE__));
my $WORKSPACE = $ENV{'OPENCLAW_WORKSPACE'} // dirname($script_dir);
my $DB_DIR = $WORKSPACE;
my $BACKUP_DIR = File::Spec->catdir($WORKSPACE, 'db', 'backups');
my $LOG_DIR = File::Spec->catdir($WORKSPACE, 'logs', 'db-maintainer');
my $IMPORTANT_DIR = File::Spec->catdir($WORKSPACE, 'important');

# Verzeichnisse erstellen
make_path($BACKUP_DIR, { verbose => 0 });
make_path($LOG_DIR, { verbose => 0 });
make_path($IMPORTANT_DIR, { verbose => 0 });

# Logger-Klasse
package Logger {
    sub new {
        my $class = shift;
        my $self = {
            log_file => File::Spec->catfile($LOG_DIR, localtime->strftime('%Y-%m-%d') . '.log')
        };
        bless $self, $class;
        return $self;
    }

    sub log {
        my ($self, $level, $message) = @_;
        my $timestamp = localtime->strftime('%Y-%m-%d %H:%M:%S');
        my $line = "[$timestamp] [$level] $message\n";
        print $line;
        open my $fh, '>>', $self->{log_file} or die "Kann Log-Datei nicht öffnen: $!";
        print $fh $line;
        close $fh;
    }

    sub info { shift->log('INFO', shift); }
    sub warn { shift->log('WARN', shift); }
    sub error { shift->log('ERROR', shift); }
}

# Hauptklasse DatabaseMaintainer
package DatabaseMaintainer {
    sub new {
        my $class = shift;
        my $self = {
            logger => Logger->new(),
            state_file => File::Spec->catfile($DB_DIR, 'maintainer_state.json'),
            retention_days => 3
        };
        bless $self, $class;
        return $self;
    }

    sub load_state {
        my $self = shift;
        if (-f $self->{state_file}) {
            open my $fh, '<', $self->{state_file} or die "Kann State-Datei nicht öffnen: $!";
            my $json_text = do { local $/; <$fh> };
            close $fh;
            my $data = eval { decode_json($json_text) };
            return $data if $data;
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
        open my $fh, '>', $self->{state_file} or die "Kann State-Datei nicht schreiben: $!";
        print $fh to_json($state, { pretty => 1 });
        close $fh;
    }

    sub get_file_hash {
        my ($self, $filepath) = @_;
        return unless -f $filepath;
        open my $fh, '<', $filepath or return;
        binmode $fh;
        my $md5 = Digest::MD5->new;
        $md5->addfile($fh);
        close $fh;
        return $md5->hexdigest;
    }

    sub _python_tree_fallback {
        my ($self, $max_depth) = @_;
        $max_depth //= 8;
        my @lines = ($WORKSPACE);
        
        sub walk {
            my ($dirpath, $prefix, $depth) = @_;
            return if $depth > $max_depth;
            my @entries;
            if (opendir(my $dh, $dirpath)) {
                @entries = readdir($dh);
                closedir($dh);
                @entries = grep { $_ ne '.' && $_ ne '..' } @entries;
                @entries = sort { (-d "$dirpath/$a" ? 0 : 1) <=> (-d "$dirpath/$b" ? 0 : 1) || $a cmp $b } @entries;
            } else {
                return;
            }
            
            for my $i (0..$#entries) {
                my $entry = $entries[$i];
                my $full_path = File::Spec->catfile($dirpath, $entry);
                my $connector = ($i == $#entries) ? '└── ' : '├── ';
                push @lines, $prefix . $connector . $entry;
                if (-d $full_path && !-l $full_path) {
                    my $extension = ($i == $#entries) ? '    ' : '│   ';
                    walk($full_path, $prefix . $extension, $depth + 1);
                }
            }
        }
        
        walk($WORKSPACE, '', 1);
        return join("\n", @lines) . "\n";
    }

    sub run_tree_command {
        my $self = shift;
        my $cmd = "tree -a -L 8 " . quotemeta($WORKSPACE);
        my $output = `$cmd 2>/dev/null`;
        my $exit_code = $? >> 8;
        
        if ($exit_code == 0) {
            $self->{logger}->info("tree -a -L 8 erfolgreich ausgeführt");
            return $output;
        } else {
            $self->{logger}->warn("tree command fehlgeschlagen – nutze Python-Fallback");
            return $self->_python_tree_fallback();
        }
    }

    sub update_tree_file {
        my ($self, $tree_output) = @_;
        return 0 unless defined $tree_output;
        
        my $tree_file = File::Spec->catfile($IMPORTANT_DIR, 'openclaw-tree.txt');
        my $timestamp = localtime->strftime('%Y-%m-%dT%H:%M:%S');
        my $header = "# OpenClaw Workspace Tree\n# Generiert: $timestamp\n# Befehl: tree -a -L 8 $WORKSPACE\n# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n";
        
        open my $fh, '>', $tree_file or do {
            $self->{logger}->error("Fehler beim Schreiben von openclaw-tree.txt: $!");
            return 0;
        };
        print $fh $header . $tree_output;
        close $fh;
        $self->{logger}->info("openclaw-tree.txt aktualisiert: $tree_file");
        return 1;
    }

    sub scan_documentations {
        my $self = shift;
        my @docs;
        my @patterns = ('*.md', '**/*.md');
        
        for my $pattern (@patterns) {
            my @files = glob(File::Spec->catfile($WORKSPACE, $pattern));
            for my $file (@files) {
                next unless -f $file && !-l $file;
                next if $file =~ /db\/backups/ || $file =~ /node_modules/;
                my $rel_path = File::Spec->abs2rel($file, $WORKSPACE);
                push @docs, {
                    path => $rel_path,
                    hash => $self->get_file_hash($file),
                    mtime => (stat($file))[9]
                };
            }
        }
        return @docs;
    }

    sub check_for_changes {
        my ($self) = @_;
        my $state = $self->load_state();
        my @current_docs = $self->scan_documentations();
        my @changes;
        my %current_hashes;
        
        for my $doc (@current_docs) {
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
        my $script = File::Spec->catfile($WORKSPACE, 'scripts', 'update_docs_db.py');
        my $cmd = "python3 " . quotemeta($script);
        my $output = `$cmd 2>&1`;
        my $exit_code = $? >> 8;
        
        if ($exit_code == 0) {
            $self->{logger}->info("docs.db aktualisiert");
            return 1;
        } else {
            $self->{logger}->error("DB-Update fehlgeschlagen: $output");
            return 0;
        }
    }

    sub update_tree_db_v2 {
        my $self = shift;
        my $script = File::Spec->catfile($WORKSPACE, 'scripts', 'tree_indexer_v2.py');
        my $cmd = "python3 " . quotemeta($script);
        my $output = `$cmd 2>&1`;
        my $exit_code = $? >> 8;
        
        if ($exit_code == 0) {
            $self->{logger}->info("tree.db v2 aktualisiert");
            return 1;
        } else {
            $self->{logger}->error("Tree-DB v2 fehlgeschlagen: $output");
            return 0;
        }
    }

    sub create_backup {
        my $self = shift;
        my $timestamp = localtime->strftime('%Y-%m-%d_%H-%M');
        
        for my $db_name ('docs.db', 'tree.db') {
            my $source = File::Spec->catfile($DB_DIR, $db_name);
            if (-f $source) {
                my $backup_name = "${timestamp}_${db_name}.bak";
                my $backup_path = File::Spec->catfile($BACKUP_DIR, $backup_name);
                copy($source, $backup_path) or do {
                    $self->{logger}->error("Backup fehlgeschlagen: $source -> $backup_path: $!");
                    next;
                };
                $self->{logger}->info("Backup erstellt: $backup_name");
            }
        }
        return $timestamp;
    }

    sub cleanup_old_backups {
        my $self = shift;
        my $cutoff = localtime() - (3 * 24 * 3600); # 3 Tage
        my $deleted = 0;
        
        for my $db_name ('docs.db', 'tree.db') {
            opendir(my $dh, $BACKUP_DIR) or next;
            my @backups = grep { /_${db_name}\.bak$/ } readdir($dh);
            closedir($dh);
            
            for my $backup (@backups) {
                # Extrahiere Datum aus Filename (Format: YYYY-MM-DD_HH-MM)
                if ($backup =~ /^(\d{4}-\d{2}-\d{2})_(\d{2}-\d{2})_/) {
                    my ($date_part, $time_part) = ($1, $2);
                    my $backup_time_str = "${date_part}_${time_part}";
                    my $backup_time = Time::Piece->strptime($backup_time_str, '%Y-%m-%d_%H-%M');
                    
                    if ($backup_time < $cutoff) {
                        my $full_path = File::Spec->catfile($BACKUP_DIR, $backup);
                        unlink $full_path or do {
                            $self->{logger}->warn("Konnte Backup nicht löschen: $backup: $!");
                            next;
                        };
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
        my ($changes_ref, $current_hashes_ref) = $self->check_for_changes();
        my @changes = @$changes_ref;
        my %current_hashes = %$current_hashes_ref;
        
        if (@changes) {
            $self->{logger}->info(scalar(@changes) . " Änderungen gefunden:");
            my $count = 0;
            for my $change (@changes) {
                last if $count++ >= 10;
                $self->{logger}->info("  - $change");
            }
            if (@changes > 10) {
                $self->{logger}->info("  ... und " . (@changes - 10) . " weitere");
            }
            
            # 4. docs.db aktualisieren
            $self->{logger}->info("Aktualisiere docs.db...");
            if ($self->update_databases()) {
                $state->{last_check} = localtime->datetime();
                $state->{file_hashes} = \%current_hashes;
            }
        } else {
            $self->{logger}->info("Keine Dokumentations-Änderungen gefunden");
        }
        
        # 5. Prüfe ob Backup fällig (stündlich)
        my $last_backup = $state->{last_backup};
        my $do_backup = 0;
        
        if ($last_backup) {
            my $last_backup_time = Time::Piece->strptime($last_backup, '%Y-%m-%dT%H:%M:%S');
            $do_backup = (localtime() - $last_backup_time) >= 3600; # 1 Stunde
        } else {
            $do_backup = 1;
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
}

# Hauptfunktion
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
