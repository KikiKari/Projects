#!/usr/bin/env perl
# package_skill.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/package_skill.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/package_skill.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use File::Find;
use File::Spec;
use File::Basename;
use Cwd 'abs_path';
use lib '.';
use quick_validate qw(validate_skill);

# Skill Packager - Creates a distributable .skill file of a skill folder
#
# Usage:
#     perl utils/package_skill.pl <path/to/skill-folder> [output-directory]
#
# Example:
#     perl utils/package_skill.pl skills/public/my-skill
#     perl utils/package_skill.pl skills/public/my-skill ./dist

sub _is_within {
    my ($path, $root) = @_;
    eval {
        my @path_parts = split '/', $path;
        my @root_parts = split '/', $root;
        for my $i (0 .. $#root_parts) {
            return 0 if $path_parts[$i] ne $root_parts[$i];
        }
        return 1;
    };
    return !$@;
}

sub package_skill {
    my ($skill_path, $output_dir) = @_;
    
    # Resolve paths
    $skill_path = abs_path($skill_path);
    
    # Validate skill folder exists
    if (!-e $skill_path) {
        print "[ERROR] Skill folder not found: $skill_path\n";
        return undef;
    }
    
    if (!-d $skill_path) {
        print "[ERROR] Path is not a directory: $skill_path\n";
        return undef;
    }
    
    # Validate SKILL.md exists
    my $skill_md = File::Spec->catfile($skill_path, "SKILL.md");
    if (!-e $skill_md) {
        print "[ERROR] SKILL.md not found in $skill_path\n";
        return undef;
    }
    
    # Run validation before packaging
    print "Validating skill...\n";
    my ($valid, $message) = validate_skill($skill_path);
    if (!$valid) {
        print "[ERROR] Validation failed: $message\n";
        print "   Please fix the validation errors before packaging.\n";
        return undef;
    }
    print "[OK] $message\n\n";
    
    # Determine output location
    my $skill_name = basename($skill_path);
    my $output_path;
    if ($output_dir) {
        $output_path = abs_path($output_dir);
        system("mkdir -p '$output_path'") == 0 or die "Failed to create output directory: $!";
    } else {
        $output_path = cwd();
    }
    
    my $skill_filename = File::Spec->catfile($output_path, "$skill_name.skill");
    
    my %EXCLUDED_DIRS = map { $_ => 1 } (".git", ".svn", ".hg", "__pycache__", "node_modules");
    
    # Create the .skill file (zip format)
    eval {
        # Collect files to add
        my @files_to_add;
        
        find(sub {
            return if $_ eq '.' || $_ eq '..';
            
            my $file_path = $File::Find::name;
            
            # Security: never follow or package symlinks.
            if (-l $file_path) {
                print "[WARN] Skipping symlink: $file_path\n";
                return;
            }
            
            my @rel_parts = split('/', File::Spec->abs2rel($file_path, $skill_path));
            my $skip = 0;
            for my $part (@rel_parts) {
                if ($EXCLUDED_DIRS{$part}) {
                    $skip = 1;
                    last;
                }
            }
            return if $skip;
            
            if (-f $file_path) {
                my $resolved_file = abs_path($file_path);
                if (!_is_within($resolved_file, $skill_path)) {
                    die "[ERROR] File escapes skill root: $file_path\n";
                }
                
                # If output lives under skill_path, avoid writing archive into itself.
                if ($resolved_file eq abs_path($skill_filename)) {
                    print "[WARN] Skipping output archive: $file_path\n";
                    return;
                }
                
                push @files_to_add, $file_path;
            }
        }, $skill_path);
        
        # Build zip command
        my $cmd = "zip -j '$skill_filename' ";
        for my $file (@files_to_add) {
            my $rel_path = File::Spec->abs2rel($file, $skill_path);
            my $arcname = File::Spec->catfile($skill_name, $rel_path);
            $cmd .= "'$file' ";
            print "  Added: $arcname\n";
        }
        
        system("$cmd >/dev/null 2>&1") == 0 or die "Failed to create zip file";
        
        print "\n[OK] Successfully packaged skill to: $skill_filename\n";
        return $skill_filename;
    };
    
    if ($@) {
        print "[ERROR] Error creating .skill file: $@\n";
        return undef;
    }
}

sub main {
    if (@ARGV < 1) {
        print "Usage: perl utils/package_skill.pl <path/to/skill-folder> [output-directory]\n";
        print "\nExample:\n";
        print "  perl utils/package_skill.pl skills/public/my-skill\n";
        print "  perl utils/package_skill.pl skills/public/my-skill ./dist\n";
        exit 1;
    }
    
    my $skill_path = $ARGV[0];
    my $output_dir = $ARGV[1] if @ARGV > 1;
    
    print "Packaging skill: $skill_path\n";
    if ($output_dir) {
        print "   Output directory: $output_dir\n";
    }
    print "\n";
    
    my $result = package_skill($skill_path, $output_dir);
    
    if ($result) {
        exit 0;
    } else {
        exit 1;
    }
}

main() if !caller;
