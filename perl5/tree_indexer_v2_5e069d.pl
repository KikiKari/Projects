#!/usr/bin/perl
# tree_indexer_v2.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:scripts/tree_indexer_v2.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use DBI;
use File::Find;
use File::Spec;
use Digest::MD5 qw(md5_hex);
use POSIX qw(strftime);
use JSON;
use Time::HiRes qw(time);

# Konfiguration
my $WORKSPACE = $ENV{'OPENCLAW_WORKSPACE'} || do {
    my $script_dir = (split '/', $0)[-2];
    $script_dir =~ s|/[^/]+$||;
    $script_dir;
};
my $DB_DIR = $WORKSPACE;

# TreeIndexerV2 Klasse
package TreeIndexerV2;

sub new {
    my $class = shift;
    my $self = {
        db_path => "$DB_DIR/tree.db",
        conn     => undef,
    };
    bless $self, $class;
    return $self;
}

sub connect {
    my $self = shift;
    $self->{conn} = DBI->connect("dbi:SQLite:dbname=$self->{db_path}", "", "", { RaiseError => 1, AutoCommit => 0 });
    return $self->{conn};
}

sub init_schema_v2 {
    my $self = shift;
    my $conn = $self->connect();
    my $cursor = $conn->prepare(q{
        CREATE TABLE IF NOT EXISTS tree_entries_v2 (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_id TEXT UNIQUE,
            root_path TEXT NOT NULL,
            relative_path TEXT NOT NULL,
            name TEXT NOT NULL,
            type TEXT CHECK(type IN ('file', 'directory', 'symlink')),
            depth INTEGER,
            parent_path TEXT,
            size_bytes INTEGER,
            previous_size_bytes INTEGER,
            size_change_bytes INTEGER,
            mtime_timestamp REAL,
            mtime_iso TEXT,
            first_seen_timestamp REAL,
            last_seen_timestamp REAL,
            change_type TEXT CHECK(change_type IN ('NEW', 'MODIFIED', 'MOVED', 'RENAMED', 'UNCHANGED', 'DELETED')),
            original_name TEXT,
            original_path TEXT,
            previous_path TEXT,
            content_hash TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    });
    $cursor->execute();

    $cursor = $conn->prepare(q{
        CREATE TABLE IF NOT EXISTS file_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_id TEXT NOT NULL,
            timestamp REAL NOT NULL,
            change_type TEXT NOT NULL,
            old_path TEXT,
            new_path TEXT,
            old_size INTEGER,
            new_size INTEGER,
            FOREIGN KEY (file_id) REFERENCES tree_entries_v2(file_id)
        )
    });
    $cursor->execute();

    $cursor = $conn->prepare("CREATE INDEX IF NOT EXISTS idx_file_id ON tree_entries_v2(file_id)");
    $cursor->execute();
    $cursor = $conn->prepare("CREATE INDEX IF NOT EXISTS idx_path ON tree_entries_v2(relative_path)");
    $cursor->execute();
    $cursor = $conn->prepare("CREATE INDEX IF NOT EXISTS idx_mtime ON tree_entries_v2(mtime_timestamp)");
    $cursor->execute();
    $cursor = $conn->prepare("CREATE INDEX IF NOT EXISTS idx_change_type ON tree_entries_v2(change_type)");
    $cursor->execute();

    $conn->commit();
    print "✅ tree.db Schema v2 erstellt/aktualisiert\n";
    return $self;
}

sub get_file_metadata {
    my ($self, $full_path) = @_;
    if (-e $full_path) {
        my @stat = stat($full_path);
        return {
            size       => $stat[7],
            mtime      => $stat[9],
            mtime_iso  => strftime("%Y-%m-%dT%H:%M:%S", localtime($stat[9])),
        };
    } else {
        return { size => 0, mtime => 0, mtime_iso => undef };
    }
}

sub generate_file_id {
    my ($self, $relative_path) = @_;
    return substr(md5_hex($relative_path), 0, 16);
}

sub scan_directory_detailed {
    my ($self, $root_path, $max_depth) = @_;
    $max_depth //= 8;
    my @entries;
    my $root = $root_path;

    find(sub {
        my $item = $File::Find::name;
        return if $item eq $root; # Skip the root itself

        # Calculate depth
        my $rel_path = File::Spec->abs2rel($item, $root);
        my @parts = split('/', $rel_path);
        my $depth = scalar(@parts);

        return if $depth > $max_depth;

        my $metadata = $self->get_file_metadata($item);
        my $file_id = $self->generate_file_id($rel_path);

        my $type = (-d $item) ? 'directory' : ((-l $item) ? 'symlink' : 'file');

        push @entries, {
            file_id              => $file_id,
            root_path            => $root_path,
            relative_path        => $rel_path,
            name                 => (split('/', $rel_path))[-1],
            type                 => $type,
            depth                => $depth,
            parent_path          => ($depth > 1) ? join('/', splice(@parts, 0, $depth - 1)) : '',
            size_bytes           => $metadata->{size},
            mtime_timestamp     => $metadata->{mtime},
            mtime_iso            => $metadata->{mtime_iso},
        };
    }, $root);

    return \@entries;
}

