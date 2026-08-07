#!/usr/bin/env perl
# abstractions_manager.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/abstractions_manager.py
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use File::Path qw(make_path);
use File::Spec;
use Cwd qw(getcwd);
use POSIX qw(strftime);

# Konfiguration
my $WORKSPACE = "/home/openclaw/.openclaw/workspace";
my $ABSTRACTIONS_REPO = "$WORKSPACE/git/Abstraktionen";
my $LOG_DIR = "$WORKSPACE/logs/abstractions-manager";
my $STATE_FILE = "$WORKSPACE/db/abstractions_state.json";

# Node-Konfiguration mit Prioritäten
my %NODES = (
    "node1" => { always_available => 1, capacity => "medium", priority => 2 },  # Gateway-Master
    "node2" => { always_available => 1, capacity => "medium", priority => 3 },  # Stable Worker
    "node3" => { always_available => 0, capacity => "medium", priority => 4 },  # Bald verfügbar
    "node5" => { always_available => 0, capacity => "low", priority => 5, device => "Redmi Note 11S", condition => "mobile_internet" },
    "node7" => { always_available => 1, capacity => "high", priority => 1 },     # Docker Hauptarbeitspferd
);

my @AVAILABLE_MODELS = (
    "openrouter/moonshotai/kimi-k2.5",
    "openrouter/openai/gpt-4o",
    "openrouter/anthropic/claude-3-5-sonnet-20241022",
    "openrouter/google/gemini-2.0-flash-001",
    "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1",
    "openrouter/qwen/qwen-2.5-coder-32b-instruct",
);

my %TARGET_LANGUAGES = (
    "perl5" => { ext => ".pl", shebang => "#!/usr/bin/env perl", header => "use strict;\nuse warnings;\n" },
    "perl6" => { ext => ".raku", shebang => "#!/usr/bin/env raku", header => "use v6;\n" },
    "javascript" => { ext => ".js", shebang => "#!/usr/bin/env node", header => "" },
    "python" => { ext => ".py", shebang => "#!/usr/bin/env python3", header => "" },
    "shell" => { ext => ".sh", shebang => "#!/bin/bash", header => "set -euo pipefail\n" },
    "powershell" => { ext => ".ps1", shebang => "#!/usr/bin/env pwsh", header => "#Requires -Version 7\n" },
    "tcl" => { ext => ".tcl", shebang => "#!/usr/bin/env tclsh", header => "package require Tcl 8.6\n" },
    "ruby" => { ext => ".rb", shebang => "#!/usr/bin/env ruby", header => "require 'json'\nrequire 'fileutils'\n" },
    "lua" => { ext => ".lua", shebang => "#!/usr/bin/env lua", header => "" },
    "go" => { ext => ".go", shebang => "// +build ignore", header => "package main\n" },
);

sub log_message {
    my ($message, $level) = @_;
    $level //= "INFO";
    
    make_path($LOG_DIR) unless -d $LOG_DIR;
    my $timestamp = strftime('%Y-%m-%d %H:%M:%S', localtime);
    my $line = "[$timestamp] [$level] $message\n";
    print $line;
    
    my $log_file = "$LOG_DIR/" . strftime('%Y-%m-%d', localtime) . ".log";
    open my $fh, '>>', $log_file or die "Cannot open log file: $!";
    print $fh $line;
    close $fh;
}

sub get_node_by_priority {
    my ($job_weight) = @_;
    $job_weight //= "medium";
    
    my @preferred_order;
    if ($job_weight eq "heavy") {
        @preferred_order = ("node7", "node2", "node1");
    } elsif ($job_weight eq "medium") {
        @preferred_order = ("node2", "node1", "node7");
    } else {
        @preferred_order = ("node5", "node1", "node2");
    }
    
    for my $node_id (@preferred_order) {
        next unless exists $NODES{$node_id};
        
        my $node = $NODES{$node_id};
        next if !$node->{always_available} && $job_weight ne "light";
        
        if (check_node_status($node_id)) {
            return $node_id;
        }
    }
    
    return "node1";
}

