#!/usr/bin/perl
# tree_indexer.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:scripts/tree_indexer.py
# auch in: OpenClaw@gateway2:scripts/tree_indexer.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use DBI;
use File::Find;
use File::Spec;
use Cwd 'abs_path';
use POSIX qw(strftime);

# Tree Indexer - Scannt Verzeichnisbäume und speichert in tree.db

my $WORKSPACE = "/home/openclaw/.openclaw/workspace";
my $DB_DIR = "$WORKSPACE/db";

package TreeIndexer;

sub new {
    my $class = shift;
    my $self = {
        db_path => "$DB_DIR/tree.db",
        conn    => undef
    };
    bless $self, $class;
    return $self;
}

sub connect {
    my $self = shift;
    $self->{conn} = DBI->connect("dbi:SQLite:dbname=$self->{db_path}", "", "", {
        RaiseError => 1,
        AutoCommit => 0
    }) or die "❌ Konnte keine Verbindung zur Datenbank herstellen: $DBI::errstr\n";
    return $self->{conn};
}

sub run_tree {
    my ($self, $root_path, $max_depth) = @_;
    # Führt tree -a -L {depth} aus und parst Ausgabe
    eval {
        local $SIG{ALRM} = sub { die "Timeout" };
        alarm(30);
        my $cmd = "tree -a -L $max_depth '$root_path'";
        my $output = `$cmd`;
        alarm(0);
        return $output;
    };
    if ($@) {
        warn "❌ Fehler bei tree $root_path: $@\n";
        return undef;
    }
    return undef;
}

