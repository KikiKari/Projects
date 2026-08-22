#!/usr/bin/env perl
# update_docs_db.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:scripts/update_docs_db.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Digest::MD5;
use JSON;
use DBI;
use File::Find;
use File::Spec;
use Cwd qw(abs_path);

my $WORKSPACE = $ENV{'OPENCLAW_WORKSPACE'} // do {
    my $script_dir = dirname(abs_path($0));
    my @parts = split('/', $script_dir);
    pop @parts; # remove script name
    join('/', @parts);
};

my $DB_PATH = "$WORKSPACE/docs.db";

sub dirname {
    my ($path) = @_;
    $path =~ s/\/[^\/]*$//;
    return $path;
}

sub iter_docs {
    my @files;
    find(sub {
        return unless /\.md$/ && -f $_ && ! -l $_;
        my $rel_path = File::Spec->abs2rel($File::Find::name, $WORKSPACE);
        my @parts = split('/', $rel_path);
        return if grep { $_ eq 'node_modules' || $_ eq '.git' || $_ eq 'backups' } @parts;
        push @files, $File::Find::name;
    }, $WORKSPACE);
    return @files;
}

sub file_hash {
    my ($path) = @_;
    open(my $fh, '<', $path) or die "Cannot open $path: $!";
    binmode($fh);
    my $digest = Digest::MD5->new;
    while (read($fh, my $buffer, 8192)) {
        $digest->add($buffer);
    }
    close($fh);
    return $digest->hexdigest;
}

sub word_count {
    my ($path) = @_;
    open(my $fh, '<:encoding(UTF-8)', $path) or return 0;
    my $text = do { local $/; <$fh> };
    close($fh);
    return scalar(split(/\s+/, $text));
}

sub build_rows {
    my $indexed = time();
    my @rows;
    for my $md_file (iter_docs()) {
        my $rel_path = File::Spec->abs2rel($md_file, $WORKSPACE);
        push @rows, {
            path => $rel_path,
            content_hash => file_hash($md_file),
            last_indexed => $indexed,
            word_count => word_count($md_file),
        };
    }
    return @rows;
}

sub ensure_schema {
    my ($dbh) = @_;
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS documents (
            path TEXT PRIMARY KEY,
            content_hash TEXT,
            last_indexed REAL,
            word_count INTEGER
        )
    });
    $dbh->do(q{
        CREATE TABLE IF NOT EXISTS tags (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT,
            tag TEXT
        )
    });
}

sub update_database {
    my (@rows) = @_;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$DB_PATH", "", "", { RaiseError => 1 }) or die $DBI::errstr;
    eval {
        ensure_schema($dbh);
        $dbh->do('DELETE FROM documents');
        my $sth = $dbh->prepare('INSERT INTO documents (path, content_hash, last_indexed, word_count) VALUES (?, ?, ?, ?)');
        for my $row (@rows) {
            $sth->execute($row->{path}, $row->{content_hash}, $row->{last_indexed}, $row->{word_count});
        }
        $dbh->commit;
    };
    my $error = $@;
    $dbh->disconnect;
    die $error if $error;
}

sub export_table {
    my ($table) = @_;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$DB_PATH", "", "", { RaiseError => 1 }) or die $DBI::errstr;
    $dbh->{sqlite_unicode} = 1;
    my $rows = $dbh->selectall_arrayref("SELECT * FROM $table", { Slice => {} });
    $dbh->disconnect;

    my $json_path = "$WORKSPACE/db_${table}.json";
    my $json_text = to_json($rows, { pretty => 1 });
    open(my $jh, '>', $json_path) or die "Cannot write to $json_path: $!";
    print $jh $json_text;
    close($jh);

    my $csv_path = "$WORKSPACE/db_${table}.csv";
    open(my $ch, '>', $csv_path) or die "Cannot write to $csv_path: $!";
    if (@$rows) {
        my @keys = keys %{$rows->[0]};
        print $ch join(',', map { "\"$_\"" } @keys) . "\n";
        for my $row (@$rows) {
            print $ch join(',', map { defined $row->{$_} ? "\"$row->{$_}\"" : '""' } @keys) . "\n";
        }
    } else {
        print $ch "\n";
    }
    close($ch);
}

sub main {
    print '=' x 60 . "\n";
    print "DOCS.DB UPDATER\n";
    print '=' x 60 . "\n";
    my @rows = build_rows();
    print "Gefunden: " . scalar(@rows) . " Dokumente\n";
    update_database(@rows);
    print "✅ " . scalar(@rows) . " Dokumente in docs.db aktualisiert\n";
    export_table('documents');
    export_table('tags');
    print "✅ Exporte aktualisiert\n";
    print "\n" . '=' x 60 . "\n";
    print "DOCS.DB AKTUALISIERT\n";
    print '=' x 60 . "\n";
}

main() if __FILE__ eq $0;