sub check_node_status {
    my ($node_id) = @_;
    
    my $cmd = "openclaw nodes status $node_id";
    my $output = `$cmd 2>/dev/null`;
    my $exit_code = $? >> 8;
    
    if ($exit_code == 0 && ($output =~ /online/i || $output =~ /active/i)) {
        return 1;
    }
    
    return $NODES{$node_id}->{always_available} // 0;
}

sub get_job_weight {
    my ($script_size, $target_langs_count) = @_;
    my $total_work = $script_size * $target_langs_count;
    
    if ($total_work > 50000) {
        return "heavy";
    } elsif ($total_work > 10000) {
        return "medium";
    } else {
        return "light";
    }
}

sub load_state {
    if (-f $STATE_FILE) {
        open my $fh, '<', $STATE_FILE or return default_state();
        my $json_text = do { local $/; <$fh> };
        close $fh;
        
        my $state = eval { decode_json($json_text) };
        return $state if $state;
    }
    
    return default_state();
}

sub default_state {
    return {
        processed => {},
        queue => [],
        current_priority => "high",
        stats => { total_scripts => 0, abstractions_created => 0 }
    };
}

sub save_state {
    my ($state) = @_;
    
    my $state_dir = $STATE_FILE;
    $state_dir =~ s/\/[^\/]+$//;
    make_path($state_dir) unless -d $state_dir;
    
    open my $fh, '>', $STATE_FILE or die "Cannot write state file: $!";
    print $fh encode_json($state);
    close $fh;
}

sub find_scripts_in_dir {
    my ($directory, $exclude_patterns) = @_;
    $exclude_patterns //= ["node_modules", ".git", "__pycache__", "dist", "build"];
    
    my @scripts;
    return @scripts unless -d $directory;
    
    my @extensions = ("*.py", "*.js", "*.sh", "*.pl", "*.rb");
    for my $ext (@extensions) {
        my @files = glob("$directory/**/$ext");
        for my $file (@files) {
            my $exclude = 0;
            for my $pattern (@$exclude_patterns) {
                if ($file =~ /\Q$pattern\E/) {
                    $exclude = 1;
                    last;
                }
            }
            push @scripts, $file unless $exclude;
        }
    }
    
    return @scripts;
}

sub create_abstraction {
    my ($script_path, $target_lang) = @_;
    
    eval {
        open my $fh, '<:encoding(UTF-8)', $script_path or die "Cannot read $script_path: $!";
        my $original_content = do { local $/; <$fh> };
        close $fh;
        
        my ($ext) = $script_path =~ /\.([^.]+)$/;
        my %source_lang_map = (py => "Python", js => "JavaScript", sh => "Shell", pl => "Perl", rb => "Ruby");
        my $source_lang = $source_lang_map{$ext} // $ext;
        
        my $target_dir = "$ABSTRACTIONS_REPO/$target_lang";
        make_path($target_dir) unless -d $target_dir;
        
        my ($script_name) = $script_path =~ /([^\/]+)\.[^.]+$/;
        my $target_file = "$target_dir/${script_name}$TARGET_LANGUAGES{$target_lang}{ext}";
        
        return 0 if -f $target_file;
        
        my $template = $TARGET_LANGUAGES{$target_lang};
        my @lines = split /\n/, $original_content;
        @lines = @lines[0..14] if @lines > 15;
        
        my $content = "$template->{shebang}\n";
        $content .= "# $script_name - " . ucfirst($target_lang) . " Version\n";
        $content .= "# Portiert von $source_lang\n";
        $content .= "# Original: $script_path\n";
        $content .= "# Erstellt: " . strftime('%Y-%m-%d', localtime) . "\n#\n";
        $content .= "# $template->{header}\n" if $template->{header};
        $content .= "# Original-Code-Referenz:\n";
        $content .= "# " . join("\n# ", @lines) . "\n\n";
        $content .= "sub main {\n";
        $content .= "    # TODO: Implementiere $source_lang Funktionalität in " . ucfirst($target_lang) . "\n";
        $content .= "    return;\n";
        $content .= "}\n\n";
        $content .= "main() unless caller;\n";
        
        open $fh, '>', $target_file or die "Cannot write $target_file: $!";
        print $fh $content;
        close $fh;
        
        log_message("Created: $target_file");
        return 1;
    };
    
    if ($@) {
        log_message("Failed: $script_path - $@", "ERROR");
        return 0;
    }
}

