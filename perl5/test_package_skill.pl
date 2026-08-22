#!/usr/bin/env perl
# test_package_skill.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/test_package_skill.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/test_package_skill.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Temp qw(tempdir);
use File::Path qw(remove_tree);
use File::Spec;
use Cwd qw(abs_path);
use lib '.';
use Test::More;
use Test::MockModule;

# Mock quick_validate module
my $mock_quick_validate = Test::MockModule->new('quick_validate');
$mock_quick_validate->mock('validate_skill', sub { return (1, "Skill is valid!"); });

require package_skill;

# Add script directory to @INC if needed
my $script_dir = dirname(abs_path($0));
unshift @INC, $script_dir unless grep { $_ eq $script_dir } @INC;

sub dirname {
    my ($path) = @_;
    $path =~ s/\/[^\/]*$//;
    return $path || '/';
}

sub tempdir_wrapper {
    my ($prefix) = @_;
    return tempdir(CLEANUP => 0, TEMPLATE => "/tmp/${prefix}XXXXXX");
}

sub create_skill {
    my ($self, $name) = @_;
    $name //= "test-skill";
    my $skill_dir = File::Spec->catdir($self->{temp_dir}, $name);
    mkdir $skill_dir unless -d $skill_dir;
    
    my $skill_md = File::Spec->catfile($skill_dir, "SKILL.md");
    open my $fh, '>', $skill_md or die "Cannot write to $skill_md: $!";
    print $fh "---\nname: test-skill\ndescription: test\n---\n";
    close $fh;
    
    my $script_py = File::Spec->catfile($skill_dir, "script.py");
    open $fh, '>', $script_py or die "Cannot write to $script_py: $!";
    print $fh "print('ok')\n";
    close $fh;
    
    return $skill_dir;
}

sub setUp {
    my $self = shift;
    $self->{temp_dir} = tempdir_wrapper("test_skill_");
}

sub tearDown {
    my $self = shift;
    if (-d $self->{temp_dir}) {
        remove_tree($self->{temp_dir});
    }
}

sub test_packages_normal_files {
    my $self = shift;
    $self->setUp();
    
    my $skill_dir = create_skill($self, "normal-skill");
    my $out_dir = File::Spec->catdir($self->{temp_dir}, "out");
    mkdir $out_dir unless -d $out_dir;
    
    my $result = package_skill::package_skill($skill_dir, $out_dir);
    
    ok(defined $result, "Result should be defined");
    
    my $skill_file = File::Spec->catfile($out_dir, "normal-skill.skill");
    ok(-f $skill_file, "Skill file should exist");
    
    # Check zip contents
    my @names = list_zip_contents($skill_file);
    my %name_set = map { $_ => 1 } @names;
    
    ok(exists $name_set{"normal-skill/SKILL.md"}, "Should contain SKILL.md");
    ok(exists $name_set{"normal-skill/script.py"}, "Should contain script.py");
    
    $self->tearDown();
}

sub test_skips_symlink_to_external_file {
    my $self = shift;
    $self->setUp();
    
    my $skill_dir = create_skill($self, "symlink-file-skill");
    my $outside = File::Spec->catfile($self->{temp_dir}, "outside-secret.txt");
    
    open my $fh, '>', $outside or die "Cannot write to $outside: $!";
    print $fh "super-secret\n";
    close $fh;
    
    my $link = File::Spec->catfile($skill_dir, "loot.txt");
    my $out_dir = File::Spec->catdir($self->{temp_dir}, "out");
    mkdir $out_dir unless -d $out_dir;
    
    eval {
        symlink($outside, $link) or die "symlink failed: $!";
    };
    if ($@) {
        plan skip_all => "symlink unsupported on this platform";
        return;
    }
    
    my $result = package_skill::package_skill($skill_dir, $out_dir);
    ok(defined $result, "Result should be defined");
    
    my $skill_file = File::Spec->catfile($out_dir, "symlink-file-skill.skill");
    ok(-f $skill_file, "Skill file should exist");
    
    my @names = list_zip_contents($skill_file);
    my %name_set = map { $_ => 1 } @names;
    
    ok(exists $name_set{"symlink-file-skill/SKILL.md"}, "Should contain SKILL.md");
    ok(exists $name_set{"symlink-file-skill/script.py"}, "Should contain script.py");
    ok(!exists $name_set{"symlink-file-skill/loot.txt"}, "Should NOT contain loot.txt");
    
    $self->tearDown();
}

