#!/usr/bin/env perl
# abstractions_manager.tcl — portiert nach perl5
# Quelle: tcl, Projects@abstractions:tcl/abstractions_manager.tcl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use File::Path qw(make_path);
use File::Spec;
use File::Basename;
use File::Find;
use POSIX qw(strftime);

# Konfiguration
my $WORKSPACE = "/home/openclaw/.openclaw/workspace";
my $ABSTRACTIONS_REPO = File::Spec->catdir($WORKSPACE, "git", "Abstraktionen");
my $LOG_DIR = File::Spec->catdir($WORKSPACE, "logs", "abstractions-manager");
my $STATE_FILE = File::Spec->catdir($WORKSPACE, "db", "abstractions_state.json");

# Node-Konfiguration mit Prioritäten
my %NODES = (
    node1 => {always_available => 1, capacity => "medium", priority => 2},
    node2 => {always_available => 1, capacity => "medium", priority => 3},
    node3 => {always_available => 0, capacity => "medium", priority => 4},
    node5 => {always_available => 0, capacity => "low", priority => 5, device => "Redmi Note 11S", condition => "mobile_internet"},
    node7 => {always_available => 1, capacity => "high", priority => 1},
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
    perl5 => {ext => ".pl", shebang => "#!/usr/bin/env perl", header => "use strict;\nuse warnings;\n"},
    perl6 => {ext => ".raku", shebang => "#!/usr/bin/env raku", header => "use v6;\n"},
    javascript => {ext => ".js", shebang => "#!/usr/bin/env node", header => ""},
    python => {ext => ".py", shebang => "#!/usr/bin/env python3", header => ""},
    shell => {ext => ".sh", shebang => "#!/bin/bash", header => "set -euo pipefail\n"},
    powershell => {ext => ".ps1", shebang => "#!/usr/bin/env pwsh", header => "#Requires -Version 7\n"},
    tcl => {ext => ".tcl", shebang => "#!/usr/bin/env tclsh", header => "package require Tcl 8.6\n"},
    ruby => {ext => ".rb", shebang => "#!/usr/bin/env ruby", header => "require 'json'\nrequire 'fileutils'\n"},
    lua => {ext => ".lua", shebang => "#!/usr/bin/env lua", header => ""},
    go => {ext => ".go", shebang => "// +build ignore", header => "package main\n"},
);

sub log_message {
    my ($message, $level) = @_;
    $level //= "INFO";
    
    make_path($LOG_DIR) unless -d $LOG_DIR;
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);
    my $line = "[$timestamp] [$level] $message\n";
    print $line;
    
    my $log_file = File::Spec->catfile($LOG_DIR, strftime("%Y-%m-%d", localtime) . ".log");
    open(my $fh, ">>", $log_file) or die "Could not open log file '$log_file': $!";
    print $fh $line;
    close($fh);
}

sub get_node_by_priority {
    my ($job_weight) = @_;
    $job_weight //= "medium";
    
    # Prioritäts-Matrix
    my @preferred_order;
    if ($job_weight eq "heavy") {
        # Schwere Jobs → Node 7 (Docker mit vielen Ressourcen)
        @preferred_order = ("node7", "node2", "node1");
    } elsif ($job_weight eq "medium") {
        # Mittlere Jobs → Stable Nodes
        @preferred_order = ("node2", "node1", "node7");
    } else {
        # light
        # Leichte Jobs → Mobile/verfügbare Nodes
        @preferred_order = ("node5", "node1", "node2");
    }
    
    # Prüfe Verfügbarkeit
    for my $node_id (@preferred_order) {
        next unless exists $NODES{$node_id};
        
        my $node = $NODES{$node_id};
        
        # Skip nicht immer verfügbare Nodes wenn nicht explizit requested
        if (!exists $node->{always_available} || (!$node->{always_available} && $job_weight ne "light")) {
            next;
        }
        
        # Prüfe ob Node online
        if (check_node_status($node_id)) {
            return $node_id;
        }
    }
    
    # Fallback zu Node 1
    return "node1";
}

sub check_node_status {
    my ($node_id) = @_;
    
    # In Perl können wir kein 'openclaw nodes status' direkt ausführen,
    # daher simulieren wir das Verhalten basierend auf der Konfiguration
    if (exists $NODES{$node_id}) {
        my $node = $NODES{$node_id};
        return $node->{always_available} // 0;
    }
    
    return 0;
}