sub parse_tree_output {
    my ($self, $tree_output, $root_path) = @_;
    # Parst tree-Ausgabe und extrahiert Einträge
    my @entries = ();
    my @lines = split /\n/, $tree_output;

    # Regex für tree-Zeilen
    # Beispiel: "├── .bash_history" oder "│   ├── bin"
    my $pattern = qr/^[│ ]*[├└]── (.+)$/;

    for my $line (@lines) {
        if ($line =~ /$pattern/) {
            my $name = $1;
            $name =~ s/^\s+|\s+$//g; # trim
            # Tiefe bestimmen durch Anzahl der │ und Leerzeichen
            my $depth = ($line =~ tr/│//) + (($line =~ /(    )/g) || 0);

            # Typ bestimmen
            my $entry_type;
            if ($name =~ s/\/$//) {
                $entry_type = 'directory';
            } elsif ($name =~ / -> /) {
                $entry_type = 'symlink';
                $name = (split / -> /, $name)[0];
            } else {
                $entry_type = 'file';
            }

            push @entries, {
                name => $name,
                type => $entry_type,
                depth => $depth,
                line => $line
            };
        }
    }

    return \@entries;
}

sub save_to_db {
    my ($self, $root_path, $max_depth, $entries) = @_;
    # Speichert Einträge in tree.db
    my $conn = $self->connect();
    my $cursor = $conn->prepare("INSERT INTO tree_scans (root_path, max_depth, total_files, total_dirs, total_symlinks) VALUES (?,?,?,?,?)");

    # Scan-Metadaten
    my $total_files = scalar grep { $_->{type} eq 'file' } @$entries;
    my $total_dirs = scalar grep { $_->{type} eq 'directory' } @$entries;
    my $total_symlinks = scalar grep { $_->{type} eq 'symlink' } @$entries;

    $cursor->execute($root_path, $max_depth, $total_files, $total_dirs, $total_symlinks);
    my $scan_id = $conn->last_insert_id("", "", "tree_scans", "");

    # Einträge speichern
    my $insert_entry = $conn->prepare(q{
        INSERT INTO tree_entries 
        (root_path, relative_path, name, type, depth, parent_path, size)
        VALUES (?,?,?,?,?,?,0)
    });

    for my $entry (@$entries) {
        $insert_entry->execute(
            $root_path,
            $entry->{name},
            $entry->{name},
            $entry->{type},
            $entry->{depth},
            $root_path
        );
    }

    $conn->commit();
    print "✅ " . scalar(@$entries) . " Einträge gespeichert für $root_path\n";
    return $scan_id;
}

sub index_directory {
    my ($self, $root_path, $max_depth) = @_;
    # Komplette Indexierung eines Verzeichnisses
    print "\n--- Indexiere: $root_path (Depth: $max_depth) ---\n";
    my $tree_output = $self->run_tree($root_path, $max_depth);

    if (defined $tree_output) {
        my $entries = $self->parse_tree_output($tree_output, $root_path);
        if (@$entries) {
            return $self->save_to_db($root_path, $max_depth, $entries);
        }
    }
    return undef;
}

sub export_csv {
    my $self = shift;
    # Exportiert alle Tree-Einträge als CSV
    my $conn = $self->connect();
    my $cursor = $conn->prepare("SELECT * FROM tree_entries ORDER BY root_path, depth, name");
    $cursor->execute();
    my $rows = $cursor->fetchall_arrayref({});

    if (!@$rows) {
        print "⚠️ Keine Tree-Daten vorhanden\n";
        return undef;
    }

    my $csv_path = "$WORKSPACE/export_tree_all.csv";
    open(my $fh, '>', $csv_path) or die "❌ Konnte $csv_path nicht öffnen: $!\n";

    # Header schreiben
    my @header = keys %{$rows->[0]};
    print $fh join(",", @header) . "\n";

    # Daten schreiben
    for my $row (@$rows) {
        my @values = map { defined $row->{$_} ? $row->{$_} : '' } @header;
        print $fh join(",", @values) . "\n";
    }

    close $fh;
    print "✅ Tree CSV exportiert: $csv_path (" . scalar(@$rows) . " Einträge)\n";
    return $csv_path;
}

sub export_by_root {
    my $self = shift;
    # Exportiert getrennt nach root_path
    my $conn = $self->connect();
    my $cursor = $conn->prepare("SELECT DISTINCT root_path FROM tree_entries");
    $cursor->execute();
    my $roots = $cursor->fetchall_arrayref();

    my @exports = ();
    for my $row (@$roots) {
        my $root_path = $row->[0];
        my $safe_name = $root_path;
        $safe_name =~ s/\///g;
        $safe_name =~ s/\.//g;
        my $csv_path = "$WORKSPACE/export_tree$safe_name.csv";

        my $select_cursor = $conn->prepare("SELECT * FROM tree_entries WHERE root_path = ? ORDER BY depth, name");
        $select_cursor->execute($root_path);
        my $rows = $select_cursor->fetchall_arrayref({});

        open(my $fh, '>', $csv_path) or die "❌ Konnte $csv_path nicht öffnen: $!\n";

        # Header schreiben
        my @header = keys %{$rows->[0]};
        print $fh join(",", @header) . "\n";

        # Daten schreiben
        for my $row (@$rows) {
            my @values = map { defined $row->{$_} ? $row->{$_} : '' } @header;
            print $fh join(",", @values) . "\n";
        }

        close $fh;
        push @exports, [$root_path, $csv_path, scalar(@$rows)];
        print "✅ Export $root_path: $csv_path (" . scalar(@$rows) . " Einträge)\n";
    }

    return \@exports;
}

package main;

sub main {
    print "=" x 60 . "\n";
    print "TREE INDEXER\n";
    print "=" x 60 . "\n";

    my $indexer = TreeIndexer->new();

    # 1. /home/openclaw/ mit depth 3
    $indexer->index_directory('/home/openclaw/', 3);

    # 2. Workspace mit depth 6
    $indexer->index_directory('/home/openclaw/.openclaw/workspace/', 6);

    # Exporte erstellen
    print "\n--- Exporte ---\n";
    $indexer->export_csv();
    $indexer->export_by_root();

    print "\n" . "=" x 60 . "\n";
    print "TREE INDEXIERUNG ABGESCHLOSSEN\n";
    print "=" x 60 . "\n";
}

main() unless caller;
