#!/usr/bin/perl
# language_validator.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use Getopt::Long;
use File::Spec;
use File::Basename;
use IPC::Run3;
use Time::HiRes qw(alarm);
use Data::Dumper;

# Multi-language script validator supporting 8+ languages.
# WebSearch integration for documentation lookup.

# ValidationResult class equivalent
package ValidationResult {
    sub new {
        my ($class, $language, $valid, $errors, $warnings, $doc_url) = @_;
        my $self = {
            language => $language,
            valid => $valid,
            errors => $errors || [],
            warnings => $warnings || [],
            doc_url => $doc_url
        };
        bless $self, $class;
        return $self;
    }
}

# LanguageValidator class equivalent
package LanguageValidator {
    our %LANGUAGES = (
        "bash" => { cmd => "bash", args => ["-n"], linter => "shellcheck" },
        "sh" => { cmd => "sh", args => ["-n"], linter => "shellcheck" },
        "python" => { cmd => "python3", args => ["-m", "py_compile"], linter => "pylint" },
        "perl" => { cmd => "perl", args => ["-c"], linter => "perlcritic" },
        "raku" => { cmd => "raku", args => ["-c"], linter => undef },
        "powershell" => { cmd => "pwsh", args => ["-Command", "Get-Command"], linter => undef },
        "javascript" => { cmd => "node", args => ["--check"], linter => "eslint" },
        "tcl" => { cmd => "tclsh", args => [], linter => undef },
    );
    
    sub new {
        my ($class, $language, $use_websearch) = @_;
        my $self = {
            language => lc($language),
            use_websearch => $use_websearch // 1,
            config => undef
        };
        bless $self, $class;
        
        $self->{config} = $LANGUAGES{$self->{language}};
        if (!$self->{config}) {
            die "Unsupported language: $language\n";
        }
        
        return $self;
    }
    
    sub validate {
        my ($self, $script_path) = @_;
        my @errors = ();
        my @warnings = ();
        
        # Syntax check
        eval {
            local $SIG{ALRM} = sub { die "timeout\n" };
            alarm(30);
            
            my @cmd = ($self->{config}->{cmd}, @{$self->{config}->{args}}, $script_path);
            my ($stdout, $stderr, $exit);
            
            run3(\@cmd, undef, \$stdout, \$stderr);
            $exit = $? >> 8;
            
            alarm(0);
            
            if ($exit != 0) {
                push @errors, $stderr || "Command failed with exit code $exit";
            }
        };
        
        if ($@) {
            if ($@ eq "timeout\n") {
                push @errors, "Validation timeout";
            } elsif ($@ =~ /Cannot exec/) {
                push @errors, "Command not found: " . $self->{config}->{cmd};
                if ($self->{use_websearch}) {
                    my $doc_url = $self->_fetch_docs();
                    return ValidationResult->new($self->{language}, 0, \@errors, \@warnings, $doc_url);
                }
            } else {
                push @errors, $@;
            }
        }
        
        # Linter check if available
        if ($self->{config}->{linter}) {
            my $linter_warnings = $self->_run_linter($script_path);
            push @warnings, @$linter_warnings;
        }
        
        return ValidationResult->new($self->{language}, scalar(@errors) == 0, \@errors, \@warnings);
    }
    
    sub _run_linter {
        my ($self, $script_path) = @_;
        my $linter = $self->{config}->{linter};
        my @warnings = ();
        
        eval {
            if ($linter eq "shellcheck") {
                my ($stdout, $stderr);
                run3(["shellcheck", "-f", "gcc", $script_path], undef, \$stdout, \$stderr);
                if ($stdout) {
                    @warnings = split /\n/, $stdout;
                    chomp @warnings;
                }
            } elsif ($linter eq "pylint") {
                my ($stdout, $stderr);
                run3(["pylint", "--output-format=parseable", $script_path], undef, \$stdout, \$stderr);
                if ($stdout) {
                    @warnings = split /\n/, $stdout;
                    chomp @warnings;
                }
            }
        };
        
        if ($@ && $@ =~ /Cannot exec/) {
            push @warnings, "Linter not installed: $linter";
        }
        
        return \@warnings;
    }
    
    sub _fetch_docs {
        my ($self) = @_;
        return undef unless $self->{use_websearch};
        
        my %docs = (
            "powershell" => "https://docs.microsoft.com/powershell/",
            "raku" => "https://docs.raku.org/",
            "tcl" => "https://www.tcl.tk/",
        );
        
        return $docs{$self->{language}};
    }
}

# Main program
package main {
    my $script_path;
    my $language;
    my $no_websearch = 0;
    
    GetOptions(
        "lang=s" => \$language,
        "no-websearch" => \$no_websearch,
    ) or die "Invalid options\n";
    
    if (!$language) {
        die "Language is required (--lang)\n";
    }
    
    $script_path = $ARGV[0] or die "Script path is required\n";
    
    if (!-f $script_path) {
        die "Script file not found: $script_path\n";
    }
    
    my $validator = LanguageValidator->new($language, !$no_websearch);
    my $result = $validator->validate($script_path);
    
    print "Language: " . $result->{language} . "\n";
    print "Valid: " . ($result->{valid} ? "True" : "False") . "\n";
    
    if (@{$result->{errors}}) {
        my $count = scalar(@{$result->{errors}});
        print "Errors: $count\n";
        my $limit = $count > 5 ? 5 : $count;
        for my $i (0..$limit-1) {
            print "  - " . $result->{errors}[$i] . "\n";
        }
    }
    
    if (@{$result->{warnings}}) {
        my $count = scalar(@{$result->{warnings}});
        print "Warnings: $count\n";
        my $limit = $count > 5 ? 5 : $count;
        for my $i (0..$limit-1) {
            print "  - " . $result->{warnings}[$i] . "\n";
        }
    }
    
    if ($result->{doc_url}) {
        print "Docs: " . $result->{doc_url} . "\n";
    }
    
    exit($result->{valid} ? 0 : 1);
}
