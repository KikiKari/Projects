#!/usr/bin/perl
# update_docs_db.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:scripts/update_docs_db.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use DBI;
use File::Find;
use File::Spec;
use JSON;
use Text::CSV;
use POSIX qw(strftime);

# Konfiguration
my $WORKSPACE = "/home/openclaw/.openclaw/workspace";
my $DB_PATH = "$WORKSPACE/db/docs.db";

# Hauptprogramm
sub main {
    print "=" x 60 . "\n";
    print "DOCS.DB UPDATER\n";
    print "=" x 60 . "\n";

    print "\n--- Scanne Dokumentationen ---\n";
    my $docs = scan_documentations();
    print "Gefunden: " . scalar(@$docs) . " Dokumente\n";

    print "\n--- Aktualisiere docs.db ---\n";
    my $inserted = update_database($docs);
    print "✅ $inserted Dokumente in docs.db aktualisiert\n";

    print "\n--- Erstelle Exporte ---\n";
    export_all();

    print "\n" . "=" x 60 . "\n";
    print "DOCS.DB AKTUALISIERT\n";
    print "=" x 60 . "\n";
}

# Scannt alle .md Dateien im Workspace
sub scan_documentations {
    my @docs;

    # Hauptverzeichnis
    opendir(my $dh, $WORKSPACE) or die "Kann $WORKSPACE nicht öffnen: $!";
    while (readdir $dh) {
        next unless /\.md$/;
        my $file = "$WORKSPACE/$_";
        next unless -f $file && !(-l $file);
        push @docs, {
            name => $_,
            path => '/',
            category => 'main',
            description => get_description($file),
            type => 'doc',
            has_symlink => 0,
            symlink_path => undef,
            last_update => get_mtime($file)
        };
    }
    closedir $dh;

    # WebSearch Verzeichnis
    my $websearch_dir = "$WORKSPACE/websearch";
    if (-d $websearch_dir) {
        opendir(my $wh, $websearch_dir) or die "Kann $websearch_dir nicht öffnen: $!";
        while (readdir $wh) {
            next unless /\.md$/;
            my $file = "$websearch_dir/$_";
            push @docs, {
                name => $_,
                path => 'websearch/',
                category => 'websearch',
                description => get_description($file),
                type => ($_ =~ /GUIDE/) ? 'guide' : 'config',
                has_symlink => 1,
                symlink_path => "websearch/$_",
                last_update => get_mtime($file)
            };
        }
        closedir $wh;
    }

    # MCP Verzeichnis
    my $mcp_dir = "$WORKSPACE/mcp";
    if (-d $mcp_dir) {
        opendir(my $mh, $mcp_dir) or die "Kann $mcp_dir nicht öffnen: $!";
        while (readdir $mh) {
            next unless /\.md$/;
            my $file = "$mcp_dir/$_";
            my $is_symlink = -l $file;
            my $symlink_path = $is_symlink ? readlink($file) : undef;
            push @docs, {
                name => $_,
                path => 'mcp/',
                category => 'mcp',
                description => get_description($file),
                type => $is_symlink ? 'symlink' : 'guide',
                has_symlink => $is_symlink,
                symlink_path => $symlink_path,
                last_update => get_mtime($file)
            };
        }
        closedir $mh;
    }

    # Docs-Unterverzeichnisse
    my $docs_dir = "$WORKSPACE/docs";
    if (-d $docs_dir) {
        opendir(my $ddh, $docs_dir) or die "Kann $docs_dir nicht öffnen: $!";
        while (my $entry = readdir $ddh) {
            next if $entry =~ /^\.\.?$/;
            my $subdir = "$docs_dir/$entry";
            next unless -d $subdir;
            opendir(my $sdh, $subdir) or die "Kann $subdir nicht öffnen: $!";
            while (my $file = readdir $sdh) {
                next unless /\.md$/;
                my $full_path = "$subdir/$file";
                push @docs, {
                    name => $file,
                    path => "docs/$entry/",
                    category => $entry,
                    description => get_description($full_path),
                    type => 'doc',
                    has_symlink => 0,
                    symlink_path => undef,
                    last_update => get_mtime($full_path)
                };
            }
            closedir $sdh;
        }
        closedir $ddh;
    }

    # Cluster, Memory, Reports, Skills
    for my $category (qw(cluster memory reports skills)) {
        my $cat_dir = "$WORKSPACE/$category";
        if (-d $cat_dir) {
            opendir(my $ch, $cat_dir) or die "Kann $cat_dir nicht öffnen: $!";
            while (my $file = readdir $ch) {
                next unless /\.md$/;
                my $full_path = "$cat_dir/$file";
                push @docs, {
                    name => $file,
                    path => "$category/",
                    category => $category,
                    description => get_description($full_path),
                    type => 'doc',
                    has_symlink => 0,
                    symlink_path => undef,
                    last_update => get_mtime($full_path)
                };
            }
            closedir $ch;
        }
    }

    return \@docs;
}