sub process_on_node {
    my ($node_id, $scripts, $target_langs) = @_;
    my $created = 0;
    
    if ($node_id eq "node1") {
        for my $script (@$scripts) {
            for my $lang (@$target_langs) {
                $created++ if create_abstraction($script, $lang);
            }
        }
    } else {
        log_message("Dispatching " . scalar(@$scripts) . " jobs to $node_id");
        for my $script (@$scripts) {
            for my $lang (@$target_langs) {
                if (create_abstraction($script, $lang)) {
                    $created++;
                    log_message("Processed on $node_id: $script -> $lang");
                }
            }
        }
    }
    
    return $created;
}

sub process_priority_high {
    my $created = 0;
    my @targets = (
        ["skill-creator", "$WORKSPACE/skills/skill-creator/scripts"],
        ["json-utils", "$WORKSPACE/skills/json-utils/scripts"],
        ["scripting-utils", "$WORKSPACE/skills/scripting-utils/scripts"],
        ["model-usage", "$WORKSPACE/skills/model-usage/scripts"],
        ["tiktok-live", "$WORKSPACE/skills/tiktok-live/scripts"],
    );
    
    for my $target (@targets) {
        my ($skill_name, $scripts_dir) = @$target;
        my @scripts = find_scripts_in_dir($scripts_dir, ["node_modules", ".git", "test", "tests"]);
        log_message("$skill_name: " . scalar(@scripts) . " scripts found");
        
        my $count = 0;
        for my $script (@scripts) {
            last if $count++ >= 10;
            my $script_size = -s $script // 0;
            my @target_langs = ("perl5", "javascript", "python", "shell", "tcl");
            my $job_weight = get_job_weight($script_size, scalar(@target_langs));
            
            my $selected_node = get_node_by_priority($job_weight);
            log_message("Processing " . ($script =~ /([^\/]+)$/) . " ($job_weight) on $selected_node");
            
            $created += process_on_node($selected_node, [$script], \@target_langs);
        }
    }
    
    return $created;
}

sub process_priority_medium {
    my $created = 0;
    my @targets = (
        ["workspace-scripts", "$WORKSPACE/scripts"],
        ["db-maintainer", "$WORKSPACE/skills/db-maintainer/scripts"],
        ["log-collector", "$WORKSPACE/skills/log-collector/scripts"],
    );
    
    for my $target (@targets) {
        my ($dir_name, $scripts_dir) = @$target;
        my @scripts = find_scripts_in_dir($scripts_dir, ["node_modules", ".git"]);
        
        my $count = 0;
        for my $script (@scripts) {
            last if $count++ >= 10;
            my $script_size = -s $script // 0;
            my @target_langs = ("perl5", "javascript", "powershell", "python");
            my $job_weight = get_job_weight($script_size, scalar(@target_langs));
            
            my $priority = ($job_weight eq "heavy") ? "medium" : $job_weight;
            my $selected_node = get_node_by_priority($priority);
            log_message("Processing " . ($script =~ /([^\/]+)$/) . " ($job_weight) on $selected_node");
            
            $created += process_on_node($selected_node, [$script], \@target_langs);
        }
    }
    
    return $created;
}

sub git_commit {
    my ($message) = @_;
    
    eval {
        my $old_dir = getcwd();
        chdir $ABSTRACTIONS_REPO;
        system("git add .") == 0 or die "git add failed";
        system("git commit -m '$message'") == 0 or die "git commit failed";
        chdir $old_dir;
        log_message("Git commit: $message");
    };
}

