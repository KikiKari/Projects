#!/usr/bin/perl
# tree_indexer_v2.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:scripts/tree_indexer_v2.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use DBI;
use File::Find;
use File::Spec;
use Digest::MD5 qw(md5_hex);
use POSIX qw(strftime);

# Tree Indexer v2 - Erweitertes Tracking mit Metadaten

my $WORKSPACE = '/workspace';
my $DB_DIR = $WORKSPACE;

package TreeIndexerV2;

sub new {
    my $class = shift;
    my $self = {
        db_path => "$WORKSPACE/db/tree.db",
        conn => undef,
    };
    bless $self, $class;
    return $self;
}

sub connect {
    my $self = shift;
    unless ($self->{conn}) {
        $self->{conn} = DBI->connect("dbi:SQLite:dbname=$self->{db_path}", "", "", { RaiseError => 1, AutoCommit => 0 });
    }
    return $self->{conn};
}

sub init_schema_v2 {
    my $self = shift;
    my $conn = $self->connect();
    
    # Haupttabelle mit erweiterten Metadaten
    $conn->do(qq{
        CREATE TABLE IF NOT EXISTS tree_entries_v2 (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            file_id TEXT UNIQUE,              -- Eindeutige Datei-ID (Hash von Pfad)
            root_path TEXT NOT NULL,
            relative_path TEXT NOT NULL,
            name TEXT NOT NULL,
            type TEXT CHECK(type IN ('file', 'directory', 'symlink')),
            depth INTEGER,
            parent_path TEXT,
            
            -- Größen-Tracking
            size_bytes INTEGER,               -- Aktuelle Größe
            previous_size_bytes INTEGER,      -- Vorherige Größe (für Delta)
            size_change_bytes INTEGER,        -- Änderung (positiv/negativ)
            
            -- Zeitstempel
            mtime_timestamp REAL,             -- Letzte Änderung (Unix timestamp)
            mtime_iso TEXT,                   -- ISO-Format für Lesbarkeit
            first_seen_timestamp REAL,        -- Wann wurde Datei erste Mal gesehen
            last_seen_timestamp REAL,         -- Wann wurde Datei zuletzt gesehen
            
            -- Änderungs-Tracking
            change_type TEXT CHECK(change_type IN ('NEW', 'MODIFIED', 'MOVED', 'RENAMED', 'UNCHANGED', 'DELETED')),
            
            -- Historie
            original_name TEXT,               -- Ursprünglicher Name wenn umbenannt
            original_path TEXT,               -- Ursprünglicher Pfad wenn verschoben
            previous_path TEXT,               -- Vorheriger Pfad
            
            -- Content-Hash (optionale Integritätsprüfung)
            content_hash TEXT,                -- MD5 der Datei (nur für kleine Dateien)
            
            -- Metadaten
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    });
    
    # Historie-Tabelle für alle Änderungen
    $conn->do(qq{
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
    
    # Index für schnelle Suchen
    $conn->do('CREATE INDEX IF NOT EXISTS idx_file_id ON tree_entries_v2(file_id)');
    $conn->do('CREATE INDEX IF NOT EXISTS idx_path ON tree_entries_v2(relative_path)');
    $conn->do('CREATE INDEX IF NOT EXISTS idx_mtime ON tree_entries_v2(mtime_timestamp)');
    $conn->do('CREATE INDEX IF NOT EXISTS idx_change_type ON tree_entries_v2(change_type)');
    
    $conn->commit();
    print "✅ tree.db Schema v2 erstellt/aktualisiert\n";
    return $self;
}

sub get_file_metadata {
    my ($self, $full_path) = @_;
    my %metadata = (size => 0, mtime => 0, mtime_iso => undef);
    
    if (-e $full_path) {
        my @stat = stat($full_path);
        if (@stat) {
            $metadata{size} = $stat[7];
            $metadata{mtime} = $stat[9];
            $metadata{mtime_iso} = strftime("%Y-%m-%dT%H:%M:%S", localtime($stat[9]));
        }
    }
    
    return \%metadata;
}

sub generate_file_id {
    my ($self, $relative_path) = @_;
    return substr(md5_hex($relative_path), 0, 16);
}

sub scan_directory_detailed {
    my ($self, $root_path, $max_depth) = @_;
    $max_depth //= 8;
    
    my @entries;
    my $root_length = length($root_path);
    
    find(sub {
        my $item = $File::Find::name;
        return if ($item eq $root_path);
        
        # Max depth prüfen
        my $relative_item = substr($item, $root_length + 1);
        my @parts = split('/', $relative_item);
        my $depth = scalar(@parts);
        
        if ($depth > $max_depth) {
            return;
        }
        
        my $relative_path = $relative_item;
        my $file_id = $self->generate_file_id($relative_path);
        my $metadata = $self->get_file_metadata($item);
        
        my $entry = {
            file_id => $file_id,
            root_path => $root_path,
            relative_path => $relative_path,
            name => $_,
            type => (-d $_) ? 'directory' : ((-l $_) ? 'symlink' : 'file'),
            depth => $depth,
            parent_path => ($depth > 1) ? join('/', @parts[0..$#parts-1]) : '',
            size_bytes => $metadata->{size},
            mtime_timestamp => $metadata->{mtime},
            mtime_iso => $metadata->{mtime_iso},
        };
        push @entries, $entry;
    }, $root_path);
    
    return \@entries;
}

sub update_database {
    my ($self, $entries) = @_;
    my $conn = $self->connect();
    my $cursor = $conn->prepare("SELECT * FROM tree_entries_v2 WHERE file_id = ?");
    
    # Aktuelle Zeit
    my $now = time();
    my $now_timestamp = $now;
    
    # Alle bestehenden Einträge als "potentiell gelöscht" markieren
    $conn->do("UPDATE tree_entries_v2 SET change_type = NULL");
    
    my %stats = (new => 0, modified => 0, unchanged => 0, moved => 0);
    
    foreach my $entry (@$entries) {
        $cursor->execute($entry->{file_id});
        my $existing = $cursor->fetchrow_hashref();
        
        if ($existing) {
            # Vergleiche Metadaten
            my $old_mtime = $existing->{mtime_timestamp} || 0;
            my $old_size = $existing->{size_bytes} || 0;
            my $old_path = $existing->{relative_path};
            
            # Größenänderung berechnen
            my $size_change = $entry->{size_bytes} - $old_size;
            
            # Änderungstyp bestimmen
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
            
            # Update
            my $update_stmt = $conn->prepare(qq{
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
            $update_stmt->execute(
                $entry->{size_bytes},
                $old_size,
                $size_change,
                $entry->{mtime_timestamp},
                $entry->{mtime_iso},
                $now_timestamp,
                $change_type,
                ($change_type eq 'MOVED') ? $old_path : undef,
                ($change_type eq 'MOVED') ? $old_path : $existing->{original_path},
                $entry->{file_id}
            );
            
            # Änderung in Historie loggen
            if ($change_type eq 'MODIFIED' || $change_type eq 'MOVED') {
                my $history_stmt = $conn->prepare(qq{
                    INSERT INTO file_history
                    (file_id, timestamp, change_type, old_path, new_path, old_size, new_size)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                });
                $history_stmt->execute(
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
            # Neue Datei
            $stats{new}++;
            my $insert_stmt = $conn->prepare(qq{
                INSERT INTO tree_entries_v2
                (file_id, root_path, relative_path, name, type, depth, parent_path,
                 size_bytes, previous_size_bytes, size_change_bytes,
                 mtime_timestamp, mtime_iso, first_seen_timestamp, last_seen_timestamp,
                 change_type, content_hash)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            });
            $insert_stmt->execute(
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
                undef  # content_hash
            );
        }
    }
    
    # Markiere nicht aktualisierte Einträge als DELETED
    my $select_deleted = $conn->prepare(qq{
        SELECT * FROM tree_entries_v2 
        WHERE change_type IS NULL OR last_seen_timestamp < ?
    });
    $select_deleted->execute($now_timestamp - 3600); # Älter als 1 Stunde
    
    my @deleted;
    while (my $row = $select_deleted->fetchrow_hashref()) {
        push @deleted, $row;
    }
    
    foreach my $item (@deleted) {
        my $delete_stmt = $conn->prepare(qq{
            UPDATE tree_entries_v2 
            SET change_type = 'DELETED', updated_at = CURRENT_TIMESTAMP
            WHERE file_id = ?
        });
        $delete_stmt->execute($item->{file_id});
    }
    
    $stats{deleted} = scalar(@deleted);
    
    $conn->commit();
    return \%stats;
}

sub export_changes {
    my ($self, $since_hours) = @_;
    $since_hours //= 24;
    
    my $conn = $self->connect();
    my $cursor = $conn->prepare(qq{
        SELECT * FROM tree_entries_v2 
        WHERE change_type IN ('NEW', 'MODIFIED', 'MOVED', 'DELETED')
        AND last_seen_timestamp > ?
        ORDER BY last_seen_timestamp DESC
    });
    
    my $since = time() - ($since_hours * 3600);
    $cursor->execute($since);
    
    my @changes;
    while (my $row = $cursor->fetchrow_hashref()) {
        push @changes, $row;
    }
    
    # Export als JSON
    my $export_file = "$WORKSPACE/tree_changes_last_${since_hours}h.json";
    
    open(my $fh, '>', $export_file) or die "Could not open file '$export_file' $!";
    print $fh "[\n";
    for my $i (0 .. $#changes) {
        my $row = $changes[$i];
        print $fh "  {\n";
        my @keys = keys %$row;
        for my $j (0 .. $#keys) {
            my $key = $keys[$j];
            my $value = defined $row->{$key} ? "\"$row->{$key}\"" : "null";
            print $fh "    \"$key\": $value";
            print $fh "," if $j < $#keys;
            print $fh "\n";
        }
        print $fh "  }";
        print $fh "," if $i < $#changes;
        print $fh "\n";
    }
    print $fh "]\n";
    close $fh;
    
    print "✅ Änderungen exportiert: $export_file (" . scalar(@changes) . " Einträge)\n";
    return $export_file;
}

sub main {
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
    $indexer->export_changes(24);
    
    print "\n" . "=" x 60 . "\n";
    print "TREE INDEXING ABGESCHLOSSEN\n";
    print "=" x 60 . "\n";
}

main() unless caller;
