#!/usr/bin/perl
# backup_dbs.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:tmp/backup_dbs.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Copy qw(copy);
use File::Path qw(make_path);
use POSIX qw(strftime);

# Backup docs.db and tree.db with timestamp into /workspace/db/backups

my $workspace = $ENV{'OPENCLAW_WORKSPACE'} // '/workspace';
my $backup_dir = "$workspace/db/backups";

# Ensure backup_dir exists
make_path($backup_dir) unless -d $backup_dir;

my $timestamp = strftime('%Y-%m-%d_%H-%M', localtime);

foreach my $db_name ('docs.db', 'tree.db') {
    my $src = "$workspace/$db_name";
    if (-f $src) {
        my $dest = "$backup_dir/${timestamp}_${db_name}.bak";
        copy($src, $dest) or warn "Copy failed: $!";
        print "Backup created: $dest\n";
    } else {
        print "Source db not found: $src\n";
    }
}