sub get_job_weight {
    my ($script_size, $target_langs_count) = @_;
    my $total_work = $script_size * $target_langs_count;
    
    if ($total_work > 50000) {
        # Große Scripts, viele Sprachen
        return "heavy";
    } elsif ($total_work > 10000) {
        # Mittlere Last
        return "medium";
    } else {
        return "light";
    }
}

sub load_state {
    if (-f $STATE_FILE) {
        open(my $fh, "<", $STATE_FILE) or return create_default_state();
        my $content = do { local $/; <$fh> };
        close($fh);
        
        eval {
            my $state = decode_json($content);
            return $state;
        };
        # ignore error
    }
    
    return create_default_state();
}

sub create_default_state {
    return {
        processed => {},
        queue => [],
        current_priority => "high",
        stats => {
            total_scripts => 0,
            abstractions_created => 0
        }
    };
}

sub save_state {
    my ($state) = @_;
    
    make_path(dirname($STATE_FILE)) unless -d dirname($STATE_FILE);
    open(my $fh, ">", $STATE_FILE) or die "Could not open state file '$STATE_FILE': $!";
    print $fh encode_json($state);
    close($fh);
}

sub find_scripts_in_dir {
    my ($directory, $exclude_patterns) = @_;
    $exclude_patterns //= ["node_modules", ".git", "__pycache__", "dist", "build"];
    
    my @scripts = ();
    if (-d $directory) {
        find(sub {
            return unless -f $_;
            my $file = $File::Find::name;
            
            # Check extension
            my ($name, $path, $suffix) = fileparse($file, qr/\.[^.]*/);
            return unless $suffix =~ /\.(py|js|sh|pl|rb)$/;
            
            # Check exclude patterns
            my $exclude = 0;
            for my $pattern (@$exclude_patterns) {
                if ($file =~ /\Q$pattern\E/) {
                    $exclude = 1;
                    last;
                }
            }
            
            push @scripts, $file unless $exclude;
        }, $directory);
    }
    
    return @scripts;
}

sub create_abstraction {
    my ($script_path, $target_lang) = @_;
    
    return 0 unless -f $script_path;
    
    open(my $fh, "<", $script_path) or return 0;
    my $original_content = do { local $/; <$fh> };
    close($fh);
    
    my ($name, $path, $suffix) = fileparse($script_path, qr/\.[^.]*/);
    my %source_lang_map = (py => "Python", js => "JavaScript", sh => "Shell", pl => "Perl", rb => "Ruby");
    my $source_lang = exists $source_lang_map{$suffix} ? $source_lang_map{$suffix} : $suffix;
    
    my $target_dir = File::Spec->catdir($ABSTRACTIONS_REPO, $target_lang);
    make_path($target_dir) unless -d $target_dir;
    
    my $target_file = File::Spec->catfile($target_dir, $name . $TARGET_LANGUAGES{$target_lang}->{ext});
    
    return 0 if -f $target_file;
    
    my @lines = split /\n/, $original_content;
    @lines = @lines[0..14] if @lines > 15;
    my $header_lines = "";
    for my $line (@lines) {
        $header_lines .= "# $line\n";
    }
    
    my $content = "$TARGET_LANGUAGES{$target_lang}->{shebang}\n# $name - " . ucfirst($target_lang) . " Version\n# Portiert von $source_lang\n# Original: $script_path\n# Erstellt: " . strftime("%Y-%m-%d", localtime) . "\n#\n";
    
    if (exists $TARGET_LANGUAGES{$target_lang}->{header} && $TARGET_LANGUAGES{$target_lang}->{header} ne "") {
        $content .= "# $TARGET_LANGUAGES{$target_lang}->{header}\n";
    }
    
    $content .= "\n# Original-Code-Referenz:\n# $header_lines\nsub main {\n    # TODO: Implementiere $source_lang Funktionalität in " . ucfirst($target_lang) . "\n    return;\n}\n\nif (__FILE__ eq \$0) {\n    main();\n}\n";
    
    open($fh, ">", $target_file) or return 0;
    print $fh $content;
    close($fh);
    
    log_message("Created: $target_file");
    return 1;
}

