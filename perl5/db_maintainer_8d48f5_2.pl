#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "819921b0e00812618064d4fa0be7c8779e8012508428b8b542dfcd31051dfb28", "source_sha256": "8d48f51942bb1c171bbd41e0696beb0722cb4b94d6596233f54b32928b645086", "target_language": "perl5"}
# db_maintainer.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:scripts/db_maintainer.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use File::Spec;
use File::Path qw(make_path);
use File::Copy;
use Digest::MD5 qw(md5_hex);
use JSON qw(decode_json encode_json);
use Cwd qw(abs_path);
use File::Basename;
use POSIX qw(strftime);

binmode STDOUT, ':encoding(UTF-8)';
binmode STDERR, ':encoding(UTF-8)';

my $script_dir = dirname(abs_path($0));
my $workspace_env = $ENV{'OPENCLAW_WORKSPACE'};
my $WORKSPACE = defined $workspace_env ? $workspace_env : dirname($script_dir);
my $DB_DIR = $WORKSPACE;
my $BACKUP_DIR = File::Spec->catdir($WORKSPACE, 'db', 'backups');
my $LOG_DIR = File::Spec->catdir($WORKSPACE, 'logs', 'db-maintainer');
my $IMPORTANT_DIR = File::Spec->catdir($WORKSPACE, 'important');

make_path($BACKUP_DIR) unless -d $BACKUP_DIR;
make_path($LOG_DIR) unless -d $LOG_DIR;
make_path($IMPORTANT_DIR) unless -d $IMPORTANT_DIR;

package Logger {
    sub new {
        my ($class) = @_;
        my $self = {};
        my $today = strftime('%Y-%m-%d', localtime);
        $self->{log_file} = File::Spec->catfile($LOG_DIR, "$today.log");
        bless $self, $class;
        return $self;
    }

    sub log {
        my ($self, $level, $message) = @_;
        my $timestamp = strftime('%Y-%m-%d %H:%M:%S', localtime);
        my $line = "[$timestamp] [$level] $message\n";
        print $line;
        open(my $fh, '>>:encoding(UTF-8)', $self->{log_file}) or die "Cannot open log file: $!";
        print $fh $line;
        close($fh);
    }

    sub info { shift->log('INFO', @_); }
    sub warn { shift->log('WARN', @_); }
    sub error { shift->log('ERROR', @_); }
}