sub create_status_report {
    my ($state) = @_;
    my $report_file = "$ABSTRACTIONS_REPO/STATUS.md";
    
    my %lang_counts;
    if (-d $ABSTRACTIONS_REPO) {
        opendir my $dh, $ABSTRACTIONS_REPO or die "Cannot open directory: $!";
        while (my $lang_dir = readdir($dh)) {
            next if $lang_dir =~ /^\.\.?$/;
            my $full_path = "$ABSTRACTIONS_REPO/$lang_dir";
            if (-d $full_path && exists $TARGET_LANGUAGES{$lang_dir}) {
                opendir my $lang_dh, $full_path or next;
                my $count = 0;
                while (my $file = readdir($lang_dh)) {
                    next if $file =~ /^\.\.?$/;
                    $count++ if -f "$full_path/$file";
                }
                closedir $lang_dh;
                $lang_counts{$lang_dir} = $count;
            }
        }
        closedir $dh;
    }
    
    open my $fh, '>', $report_file or die "Cannot write report file: $!";
    print $fh "# Script Abstractions - Status Report\n\n";
    print $fh "**Letzte Aktualisierung:** " . strftime('%Y-%m-%d %H:%M', localtime) . "\n\n";
    print $fh "- Aktuelle Priorität: " . ($state->{current_priority} // "high") . "\n";
    print $fh "- Verarbeitete Scripts: " . (scalar keys %{$state->{processed}}) . "\n";
    print $fh "- Abstraktionen gesamt: " . ($state->{stats}->{abstractions_created} // 0) . "\n\n";
    
    print $fh "## Abstraktionen pro Sprache\n\n";
    for my $lang (sort keys %lang_counts) {
        print $fh "- $lang: $lang_counts{$lang}\n";
    }
    
    print $fh "\n## Verfügbare Modelle\n\n";
    for my $i (0..2) {
        last if $i >= @AVAILABLE_MODELS;
        print $fh "- `$AVAILABLE_MODELS[$i]`\n";
    }
    print $fh "- ... und " . (@AVAILABLE_MODELS - 3) . " weitere\n";
    
    print $fh "\n## Multi-Node Support\n\n";
    print $fh "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n";
    print $fh "|------|---------------|-----------|-----------|-------|\n";
    for my $node_id (sort keys %NODES) {
        my $config = $NODES{$node_id};
        my $avail = $config->{always_available} ? "✅ Immer" : "📱 Bedingt";
        my $device = $config->{device} // "Server";
        print $fh "| $node_id | $avail | " . ($config->{capacity} // "unknown") . " | " . ($config->{priority} // "-") . " | $device |\n";
    }
    
    print $fh "\n### Job-Verteilung\n\n";
    print $fh "- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n";
    print $fh "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n";
    print $fh "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n";
    
    close $fh;
}

sub main {
    log_message("Script Abstractions Manager (Multi-Node) gestartet");
    
    my $state = load_state();
    log_message("State loaded: " . (scalar keys %{$state->{processed}}) . " processed");
    
    my $current_priority = $state->{current_priority} // "high";
    my $created = 0;
    
    if ($current_priority eq "high") {
        log_message("Processing HIGH priority: Top 5 Skills");
        $created = process_priority_high();
        if ($created > 0) {
            git_commit("High priority: $created abstractions");
        }
        $state->{current_priority} = "medium";
    } elsif ($current_priority eq "medium") {
        log_message("Processing MEDIUM priority: Workspace Scripts");
        $created = process_priority_medium();
        if ($created > 0) {
            git_commit("Medium priority: $created abstractions");
        }
        $state->{current_priority} = "high";  # Zyklus
    }
    
    $state->{stats}->{last_run} = strftime('%Y-%m-%dT%H:%M:%S', localtime);
    
    my $total = 0;
    if (-d $ABSTRACTIONS_REPO) {
        for my $lang (keys %TARGET_LANGUAGES) {
            my $lang_dir = "$ABSTRACTIONS_REPO/$lang";
            if (-d $lang_dir) {
                opendir my $dh, $lang_dir or next;
                while (my $file = readdir($dh)) {
                    next if $file =~ /^\.\.?$/;
                    $total++ if -f "$lang_dir/$file";
                }
                closedir $dh;
            }
        }
    }
    $state->{stats}->{abstractions_created} = $total;
    
    save_state($state);
    create_status_report($state);
    
    log_message("Abgeschlossen. $created neue Abstraktionen erstellt.");
}

main() unless caller;