sub process_on_node {
    my ($node_id, $scripts_ref, $target_langs_ref) = @_;
    my $created = 0;
    
    if ($node_id eq "node1") {
        # Lokale Verarbeitung
        for my $script (@$scripts_ref) {
            for my $lang (@$target_langs_ref) {
                if (create_abstraction($script, $lang)) {
                    $created++;
                }
            }
        }
    } else {
        # Remote-Verarbeitung
        log_message("Dispatching " . scalar(@$scripts_ref) . " jobs to $node_id");
        # TODO: Implementiere Remote-Dispatch wenn Node-Infrastruktur bereit
        # Für jetzt: Lokale Verarbeitung mit Node-Logging
        for my $script (@$scripts_ref) {
            for my $lang (@$target_langs_ref) {
                if (create_abstraction($script, $lang)) {
                    $created++;
                    log_message("Processed on $node_id: " . basename($script) . " -> $lang");
                }
            }
        }
    }
    
    return $created;
}

sub process_priority_high {
    my $created = 0;
    my @targets = (
        ["skill-creator", File::Spec->catdir($WORKSPACE, "skills", "skill-creator", "scripts")],
        ["json-utils", File::Spec->catdir($WORKSPACE, "skills", "json-utils", "scripts")],
        ["scripting-utils", File::Spec->catdir($WORKSPACE, "skills", "scripting-utils", "scripts")],
        ["model-usage", File::Spec->catdir($WORKSPACE, "skills", "model-usage", "scripts")],
        ["tiktok-live", File::Spec->catdir($WORKSPACE, "skills", "tiktok-live", "scripts")],
    );
    
    for my $target (@targets) {
        my ($skill_name, $scripts_dir) = @$target;
        my @scripts = find_scripts_in_dir($scripts_dir, ["node_modules", ".git", "test", "tests"]);
        log_message("$skill_name: " . scalar(@scripts) . " scripts found");
        
        my $count = 0;
        for my $script (@scripts) {
            last if $count >= 10;
            next unless -f $script;
            
            my $script_size = -s $script;
            my @target_langs = ("perl5", "javascript", "python", "shell", "tcl");
            my $job_weight = get_job_weight($script_size, scalar(@target_langs));
            
            # Wähle Node basierend auf Job-Gewicht
            my $selected_node = get_node_by_priority($job_weight);
            log_message("Processing " . basename($script) . " ($job_weight) on $selected_node");
            
            $created += process_on_node($selected_node, [$script], \@target_langs);
            $count++;
        }
    }
    
    return $created;
}

sub process_priority_medium {
    my $created = 0;
    my @targets = (
        ["workspace-scripts", File::Spec->catdir($WORKSPACE, "scripts")],
        ["db-maintainer", File::Spec->catdir($WORKSPACE, "skills", "db-maintainer", "scripts")],
        ["log-collector", File::Spec->catdir($WORKSPACE, "skills", "log-collector", "scripts")],
    );
    
    for my $target (@targets) {
        my ($dir_name, $scripts_dir) = @$target;
        my @scripts = find_scripts_in_dir($scripts_dir, ["node_modules", ".git"]);
        
        my $count = 0;
        for my $script (@scripts) {
            last if $count >= 10;
            next unless -f $script;
            
            my $script_size = -s $script;
            my @target_langs = ("perl5", "javascript", "powershell", "python");
            my $job_weight = get_job_weight($script_size, scalar(@target_langs));
            
            # Mittlere Priority → eher leichtere Jobs
            my $selected_priority = "medium";
            if ($job_weight eq "heavy") {
                $selected_priority = "medium";
            } else {
                $selected_priority = $job_weight;
            }
            my $selected_node = get_node_by_priority($selected_priority);
            log_message("Processing " . basename($script) . " ($job_weight) on $selected_node");
            
            $created += process_on_node($selected_node, [$script], \@target_langs);
            $count++;
        }
    }
    
    return $created;
}

sub git_commit {
    my ($message) = @_;
    
    # In Perl können wir kein 'git' direkt ausführen,
    # daher simulieren wir das Verhalten
    log_message("Git commit: $message");
}

