#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "028c14898a5c2ca39c7ccdd406b9cc3547a934127dad214a2ffd8773b8f1a12e", "source_sha256": "42646f32f72b1ca4e041673cd4a65a4b6611379252e110d53df9fb001a5ba6de", "target_language": "perl5"}
# git_source_inventory.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/git_source_inventory.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use File::Path qw(make_path);
use File::Spec;
use Digest::SHA qw(sha256_hex);
use Cwd qw(getcwd);

# Git tree inventory and batched selected-blob loading.

sub write_private {
    my ($path, $data) = @_;
    open(my $fh, '>:raw', $path) or die "Cannot open $path: $!";
    print $fh $data;
    close($fh);
    chmod 0600, $path or die "Cannot chmod $path: $!";
}

sub snapshot {
    my ($manager, $run_id, $run_attempt, $workflow_sha) = @_;

    sub repository_index {
        my ($source) = @_;
        my $name = $source->{repo};
        my $mirror = File::Spec->catdir($manager->{QUELLEN_DIR}, "$name.git");

        sub git {
            my @args = @_;
            my $cmd = join(' ', 'git', '-C', $mirror, @args);
            open(my $pipe, '-|:raw', $cmd) or die "Cannot run git: $!";
            my $output = do { local $/; <$pipe> };
            close($pipe);
            return $output;
        }

        my @refs = split(/\n/, git('for-each-ref', '--format=%(refname:strip=2)%00%(objectname)', 'refs/heads'));
        my @selected;
        foreach my $line (@refs) {
            next unless $line =~ /\0/;
            my ($branch_bytes, $commit) = split(/\0/, $line, 2);
            my $branch = $branch_bytes;
            if ($source->{branches} eq 'alle' || grep { $_ eq $branch } @{$source->{branches}}) {
                push @selected, [$branch, $commit];
            }
        }

        sub branch_index {
            my ($item) = @_;
            my ($branch, $commit) = @$item;
            my @paths;
            my $tree_output = git('ls-tree', '-r', '-z', '--full-tree', $commit);
            my @entries = split(/\0/, $tree_output);
            foreach my $entry (@entries) {
                next unless $entry;
                my ($meta, $path) = split(/\t/, $entry, 2);
                my $text = $path;
                my @parts = split(/ /, $meta);
                if ($parts[1] eq 'blob') {
                    my $suffix = lc((split(/\./, $text))[-1] // '');
                    $suffix = ".$suffix" if $suffix && $suffix !~ /^\./;
                    if (exists $manager->{QUELLSPRACHEN}{$suffix}) {
                        push @paths, $text;
                    }
                }
            }
            return ($branch, { commit => $commit, paths => \@paths });
        }

        my %branches;
        foreach my $item (@selected) {
            my ($branch, $data) = branch_index($item);
            $branches{$branch} = $data;
        }

        my $expected_branches = $source->{branches} eq 'alle' ? 1 : scalar(@{$source->{branches}});
        if (!%branches || ($source->{branches} ne 'alle' && keys(%branches) != $expected_branches)) {
            die "incomplete source branches";
        }
        return ($name, \%branches);
    }

    my %repositories;
    foreach my $source (@{$manager->{QUELLEN}}) {
        my ($name, $branches) = repository_index($source);
        $repositories{$name} = $branches;
    }

    return {
        version => 1,
        run_id => $run_id,
        run_attempt => $run_attempt,
        workflow_sha => $workflow_sha,
        repositories => \%repositories
    };
}

sub prepare_git_sources {
    my ($manager, $directory, $state, $priority, $count, $run_id, $run_attempt, $workflow_sha) = @_;

    sub git {
        my ($mirror, @args) = @_;
        my $data = pop @args if $args[-1] && ref($args[-1]) eq 'SCALAR';
        $data = $$data if defined $data;
        
        my $cmd = join(' ', 'git', '-C', $mirror, @args);
        open(my $pipe, '|-', \$cmd) or die "Cannot run git: $!";
        if (defined $data) {
            print $pipe $data;
        }
        close($pipe);
        
        open(my $read_pipe, '-|:raw', $cmd) or die "Cannot run git: $!";
        my $output = do { local $/; <$read_pipe> };
        close($read_pipe);
        return $output;
    }

    make_path($manager->{QUELLEN_DIR}, { mode => 0755 }) unless -d $manager->{QUELLEN_DIR};

    sub update {
        my ($source) = @_;
        my $repo = $source->{repo};
        my $mirror = File::Spec->catdir($manager->{QUELLEN_DIR}, "$repo.git");
        my $result;
        if (-d $mirror) {
            $result = system("git", "-C", $mirror, "remote", "update", "--prune");
        } else {
            my $url = "https://github.com/$manager->{GITHUB_BENUTZER}/$repo.git";
            $result = system("git", "clone", "--mirror", "--filter=blob:none", $url, $mirror);
        }
        if ($result != 0) {
            die "$repo: Quellspiegel nicht verfuegbar";
        }
    }

    foreach my $source (@{$manager->{QUELLEN}}) {
        update($source);
    }

    my $index = snapshot($manager, $run_id, $run_attempt, $workflow_sha);
    my @sources;

    sub list_branch {
        my ($item) = @_;
        my ($repo, $branch, $commit) = @$item;
        my $mirror = File::Spec->catdir($manager->{QUELLEN_DIR}, "$repo.git");
        my @records;
        
        my $tree_output = git($mirror, "ls-tree", "-r", "-z", "--full-tree", $commit);
        my @entries = split(/\0/, $tree_output);
        foreach my $entry (@entries) {
            next unless $entry;
            my ($metadata, $raw_path) = split(/\t/, $entry, 2);
            my ($mode, $kind, $oid) = split(/ /, $metadata, 3);
            next if $kind ne "blob" || ($mode ne "100644" && $mode ne "100755");
            
            my $path = $raw_path;
            $path =~ s/\\\\/\//g;
            my $suffix = lc((split(/\./, $path))[-1] // '');
            $suffix = ".$suffix" if $suffix && $suffix !~ /^\./;
            my $language = $manager->{QUELLSPRACHEN}{$suffix};
            next unless defined $language;
            
            my $excluded = 0;
            foreach my $pattern (@{$manager->{AUSSCHLUSS}}) {
                if (index("/$path", $pattern) >= 0) {
                    $excluded = 1;
                    last;
                }
            }
            next if $excluded;
            
            if ($oid !~ /^[0-9a-f]{40}$/) {
                die "invalid Git blob identity";
            }
            push @records, [$repo, $branch, $commit, $path, $language, $oid];
        }
        return \@records;
    }

    my @branches;
    while (my ($repo, $details) = each %{$index->{repositories}}) {
        while (my ($branch, $data) = each %$details) {
            push @branches, [$repo, $branch, $data->{commit}];
        }
    }

    foreach my $branch_item (@branches) {
        my $records = list_branch($branch_item);
        push @sources, @$records;
    }

    my %grouped;
    foreach my $source_item (@sources) {
        my ($repo, $branch, $commit, $path, $language, $oid) = @$source_item;
        my $origin = "$repo\@$branch:$path";
        my $item = $grouped{$oid};
        if (!defined $item) {
            $item = {
                blob => $oid,
                repo => $repo,
                commit => $commit,
                path => $path,
                sprache => $language,
                herkunft => [],
                prioritaet => $manager->_prioritaet($path, $language)
            };
            $grouped{$oid} = $item;
        }
        push @{$item->{herkunft}}, $origin;
    }

    my %rank = (high => 0, medium => 1, low => 2);
    my @candidates = sort {
        $rank{$a->{prioritaet}} <=> $rank{$b->{prioritaet}} ||
        (split(/\//, $a->{path}))[-1] cmp (split(/\//, $b->{path}))[-1]
    } values %grouped;

    if ($priority ne "alle") {
        @candidates = grep { $_->{prioritaet} eq $priority } @candidates;
    }

    my $cursor = $state->{auswahl_blob_cursor}{$priority};
    if ($cursor) {
        my $pos;
        for my $i (0..$#candidates) {
            if ($candidates[$i]{blob} eq $cursor) {
                $pos = $i;
                last;
            }
        }
        if (defined $pos) {
            @candidates = (@candidates[$pos+1..$#candidates], @candidates[0..$pos]);
        }
    }

    my @selected = @candidates[0..($count-1)];
    my %by_repo;
    foreach my $item (@selected) {
        push @{$by_repo{$item->{repo}}}, $item;
    }

    sub read_blobs {
        my ($pair) = @_;
        my ($repo, $items) = @$pair;
        my $mirror = File::Spec->catdir($manager->{QUELLEN_DIR}, "$repo.git");
        
        my $requested = join('', map { $_->{blob} . "\n" } @$items);
        my $checks_raw = git($mirror, "cat-file", "--batch-check=%(objectname) %(objecttype) %(objectsize)", \$requested);
        my @checks = split(/\n/, $checks_raw);
        
        if (@checks != @$items) {
            die "incomplete Git blob metadata";
        }
        
        my @eligible;
        for my $i (0..$#checks) {
            my @fields = split(/ /, $checks[$i]);
            if (@fields != 3 || $fields[0] ne $items->[$i]{blob} || $fields[1] ne "blob") {
                die "invalid Git blob metadata";
            }
            if ($fields[2] <= $manager->{MAX_BYTES}) {
                push @eligible, [$items->[$i], $fields[2]];
            }
        }
        
        return [] unless @eligible;
        
        my $wanted = join('', map { $_->[0]{blob} . "\n" } @eligible);
        my $output_raw = git($mirror, "cat-file", "--batch", \$wanted);
        my $output = $output_raw;
        
        my @result;
        foreach my $elig_item (@eligible) {
            my ($item, $size) = @$elig_item;
            my $header_line = substr($output, 0, index($output, "\n")+1);
            $output = substr($output, length($header_line));
            chomp $header_line;
            my @header = split(/ /, $header_line);
            
            if (@header != 3 || $header[0] ne $item->{blob} || $header[1] ne "blob" || $header[2] != $size) {
                die "invalid Git blob response";
            }
            
            my $raw = substr($output, 0, $size);
            $output = substr($output, $size);
            
            if (length($raw) != $size || substr($output, 0, 1) ne "\n") {
                die "incomplete Git blob response";
            }
            $output = substr($output, 1);
            
            push @result, [$item, $raw];
        }
        return \@result;
    }

    my %loaded;
    while (my ($repo, $items) = each %by_repo) {
        my $result = read_blobs([$repo, $items]);
        foreach my $res_item (@$result) {
            my ($item, $raw) = @$res_item;
            $loaded{$item->{blob}} = $raw;
        }
    }

    my $source_dir = File::Spec->catdir($directory, "sources");
    make_path($source_dir, { mode => 0700 }) unless -d $source_dir;

    my @inventory;
    foreach my $item (@selected) {
        my $raw = $loaded{$item->{blob}};
        next unless defined $raw;
        next if $raw =~ /^\s*$/;
        next if $manager->enthaelt_zugangsdaten($raw);
        
        my $digest = sha256_hex($raw);
        my $target = File::Spec->catfile($source_dir, $digest);
        
        unless (-e $target) {
            write_private($target, $raw);
        }
        
        my $source_path = $item->{path};
        my @path_parts = split(/\//, $source_path);
        my $filename = $path_parts[-1];
        my $stem = $filename;
        $stem =~ s/\.[^.]*$//;
        
        push @inventory, {
            hash => substr($digest, 0, 16),
            name => $filename,
            stamm => $stem,
            sprache => $item->{sprache},
            bytes => length($raw),
            pfad => $target,
            herkunft => $item->{herkunft},
            prioritaet => $item->{prioritaet},
            css_only => 0,
            source_blob => $item->{blob},
            source_repo => $item->{repo},
            source_commit => $item->{commit},
            source_path => $item->{path},
            source_sha256 => $digest
        };
    }

    my $last_cursor = @selected ? $selected[-1]{blob} : undef;
    return ($index, \@inventory, $last_cursor);
}

1;
