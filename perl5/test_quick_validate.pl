#!/usr/bin/env perl
# test_quick_validate.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/test_quick_validate.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/test_quick_validate.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Temp qw(tempdir);
use File::Path qw(rmtree);
use File::Spec;
use lib '.';
use quick_validate;

use Test::More;

# Emulate Python's TestCase class with simple subroutines
package TestCase;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub assertTrue {
    my ($self, $condition, $message) = @_;
    ok($condition, $message // 'Assertion failed');
}

sub assertFalse {
    my ($self, $condition) = @_;
    ok(!$condition, 'Expected false condition');
}

sub assertEqual {
    my ($self, $first, $second) = @_;
    is($first, $second, 'Values should be equal');
}

# Main test package
package main;

my $test_case = TestCase->new();

# Set up temporary directory
my $temp_dir = tempdir("test_quick_validate_XXXXXX", CLEANUP => 0);

# Ensure cleanup on exit
END {
    if (-d $temp_dir) {
        rmtree($temp_dir);
    }
}

sub test_accepts_crlf_frontmatter {
    my $skill_dir = File::Spec->catdir($temp_dir, "crlf-skill");
    mkdir $skill_dir unless -d $skill_dir;
    
    my $content = "---\r\nname: crlf-skill\r\ndescription: ok\r\n---\r\n# Skill\r\n";
    my $file_path = File::Spec->catfile($skill_dir, "SKILL.md");
    
    open(my $fh, '>:encoding(UTF-8)', $file_path) or die "Could not open file '$file_path': $!";
    print $fh $content;
    close $fh;
    
    my ($valid, $message) = quick_validate::validate_skill($skill_dir);
    
    $test_case->assertTrue($valid, $message);
}

sub test_rejects_missing_frontmatter_closing_fence {
    my $skill_dir = File::Spec->catdir($temp_dir, "bad-skill");
    mkdir $skill_dir unless -d $skill_dir;
    
    my $content = "---\nname: bad-skill\ndescription: missing end\n# no closing fence\n";
    my $file_path = File::Spec->catfile($skill_dir, "SKILL.md");
    
    open(my $fh, '>:encoding(UTF-8)', $file_path) or die "Could not open file '$file_path': $!";
    print $fh $content;
    close $fh;
    
    my ($valid, $message) = quick_validate::validate_skill($skill_dir);
    
    $test_case->assertFalse($valid);
    $test_case->assertEqual($message, "Invalid frontmatter format");
}

sub test_fallback_parser_handles_multiline_frontmatter_without_pyyaml {
    my $skill_dir = File::Spec->catdir($temp_dir, "multiline-skill");
    mkdir $skill_dir unless -d $skill_dir;
    
    my $content = <<'EOF';
---
name: multiline-skill
description: Works without pyyaml
allowed-tools:
  - gh
metadata: |
  {
    "owners": ["team-openclaw"]
  }
---
# Skill
EOF
    
    my $file_path = File::Spec->catfile($skill_dir, "SKILL.md");
    
    open(my $fh, '>:encoding(UTF-8)', $file_path) or die "Could not open file '$file_path': $!";
    print $fh $content;
    close $fh;
    
    # Save original yaml value and set to undef to simulate missing pyyaml
    my $previous_yaml = $quick_validate::yaml;
    $quick_validate::yaml = undef;
    
    my ($valid, $message) = quick_validate::validate_skill($skill_dir);
    
    # Restore original yaml value
    $quick_validate::yaml = $previous_yaml;
    
    $test_case->assertTrue($valid, $message);
}

# Run all tests
test_accepts_crlf_frontmatter();
test_rejects_missing_frontmatter_closing_fence();
test_fallback_parser_handles_multiline_frontmatter_without_pyyaml();

done_testing();