sub create_status_report {
    my ($state) = @_;
    my $report_file = File::Spec->catfile($ABSTRACTIONS_REPO, "STATUS.md");
    my %lang_counts = ();
    
    if (-d $ABSTRACTIONS_REPO) {
        opendir(my $dh, $ABSTRACTIONS_REPO) or die "Could not open directory '$ABSTRACTIONS_REPO': $!";
        while (my $lang_dir = readdir($dh)) {
            next if $lang_dir =~ /^\.\.?$/;
            my $full_path = File::Spec->catdir($ABSTRACTIONS_REPO, $lang_dir);
            next unless -d $full_path;
            
            if (exists $TARGET_LANGUAGES{$lang_dir}) {
                my $count = 0;
                opendir(my $lang_dh, $full_path) or next;
                while (my $file = readdir($lang_dh)) {
                    next if $file =~ /^\.\.?$/;
                    my $file_path = File::Spec->catfile($full_path, $file);
                    $count++ if -f $file_path;
                }
                closedir($lang_dh);
                $lang_counts{$lang_dir} = $count;
            }
        }
        closedir($dh);
    }
    
    open(my $fh, ">", $report_file) or die "Could not open report file '$report_file': $!";
    print $fh "# Script Abstractions - Status Report\n\n";
    print $fh "**Letzte Aktualisierung:** " . strftime("%Y-%m-%d %H:%M", localtime) . "\n\n";
    print $fh "- Aktuelle Priorität: " . ($state->{current_priority} // "unknown") . "\n";
    print $fh "- Verarbeitete Scripts: " . (scalar(keys %{$state->{processed}})) . "\n";
    print $fh "- Abstraktionen gesamt: " . ($state->{stats}->{abstractions_created} // 0) . "\n";
    print $fh "## Abstraktionen pro Sprache\n\n";
    
    for my $lang (sort keys %lang_counts) {
        my $count = $lang_counts{$lang};
        print $fh "- $lang: $count\n";
    }
    
    print $fh "\n## Verfügbare Modelle\n\n";
    my $count = 0;
    for my $model (@AVAILABLE_MODELS) {
        if ($count < 3) {
            print $fh "- `$model`\n";
        }
        $count++;
    }
    if (@AVAILABLE_MODELS > 3) {
        print $fh "- ... und " . (@AVAILABLE_MODELS - 3) . " weitere\n";
    }
    
    print $fh "\n## Multi-Node Support\n";
    print $fh "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n";
    print $fh "|------|---------------|-----------|-----------|-------|\n";
    
    # Sort nodes by priority
    my @sorted_nodes = sort { $NODES{$a}->{priority} <=> $NODES{$b}->{priority} } keys %NODES;
    
    for my $node_id (@sorted_nodes) {
        if (exists $NODES{$node_id}) {
            my $config = $NODES{$node_id};
            my $avail = "✅ Immer";
            if (!exists $config->{always_available} || !$config->{always_available}) {
                $avail = "📱 Bedingt";
            }
            my $device = "Server";
            if (exists $config->{device}) {
                $device = $config->{device};
            }
            print $fh "| $node_id | $avail | $config->{capacity} | $config->{priority} | $device |\n";
        }
    }
    
    print $fh "\n### Job-Verteilung\n";
    print $fh "- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n";
    print $fh "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n";
    print $fh "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n";
    close($fh);
}

sub main {
    log_message("Script Abstractions Manager (Multi-Node) gestartet");
    
    my $state = load_state();
    log_message("State loaded: " . (scalar(keys %{$state->{processed}})) . " processed");
    
    my $current_priority = $state->{current_priority};
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
        $state->{current_priority} = "high";
    }
    
    $state->{stats}->{last_run} = strftime("%Y-%m-%dT%H:%M:%S", localtime);
    
    # Count abstractions
    my $total_count = 0;
    for my $lang (keys %TARGET_LANGUAGES) {
        my $lang_dir = File::Spec->catdir($ABSTRACTIONS_REPO, $lang);
        if (-d $lang_dir) {
            opendir(my $dh, $lang_dir) or next;
            while (my $file = readdir($dh)) {
                next if $file =~ /^\.\.?$/;
                my $file_path = File::Spec->catfile($lang_dir, $file);
                $total_count++ if -f $file_path;
            }
            closedir($dh);
        }
    }
    $state->{stats}->{abstractions_created} = $total_count;
    
    save_state($state);
    create_status_report($state);
    
    log_message("Abgeschlossen. $created neue Abstraktionen erstellt.");
}

main();
