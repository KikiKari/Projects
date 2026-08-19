#!/usr/bin/perl
# quick_validate.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/skill-creator/scripts/quick_validate.py
# auch in: OpenClaw@gateway2:skills/skill-creator/scripts/quick_validate.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;

# Quick validation script for skills - minimal version

my $MAX_SKILL_NAME_LENGTH = 64;

sub _extract_frontmatter {
    my ($content) = @_;
    my @lines = split /\n/, $content;
    return undef unless @lines && $lines[0] =~ /^\s*---\s*$/;
    for my $i (1 .. $#lines) {
        if ($lines[$i] =~ /^\s*---\s*$/) {
            return join("\n", @lines[1 .. $i - 1]);
        }
    }
    return undef;
}

sub _parse_simple_frontmatter {
    my ($frontmatter_text) = @_;
    my %parsed;
    my $current_key;
    for my $raw_line (split /\n/, $frontmatter_text) {
        my $stripped = $raw_line;
        $stripped =~ s/^\s+|\s+$//g;
        next if !$stripped || $stripped =~ /^#/;
        
        my $is_indented = $raw_line =~ /^\s/;
        if ($is_indented) {
            return undef unless defined $current_key;
            my $current_value = $parsed{$current_key};
            $parsed{$current_key} = defined $current_value ? "$current_value\n$stripped" : $stripped;
            next;
        }
        
        return undef unless $stripped =~ /:/;
        my ($key, $value) = split /:/, $stripped, 2;
        $key =~ s/^\s+|\s+$//g;
        $value =~ s/^\s+|\s+$//g;
        return undef unless $key;
        if (($value =~ /^".*"$/ || $value =~ /^'.*'$/) && length($value) >= 2) {
            $value = substr($value, 1, length($value) - 2);
        }
        $parsed{$key} = $value;
        $current_key = $key;
    }
    return \%parsed;
}

sub validate_skill {
    my ($skill_path) = @_;
    
    my $skill_md = File::Spec->catfile($skill_path, "SKILL.md");
    return (0, "SKILL.md not found") unless -e $skill_md;
    
    my $content;
    {
        open my $fh, '<:encoding(UTF-8)', $skill_md or return (0, "Could not read SKILL.md: $!");
        local $/;
        $content = <$fh>;
        close $fh;
    }
    
    my $frontmatter_text = _extract_frontmatter($content);
    return (0, "Invalid frontmatter format") unless defined $frontmatter_text;
    
    my $frontmatter = _parse_simple_frontmatter($frontmatter_text);
    return (0, "Invalid YAML in frontmatter: unsupported syntax without PyYAML installed") unless defined $frontmatter;
    
    my %allowed_properties = map { $_ => 1 } qw(name description license allowed-tools metadata);
    my @unexpected_keys = grep { !$allowed_properties{$_} } keys %$frontmatter;
    if (@unexpected_keys) {
        my @allowed = sort keys %allowed_properties;
        my @unexpected = sort @unexpected_keys;
        return (0, "Unexpected key(s) in SKILL.md frontmatter: " . join(", ", @unexpected) . 
                ". Allowed properties are: " . join(", ", @allowed));
    }
    
    return (0, "Missing 'name' in frontmatter") unless exists $frontmatter->{name};
    return (0, "Missing 'description' in frontmatter") unless exists $frontmatter->{description};
    
    my $name = $frontmatter->{name};
    return (0, "Name must be a string, got " . ref($name)) if ref($name);
    $name =~ s/^\s+|\s+$//g;
    if ($name) {
        if ($name !~ /^[a-z0-9-]+$/) {
            return (0, "Name '$name' should be hyphen-case (lowercase letters, digits, and hyphens only)");
        }
        if ($name =~ /^-/ || $name =~ /-$/ || $name =~ /--/) {
            return (0, "Name '$name' cannot start/end with hyphen or contain consecutive hyphens");
        }
        if (length($name) > $MAX_SKILL_NAME_LENGTH) {
            return (0, "Name is too long (" . length($name) . " characters). " .
                    "Maximum is $MAX_SKILL_NAME_LENGTH characters.");
        }
    }
    
    my $description = $frontmatter->{description};
    return (0, "Description must be a string, got " . ref($description)) if ref($description);
    $description =~ s/^\s+|\s+$//g;
    if ($description) {
        if ($description =~ /[<>]/) {
            return (0, "Description cannot contain angle brackets (< or >)");
        }
        if (length($description) > 1024) {
            return (0, "Description is too long (" . length($description) . " characters). Maximum is 1024 characters.");
        }
    }
    
    return (1, "Skill is valid!");
}

if (@ARGV != 1) {
    print "Usage: perl quick_validate.pl <skill_directory>\n";
    exit 1;
}

my ($valid, $message) = validate_skill($ARGV[0]);
print "$message\n";
exit $valid ? 0 : 1;