sub update_database {
    my ($self, $entries) = @_;
    my $conn = $self->connect();
    my $cursor;

    my $now = time();
    my $now_timestamp = $now;

    $cursor = $conn->prepare("UPDATE tree_entries_v2 SET change_type = NULL");
    $cursor->execute();

    my %stats = (new => 0, modified => 0, unchanged => 0, moved => 0);

    foreach my $entry (@$entries) {
        $cursor = $conn->prepare("SELECT * FROM tree_entries_v2 WHERE file_id = ?");
        $cursor->execute($entry->{file_id});
        my $existing = $cursor->fetchrow_hashref();

        if ($existing) {
            my $old_mtime = $existing->{mtime_timestamp} || 0;
            my $old_size = $existing->{size_bytes} || 0;
            my $old_path = $existing->{relative_path};

            my $size_change = $entry->{size_bytes} - $old_size;

            my $change_type;
            if ($old_path ne $entry->{relative_path}) {
                $change_type = 'MOVED';
                $stats{moved}++;
            } elsif ($old_mtime != $entry->{mtime_timestamp} || $old_size != $entry->{size_bytes}) {
                $change_type = 'MODIFIED';
                $stats{modified}++;
            } else {
                $change_type = 'UNCHANGED';
                $stats{unchanged}++;
            }

            $cursor = $conn->prepare(q{
                UPDATE tree_entries_v2 SET
                    size_bytes = ?,
                    previous_size_bytes = ?,
                    size_change_bytes = ?,
                    mtime_timestamp = ?,
                    mtime_iso = ?,
                    last_seen_timestamp = ?,
                    change_type = ?,
                    previous_path = ?,
                    original_path = COALESCE(original_path, ?),
                    updated_at = CURRENT_TIMESTAMP
                WHERE file_id = ?
            });
            $cursor->execute(
                $entry->{size_bytes},
                $old_size,
                $size_change,
                $entry->{mtime_timestamp},
                $entry->{mtime_iso},
                $now_timestamp,
                $change_type,
                ($change_type eq 'MOVED') ? $old_path : undef,
                ($change_type eq 'MOVED') ? $old_path : undef,
                $entry->{file_id}
            );

            if ($change_type eq 'MODIFIED' || $change_type eq 'MOVED') {
                $cursor = $conn->prepare(q{
                    INSERT INTO file_history
                    (file_id, timestamp, change_type, old_path, new_path, old_size, new_size)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                });
                $cursor->execute(
                    $entry->{file_id},
                    $now_timestamp,
                    $change_type,
                    $old_path,
                    $entry->{relative_path},
                    $old_size,
                    $entry->{size_bytes}
                );
            }
        } else {
            $stats{new}++;
            $cursor = $conn->prepare(q{
                INSERT INTO tree_entries_v2
                (file_id, root_path, relative_path, name, type, depth, parent_path,
                 size_bytes, previous_size_bytes, size_change_bytes,
                 mtime_timestamp, mtime_iso, first_seen_timestamp, last_seen_timestamp,
                 change_type, content_hash)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            });
            $cursor->execute(
                $entry->{file_id},
                $entry->{root_path},
                $entry->{relative_path},
                $entry->{name},
                $entry->{type},
                $entry->{depth},
                $entry->{parent_path},
                $entry->{size_bytes},
                $entry->{size_bytes},
                0,
                $entry->{mtime_timestamp},
                $entry->{mtime_iso},
                $now_timestamp,
                $now_timestamp,
                'NEW',
                undef
            );
        }
    }

    $cursor = $conn->prepare(q{
        SELECT * FROM tree_entries_v2 
        WHERE change_type IS NULL OR last_seen_timestamp < ?
    });
    $cursor->execute($now_timestamp - 3600);
    my $deleted = $cursor->fetchall_arrayref({});
    foreach my $item (@$deleted) {
        $cursor = $conn->prepare(q{
            UPDATE tree_entries_v2 
            SET change_type = 'DELETED', updated_at = CURRENT_TIMESTAMP
            WHERE file_id = ?
        });
        $cursor->execute($item->{file_id});
    }
    $stats{deleted} = scalar @$deleted;

    $conn->commit();
    return \%stats;
}

sub export_changes {
    my ($self, $since_hours) = @_;
    $since_hours //= 24;
    my $conn = $self->connect();
    my $cursor;

    my $since = time() - ($since_hours * 3600);

    $cursor = $conn->prepare(q{
        SELECT * FROM tree_entries_v2 
        WHERE change_type IN ('NEW', 'MODIFIED', 'MOVED', 'DELETED')
        AND last_seen_timestamp > ?
        ORDER BY last_seen_timestamp DESC
    });
    $cursor->execute($since);

    my $changes = $cursor->fetchall_arrayref({});

    my $export_file = "$WORKSPACE/tree_changes_last_${since_hours}h.json";
    open(my $fh, '>', $export_file) or die "Cannot write to $export_file: $!";
    print $fh to_json($changes, { pretty => 1 });
    close($fh);

    print "✅ Änderungen exportiert: $export_file (" . scalar(@$changes) . " Einträge)\n";
    return $export_file;
}

# Hauptprogramm
package main;

print "=" x 60 . "\n";
print "TREE INDEXER v2 - Erweitertes Tracking\n";
print "=" x 60 . "\n";

my $indexer = TreeIndexerV2->new();
$indexer->init_schema_v2();

print "\n--- Scanning Workspace ---\n";
my $entries = $indexer->scan_directory_detailed($WORKSPACE, 8);
print "Gefunden: " . scalar(@$entries) . " Einträge\n";

print "\n--- Aktualisiere Datenbank ---\n";
my $stats = $indexer->update_database($entries);
print "Statistiken:\n";
print "  NEU:        " . ($stats->{new} // 0) . "\n";
print "  MODIFIED:   " . ($stats->{modified} // 0) . "\n";
print "  MOVED:      " . ($stats->{moved} // 0) . "\n";
print "  UNCHANGED:  " . ($stats->{unchanged} // 0) . "\n";
print "  DELETED:    " . ($stats->{deleted} // 0) . "\n";

print "\n--- Exportiere Änderungen (24h) ---\n";
$indexer->export_changes(since_hours => 24);

print "\n" . "=" x 60 . "\n";
print "TREE INDEXING ABGESCHLOSSEN\n";
print "=" x 60 . "\n";