package DatabaseMaintainer {
    sub new {
        my ($class) = @_;
        my $self = {};
        $self->{logger} = Logger->new();
        $self->{state_file} = File::Spec->catfile($DB_DIR, 'maintainer_state.json');
        $self->{retention_days} = 3;
        bless $self, $class;
        return $self;
    }

    sub load_state {
        my ($self) = @_;
        if (-f $self->{state_file}) {
            open(my $fh, '<:encoding(UTF-8)', $self->{state_file}) or die "Cannot read state file: $!";
            my $json_text = do { local $/; <$fh> };
            close($fh);
            return decode_json($json_text);
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
        open(my $fh, '>:encoding(UTF-8)', $self->{state_file}) or die "Cannot write state file: $!";
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
        my $digest = md5_hex(<$fh>);
        close($fh);
        return $digest;
    }

    sub _python_tree_fallback {
        my ($self, $max_depth) = @_;
        $max_depth //= 8;
        my @lines = ($WORKSPACE);

        sub walk {
            my ($dirpath, $prefix, $depth, $lines_ref) = @_;
            return if $depth > $max_depth;
            opendir(my $dh, $dirpath) or return;
            my @entries = sort { (-d "$dirpath/$b") <=> (-d "$dirpath/$a") || $a cmp $b } readdir($dh);
            closedir($dh);
            for my $i (0 .. $#entries) {
                next if $entries[$i] eq '.' || $entries[$i] eq '..';
                my $entry = File::Spec->catfile($dirpath, $entries[$i]);
                my $connector = ($i == $#entries) ? '└── ' : '├── ';
                push @$lines_ref, $prefix . $connector . $entries[$i];
                if (-d $entry && !-l $entry) {
                    my $extension = ($i == $#entries) ? '    ' : '│   ';
                    walk($entry, $prefix . $extension, $depth + 1, $lines_ref);
                }
            }
        }

        walk($WORKSPACE, '', 1, \@lines);
        return join("\n", @lines) . "\n";
    }

    sub run_tree_command {
        my ($self) = @_;
        eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm(60);
            open(my $pipe, '-|:encoding(UTF-8)', 'tree', '-a', '-L', '8', $WORKSPACE) or die "Cannot run tree\n";
            my $output = do { local $/; <$pipe> };
            close($pipe);
            alarm(0);
            $self->{logger}->info("tree -a -L 8 erfolgreich ausgeführt");
            return $output;
        };
        if ($@) {
            if ($@ eq "timeout\n") {
                $self->{logger}->warn("tree command timed out – nutze Python-Fallback");
            } elsif ($@ =~ /Cannot run tree/) {
                $self->{logger}->warn("tree-Binary nicht installiert – nutze Python-Fallback");
            } else {
                chomp($@);
                $self->{logger}->error("tree command Exception: $@");
            }
            return $self->_python_tree_fallback();
        }
        return undef;
    }

    sub update_tree_file {
        my ($self, $tree_output) = @_;
        return 0 unless defined $tree_output;
        my $tree_file = File::Spec->catfile($IMPORTANT_DIR, 'openclaw-tree.txt');
        my $header = "# OpenClaw Workspace Tree\n";
        $header .= "# Generiert: " . strftime('%Y-%m-%dT%H:%M:%S', localtime) . "\n";
        $header .= "# Befehl: tree -a -L 8 $WORKSPACE\n";
        $header .= "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n";

        eval {
            open(my $fh, '>:encoding(UTF-8)', $tree_file) or die "Cannot write to tree file: $!";
            print $fh $header;
            print $fh $tree_output;
            close($fh);
            $self->{logger}->info("openclaw-tree.txt aktualisiert: $tree_file");
            return 1;
        };
        if ($@) {
            chomp($@);
            $self->{logger}->error("Fehler beim Schreiben von openclaw-tree.txt: $@");
            return 0;
        }
    }

    sub scan_documentations {
        my ($self) = @_;
        my @docs;
        my @patterns = ('*.md', '*/*/*.md'); # Simplified glob patterns
        require File::Find;
        my @files;
        File::Find::find(sub {
            return unless /\.md$/ && -f $_ && !-l $_;
            my $rel_path = File::Spec->abs2rel($File::Find::name, $WORKSPACE);
            return if $rel_path =~ m{(?:^|[\/\\])(?:db[\/\\]backups|node_modules)(?:[\/\\]|$)};
            push @files, $File::Find::name;
        }, $WORKSPACE);

        for my $file (@files) {
            my $rel_path = File::Spec->abs2rel($file, $WORKSPACE);
            my @stat = stat($file);
            push @docs, {
                path => $rel_path,
                hash => $self->get_file_hash($file),
                mtime => $stat[9]
            };
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
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm(60);
            system('python3', File::Spec->catfile($WORKSPACE, 'scripts', 'update_docs_db.py'));
            my $exit_code = $? >> 8;
            alarm(0);
            if ($exit_code == 0) {
                $self->{logger}->info("docs.db aktualisiert");
                return 1;
            } else {
                $self->{logger}->error("DB-Update fehlgeschlagen: exit code $exit_code");
                return 0;
            }
        };
        if ($@ && $@ eq "timeout\n") {
            $self->{logger}->error("DB-Update timed out");
        } elsif ($@) {
            chomp($@);
            $self->{logger}->error("DB-Update Exception: $@");
        }
        return 0;
    }

    sub update_tree_db_v2 {
        my ($self) = @_;
        eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm(120);
            system('python3', File::Spec->catfile($WORKSPACE, 'scripts', 'tree_indexer_v2.py'));
            my $exit_code = $? >> 8;
            alarm(0);
            if ($exit_code == 0) {
                $self->{logger}->info("tree.db v2 aktualisiert");
                return 1;
            } else {
                $self->{logger}->error("Tree-DB v2 fehlgeschlagen: exit code $exit_code");
                return 0;
            }
        };
        if ($@ && $@ eq "timeout\n") {
            $self->{logger}->error("Tree-DB v2 timed out");
        } elsif ($@) {
            chomp($@);
            $self->{logger}->error("Tree-DB v2 Exception: $@");
        }
        return 0;
    }

    sub create_backup {
        my ($self) = @_;
        my $timestamp = strftime('%Y-%m-%d_%H-%M', localtime);
        for my $db_name (qw(docs.db tree.db)) {
            my $source = File::Spec->catfile($DB_DIR, $db_name);
            if (-f $source) {
                my $backup_name = "${timestamp}_${db_name}.bak";
                my $backup_path = File::Spec->catfile($BACKUP_DIR, $backup_name);
                copy($source, $backup_path) or warn "Failed to copy $source to $backup_path: $!";
                $self->{logger}->info("Backup erstellt: $backup_name");
            }
        }
        return $timestamp;
    }

    sub cleanup_old_backups {
        my ($self) = @_;
        my $cutoff_time = time() - ($self->{retention_days} * 24 * 60 * 60);
        my $deleted = 0;
        for my $db_name (qw(docs.db tree.db)) {
            opendir(my $dh, $BACKUP_DIR) or next;
            my @backups = grep { /^.*_\Q$db_name\E\.bak$/ } readdir($dh);
            closedir($dh);
            for my $backup (@backups) {
                my $full_path = File::Spec->catfile($BACKUP_DIR, $backup);
                if ($backup =~ /^(\d{4}-\d{2}-\d{2})_(\d{2}-\d{2})_/) {
                    my ($date_part, $time_part) = ($1, $2);
                    my $backup_time_str = "${date_part}_${time_part}";
                    my $backup_timestamp = eval { 
                        require Time::Piece;
                        Time::Piece->strptime($backup_time_str, '%Y-%m-%d_%H-%M')->epoch;
                    };
                    if (!$@ && defined $backup_timestamp && $backup_timestamp < $cutoff_time) {
                        unlink($full_path) or warn "Could not delete $full_path: $!";
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

        $self->{logger}->info("Führe tree -a -L 8 aus...");
        my $tree_output = $self->run_tree_command();
        if (defined $tree_output) {
            $self->update_tree_file($tree_output);
            $state->{last_tree_update} = strftime('%Y-%m-%dT%H:%M:%S', localtime);
        }

        $self->{logger}->info("Aktualisiere tree.db v2...");
        $self->update_tree_db_v2();

        $self->{logger}->info("Prüfe auf Dokumentations-Änderungen...");
        my ($changes_ref, $current_hashes_ref) = $self->check_for_changes();
        my @changes = @$changes_ref;

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

            $self->{logger}->info("Aktualisiere docs.db...");
            if ($self->update_databases()) {
                $state->{last_check} = strftime('%Y-%m-%dT%H:%M:%S', localtime);
                $state->{file_hashes} = $current_hashes_ref;
            }
        } else {
            $self->{logger}->info("Keine Dokumentations-Änderungen gefunden");
        }

        my $do_backup = 1;
        if (defined $state->{last_backup}) {
            my $last_backup_time = $state->{last_backup};
            require Time::Piece;
            my $last_time_obj = eval { Time::Piece->strptime($last_backup_time, '%Y-%m-%dT%H:%M:%S') };
            if (!$@) {
                my $diff_seconds = time() - $last_time_obj->epoch;
                $do_backup = ($diff_seconds >= 3600); # 1 hour in seconds
            }
        }

        if ($do_backup) {
            $self->{logger}->info("Erstelle stündliches Backup...");
            my $timestamp = $self->create_backup();
            $state->{last_backup} = strftime('%Y-%m-%dT%H:%M:%S', localtime);

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
        chomp($@);
        $maintainer->{logger}->error("CRITICAL ERROR: $@");
        exit(1);
    }
}

main() if !caller();