sub test_skips_symlink_directory {
    my $self = shift;
    $self->setUp();
    
    my $skill_dir = create_skill($self, "symlink-dir-skill");
    my $outside_dir = File::Spec->catdir($self->{temp_dir}, "outside");
    mkdir $outside_dir unless -d $outside_dir;
    
    my $secret_file = File::Spec->catfile($outside_dir, "secret.txt");
    open my $fh, '>', $secret_file or die "Cannot write to $secret_file: $!";
    print $fh "secret\n";
    close $fh;
    
    my $link = File::Spec->catdir($skill_dir, "docs");
    my $out_dir = File::Spec->catdir($self->{temp_dir}, "out");
    mkdir $out_dir unless -d $out_dir;
    
    eval {
        symlink($outside_dir, $link) or die "symlink failed: $!";
    };
    if ($@) {
        plan skip_all => "symlink unsupported on this platform";
        return;
    }
    
    my $result = package_skill::package_skill($skill_dir, $out_dir);
    ok(defined $result, "Result should be defined");
    
    my $skill_file = File::Spec->catfile($out_dir, "symlink-dir-skill.skill");
    
    my @names = list_zip_contents($skill_file);
    my %name_set = map { $_ => 1 } @names;
    
    ok(exists $name_set{"symlink-dir-skill/SKILL.md"}, "Should contain SKILL.md");
    ok(exists $name_set{"symlink-dir-skill/script.py"}, "Should contain script.py");
    ok(!exists $name_set{"symlink-dir-skill/docs/secret.txt"}, "Should NOT contain secret.txt");
    
    $self->tearDown();
}

sub test_rejects_resolved_path_outside_skill_root {
    my $self = shift;
    $self->setUp();
    
    my $skill_dir = create_skill($self, "escape-skill");
    my $out_dir = File::Spec->catdir($self->{temp_dir}, "out");
    mkdir $out_dir unless -d $out_dir;
    
    # Mock _is_within function
    no warnings 'redefine';
    no strict 'refs';
    my $orig_is_within = *{package_skill::_is_within}{CODE};
    
    *package_skill::_is_within = sub {
        my ($path_obj, $root) = @_;
        if ($path_obj =~ /script\.py$/) {
            return 0;  # Simulate rejection
        }
        return $orig_is_within->($path_obj, $root);
    };
    
    my $result = package_skill::package_skill($skill_dir, $out_dir);
    ok(!defined $result, "Result should be undefined when path is rejected");
    
    # Restore original function
    *package_skill::_is_within = $orig_is_within;
    
    $self->tearDown();
}

sub test_allows_nested_regular_files {
    my $self = shift;
    $self->setUp();
    
    my $skill_dir = create_skill($self, "nested-skill");
    my $nested = File::Spec->catdir($skill_dir, "lib", "helpers");
    mkpath($nested) unless -d $nested;
    
    my $util_py = File::Spec->catfile($nested, "util.py");
    open my $fh, '>', $util_py or die "Cannot write to $util_py: $!";
    print $fh "def run():\n    return 1\n";
    close $fh;
    
    my $out_dir = File::Spec->catdir($self->{temp_dir}, "out");
    mkdir $out_dir unless -d $out_dir;
    
    my $result = package_skill::package_skill($skill_dir, $out_dir);
    ok(defined $result, "Result should be defined");
    
    my $skill_file = File::Spec->catfile($out_dir, "nested-skill.skill");
    
    my @names = list_zip_contents($skill_file);
    my %name_set = map { $_ => 1 } @names;
    
    ok(exists $name_set{"nested-skill/lib/helpers/util.py"}, "Should contain util.py");
    
    $self->tearDown();
}

sub test_skips_output_archive_when_output_dir_is_skill_dir {
    my $self = shift;
    $self->setUp();
    
    my $skill_dir = create_skill($self, "self-output-skill");
    
    my $result = package_skill::package_skill($skill_dir, $skill_dir);
    ok(defined $result, "Result should be defined");
    
    my $skill_file = File::Spec->catfile($skill_dir, "self-output-skill.skill");
    ok(-f $skill_file, "Skill file should exist");
    
    my @names = list_zip_contents($skill_file);
    my %name_set = map { $_ => 1 } @names;
    
    ok(exists $name_set{"self-output-skill/SKILL.md"}, "Should contain SKILL.md");
    ok(exists $name_set{"self-output-skill/script.py"}, "Should contain script.py");
    ok(!exists $name_set{"self-output-skill/self-output-skill.skill"}, "Should NOT contain itself");
    
    $self->tearDown();
}

sub list_zip_contents {
    my ($zip_file) = @_;
    open my $fh, '-|', "unzip", "-Z1", $zip_file or die "Cannot read zip: $!";
    my @contents;
    while (my $line = <$fh>) {
        chomp $line;
        push @contents, $line;
    }
    close $fh;
    return @contents;
}

# Run tests
plan tests => 7;

test_packages_normal_files(bless {}, 'Test');
test_skips_symlink_to_external_file(bless {}, 'Test');
test_skips_symlink_directory(bless {}, 'Test');
test_rejects_resolved_path_outside_skill_root(bless {}, 'Test');
test_allows_nested_regular_files(bless {}, 'Test');
test_skips_output_archive_when_output_dir_is_skill_dir(bless {}, 'Test');