# Extrahiert erste Zeile als Beschreibung
sub get_description {
    my ($file) = @_;
    open(my $fh, '<', $file) or return 'Dokumentation';
    my $first_line = <$fh>;
    close $fh;
    chomp $first_line;
    if ($first_line =~ /^#(.*)/) {
        $first_line = $1;
        $first_line =~ s/^\s+|\s+$//g;
        return $first_line;
    }
    if (length($first_line) > 50) {
        return substr($first_line, 0, 50) . '...';
    }
    return $first_line;
}

# Gibt letzte Änderung zurück
sub get_mtime {
    my ($file) = @_;
    my @stat = stat($file);
    if (@stat) {
        my $mtime = $stat[9];
        return strftime('%Y-%m-%d', localtime($mtime));
    }
    return '2026-04-18';
}

# Aktualisiert docs.db mit allen gefundenen Dokumenten
sub update_database {
    my ($docs) = @_;
    
    my $dbh = DBI->connect("dbi:SQLite:dbname=$DB_PATH", "", "", { RaiseError => 1 }) 
        or die "Kann keine Verbindung zur Datenbank herstellen: $DBI::errstr";
    
    # Lösche alte Einträge (außer config)
    $dbh->do("DELETE FROM documents WHERE category != 'config'");
    
    # Füge neue ein
    my $inserted = 0;
    my $sth = $dbh->prepare(q{
        INSERT INTO documents 
        (name, path, category, description, type, has_symlink, symlink_path, last_update)
        VALUES (?,?,?,?,?,?,?,?)
    });
    
    for my $doc (@$docs) {
        $sth->execute(
            $doc->{name}, $doc->{path}, $doc->{category},
            $doc->{description}, $doc->{type}, $doc->{has_symlink},
            $doc->{symlink_path}, $doc->{last_update}
        );
        $inserted++;
    }
    
    $dbh->commit;
    $dbh->disconnect;
    
    return $inserted;
}

# Erstellt alle Exporte
sub export_all {
    my $dbh = DBI->connect("dbi:SQLite:dbname=$DB_PATH", "", "", { RaiseError => 1 }) 
        or die "Kann keine Verbindung zur Datenbank herstellen: $DBI::errstr";
    
    # Tabellen exportieren
    my @tables = ('documents', 'skills', 'symlinks');
    for my $table (@tables) {
        my $sth = $dbh->prepare("SELECT * FROM $table");
        $sth->execute();
        
        # Sammle Spaltennamen
        my @columns = @{$sth->{NAME}};
        
        # Sammle Daten
        my @rows;
        while (my $row = $sth->fetchrow_hashref) {
            push @rows, $row;
        }
        
        # JSON Export
        my $json_text = encode_json(\@rows);
        my $json_path = "$WORKSPACE/db_${table}.json";
        open(my $json_fh, '>', $json_path) or die "Kann $json_path nicht schreiben: $!";
        print $json_fh $json_text;
        close $json_fh;
        print "✅ $json_path\n";
        
        # CSV Export
        my $csv_path = "$WORKSPACE/db_${table}.csv";
        open(my $csv_fh, '>', $csv_path) or die "Kann $csv_path nicht schreiben: $!";
        my $csv = Text::CSV->new({ binary => 1 });
        $csv->print($csv_fh, \@columns);
        print $csv_fh "\n";
        for my $row (@rows) {
            my @values = map { $row->{$_} } @columns;
            $csv->print($csv_fh, \@values);
            print $csv_fh "\n";
        }
        close $csv_fh;
        print "✅ $csv_path\n";
    }
    
    $dbh->disconnect;
}

# Starte das Programm
main();
