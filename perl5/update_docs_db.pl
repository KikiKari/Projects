#!/usr/bin/env perl
# update_docs_db.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:scripts/update_docs_db.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use JSON qw(encode_json);
use File::Find;
use File::Spec;
use DBI;

my $WORKSPACE = '/workspace';
my $DB_PATH = "$WORKSPACE/db/docs.db";

sub iter_docs {
    my @files;
    find(sub {
        return unless -f $_ && $_ =~ /\.md$/;
        my $rel_path = File::Spec->abs2rel($File::Find::name, $WORKSPACE);
        return if $rel_path =~ m{(?:^|/)(?:node_modules|\.git|backups)(?:/|$)};
        push @files, $File::Find::name;
    }, $WORKSPACE);
    return @files;
}

sub file_hash {
    my ($path) = @_;
    open my $fh, '<:raw', $path or die "Cannot open $path: $!";
    my $ctx = Digest::MD5->new;
    while (read($fh, my $buffer, 8192)) {
        $ctx->add($buffer);
    }
    close $fh;
    return $ctx->hexdigest;
}

sub word_count {
    my ($path) = @_;
    open my $fh, '<:encoding(UTF-8)', $path or return 0;
    local $/;
    my $text = <$fh>;
    close $fh;
    return scalar(split /\s+/, $text // '');
}

sub build_rows {
    my $indexed = time();
    my @rows;
    for my $file (iter_docs()) {
        my $rel_path = File::Spec->abs2rel($file, $WORKSPACE);
        push @rows, {
            path => $rel_path,
            content_hash => file_hash($file),
            last_indexed => $indexed,
            word_count => word_count($file),
        };
    }
    return \@rows;
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
    my ($rows) = @_;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$DB_PATH", "", "", { RaiseError => 1 });
    ensure_schema($dbh);
    $dbh->do('DELETE FROM documents');
    my $sth = $dbh->prepare('INSERT INTO documents (path, content_hash, last_indexed, word_count) VALUES (?, ?, ?, ?)');
    for my $row (@$rows) {
        $sth->execute($row->{path}, $row->{content_hash}, $row->{last_indexed}, $row->{word_count});
    }
    $dbh->commit;
    $dbh->disconnect;
}

sub export_table {
    my ($table) = @_;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$DB_PATH", "", "", { RaiseError => 1, sqlite_unicode => 1 });
    $dbh->{sqlite_unicode} = 1;
    my $rows = $dbh->selectall_arrayref("SELECT * FROM $table", { Slice => {} });
    my @data = @$rows;
    my $json_path = "$WORKSPACE/db_${table}.json";
    my $csv_path = "$WORKSPACE/db_${table}.csv";
    
    open my $json_fh, '>:encoding(UTF-8)', $json_path or die "Cannot write to $json_path: $!";
    print $json_fh encode_json(\@data);
    close $json_fh;
    
    open my $csv_fh, '>:encoding(UTF-8)', $csv_path or die "Cannot write to $csv_path: $!";
    if (@data) {
        my @keys = keys %{$data[0]};
        print $csv_fh join(',', map { "\"$_\"" } @keys) . "\n";
        for my $row (@data) {
            print $csv_fh join(',', map { defined $row->{$_} ? "\"$row->{$_}\"" : '""' } @keys) . "\n";
        }
    } else {
        print $csv_fh "\n";
    }
    close $csv_fh;
    $dbh->disconnect;
}

sub main {
    print '=' x 60 . "\n";
    print "DOCS.DB UPDATER\n";
    print '=' x 60 . "\n";
    my $rows = build_rows();
    print "Gefunden: " . scalar(@$rows) . " Dokumente\n";
    update_database($rows);
    print "✅ " . scalar(@$rows) . " Dokumente in docs.db aktualisiert\n";
    export_table('documents');
    export_table('tags');
    print "✅ Exporte aktualisiert\n";
    print "\n" . '=' x 60 . "\n";
    print "DOCS.DB AKTUALISIERT\n";
    print '=' x 60 . "\n";
}

main() if __FILE__ eq $0;
