#!/usr/bin/env perl
# ABSTRACTIONS_MANAGER.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:abstraction-manager/ABSTRACTIONS_MANAGER.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use autodie;
use JSON::PP;
use File::Path qw(make_path);
use File::Copy qw(move);
use File::Temp qw(tempfile);
use File::Find;
use Fcntl qw(:DEFAULT :flock);
use POSIX qw(strftime);
use IPC::Run3 qw(run3);
use Cwd qw(abs_path);

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

my $WORKSPACE = "/home/openclaw/.openclaw/workspace";
my $ABSTRACTIONS_REPO = "$WORKSPACE/git/Abstraktionen";
my $LOG_DIR = "$WORKSPACE/logs/abstractions-manager";
my $STATE_FILE = "$WORKSPACE/db/abstractions_state.json";

my %NODES = (
    "node1" => { always_available => 1,  capacity => "medium", priority => 2 },
    "node2" => { always_available => 1,  capacity => "medium", priority => 3 },
    "node3" => { always_available => 0,  capacity => "medium", priority => 4 },
    "node5" => { always_available => 0,  capacity => "low",    priority => 5,
                 device => "Redmi Note 11S", condition => "mobile_internet" },
    "node7" => { always_available => 1,  capacity => "high",   priority => 1 },
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
    "perl5" => {
        ext => ".pl",
        shebang => "#!/usr/bin/env perl",
        header => "use strict;\nuse warnings;\n",
        main_block => (
            "sub main {{\n"
            . "    # TODO: Implementiere {source_lang} Funktionalität in Perl 5\n"
            . "}}\n\n"
            . "main();\n"
        ),
    },
    "perl6" => {
        ext => ".raku",
        shebang => "#!/usr/bin/env raku",
        header => "use v6;\n",
        main_block => (
            "sub MAIN() {{\n"
            . "    # TODO: Implementiere {source_lang} Funktionalität in Raku\n"
            . "}}\n"
        ),
    },
    "javascript" => {
        ext => ".js",
        shebang => "#!/usr/bin/env node",
        header => "'use strict';\n",
        main_block => (
            "function main() {{\n"
            . "    // TODO: Implementiere {source_lang} Funktionalität in JavaScript\n"
            . "}}\n\n"
            . "main();\n"
        ),
    },
    "python" => {
        ext => ".py",
        shebang => "#!/usr/bin/env python3",
        header => "",
        main_block => (
            "def main():\n"
            . "    # TODO: Implementiere {source_lang} Funktionalität in Python\n"
            . "    pass\n\n\n"
            . "if __name__ == '__main__':\n"
            . "    main()\n"
        ),
    },
    "shell" => {
        ext => ".sh",
        shebang => "#!/bin/bash",
        header => "set -euo pipefail\n",
        main_block => (
            "main() {{\n"
            . "    # TODO: Implementiere {source_lang} Funktionalität in Bash\n"
            . "}}\n\n"
            . "main \"\$@\"\n"
        ),
    },
    "powershell" => {
        ext => ".ps1",
        shebang => "#!/usr/bin/env pwsh",
        header => "#Requires -Version 7\n",
        main_block => (
            "function Main {{\n"
            . "    # TODO: Implementiere {source_lang} Funktionalität in PowerShell\n"
            . "}}\n\n"
            . "Main\n"
        ),
    },
    "tcl" => {
        ext => ".tcl",
        shebang => "#!/usr/bin/env tclsh",
        header => "package require Tcl 8.6\n",
        main_block => (
            "proc main {{}} {{\n"
            . "    # TODO: Implementiere {source_lang} Funktionalität in Tcl\n"
            . "}}\n\n"
            . "main\n"
        ),
    },
    "ruby" => {
        ext => ".rb",
        shebang => "#!/usr/bin/env ruby",
        header => "# frozen_string_literal: true\nrequire 'json'\nrequire 'fileutils'\n",
        main_block => (
            "def main\n"
            . "  # TODO: Implementiere {source_lang} Funktionalität in Ruby\n"
            . "end\n\n"
            . "main if __FILE__ == \$PROGRAM_NAME\n"
        ),
    },
    "lua" => {
        ext => ".lua",
        shebang => "#!/usr/bin/env lua",
        header => "",
        main_block => (
            "local function main()\n"
            . "    -- TODO: Implementiere {source_lang} Funktionalität in Lua\n"
            . "end\n\n"
            . "main()\n"
        ),
    },
    "go" => {
        ext => ".go",
        shebang => "// +build ignore",
        header => "package main\n\nimport \"fmt\"\n",
        main_block => (
            "func main() {{\n"
            . "    // TODO: Implementiere {source_lang} Funktionalität in Go\n"
            . "    _ = fmt.Println\n"
            . "}}\n"
        ),
    },
);

# ---------------------------------------------------------------------------
# Logging-Setup
# ---------------------------------------------------------------------------

sub _setup_logger {
    make_path($LOG_DIR) unless -d $LOG_DIR;
    my $log_level_name = $ENV{ABSTRACTIONS_LOG_LEVEL} || "INFO";
    my $log_level = uc($log_level_name) eq "DEBUG" ? 1 : 
                   uc($log_level_name) eq "INFO" ? 2 : 
                   uc($log_level_name) eq "WARNING" ? 3 : 4;
    return $log_level;
}

my $log_level = _setup_logger();

sub log_message {
    my ($level, $message) = @_;
    my %levels = (DEBUG => 1, INFO => 2, WARNING => 3, ERROR => 4);
    return if $levels{$level} < $log_level;
    
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);
    my $log_line = "$timestamp | $level     | main:" . (caller)[2] . " | $message\n";
    
    print STDERR $log_line;
    
    my $log_file = "$LOG_DIR/" . strftime("%Y-%m-%d", localtime) . ".log";
    open my $fh, ">>:encoding(UTF-8)", $log_file;
    print $fh $log_line;
    close $fh;
}

# ---------------------------------------------------------------------------
# State-Management
# ---------------------------------------------------------------------------

sub load_state {
    my %default_state = (
        processed => {},
        queue => [],
        current_priority => "high",
        stats => { total_scripts => 0, abstractions_created => 0 },
    );

    return \%default_state unless -f $STATE_FILE;

    eval {
        open my $fh, "<:encoding(UTF-8)", $STATE_FILE;
        my $json_text = do { local $/; <$fh> };
        close $fh;
        return decode_json($json_text);
    };
    if ($@) {
        log_message("ERROR", "State-File konnte nicht geparst werden ($STATE_FILE): $@");
        return \%default_state;
    }
}

sub save_state {
    my ($state) = @_;
    
    eval {
        make_path(dirname($STATE_FILE)) unless -d dirname($STATE_FILE);
        
        my ($fh, $tmp_path) = tempfile(
            DIR => dirname($STATE_FILE),
            SUFFIX => ".tmp",
            UNLINK => 0
        );
        print $fh encode_json($state);
        close $fh;
        
        move($tmp_path, $STATE_FILE);
        log_message("DEBUG", "State atomar gespeichert: $STATE_FILE");
    };
    if ($@) {
        log_message("ERROR", "State konnte nicht gespeichert werden: $@");
        unlink($tmp_path) if defined $tmp_path && -e $tmp_path;
    }
}

# ---------------------------------------------------------------------------
# Node-Management
# ---------------------------------------------------------------------------

sub check_node_status {
    my ($node_id) = @_;
    
    eval {
        my @cmd = ("openclaw", "nodes", "status", $node_id);
        my ($stdout, $stderr);
        run3(\@cmd, \undef, \$stdout, \$stderr);
        
        if ($? == -1) {
            die "failed to execute: $!";
        } elsif ($? & 127) {
            die "child died with signal " . ($? & 127);
        } else {
            my $exit_code = $? >> 8;
            my $stdout_lower = lc($stdout);
            return ($exit_code == 0 && ($stdout_lower =~ /online/ || $stdout_lower =~ /active/));
        }
    };
    if ($@) {
        if ($@ =~ /timeout/i) {
            log_message("WARNING", "Timeout beim Status-Check von $node_id — verwende always_available");
        } elsif ($@ =~ /No such file or directory/) {
            log_message("WARNING", "'openclaw'-Binary nicht gefunden — verwende always_available für $node_id");
        } else {
            log_message("WARNING", "OSError beim Status-Check von $node_id: $@ — verwende always_available");
        }
        return $NODES{$node_id}{always_available} // 0;
    }
}

sub get_job_weight {
    my ($script_size, $target_langs_count) = @_;
    my $total_work = $script_size * $target_langs_count;
    return "heavy" if $total_work > 50000;
    return "medium" if $total_work > 10000;
    return "light";
}

sub get_node_by_priority {
    my ($job_weight) = @_;
    $job_weight //= "medium";
    
    my %weight_to_preference = (
        heavy => ["node7", "node2", "node1"],
        medium => ["node2", "node1", "node7"],
        light => ["node5", "node1", "node2"],
    );
    
    my $preferred_order = $weight_to_preference{$job_weight} || ["node1", "node2"];
    
    for my $node_id (@$preferred_order) {
        next unless exists $NODES{$node_id};
        my $node_cfg = $NODES{$node_id};
        next if !$node_cfg->{always_available} && $job_weight ne "light";
        if (check_node_status($node_id)) {
            log_message("DEBUG", "Node $node_id ausgewählt für ${job_weight}-Job");
            return $node_id;
        }
    }
    
    log_message("WARNING", "Kein passender Node gefunden für Gewicht '$job_weight' — Fallback node1");
    return "node1";
}

# ---------------------------------------------------------------------------
# Script-Verarbeitung
# ---------------------------------------------------------------------------

sub find_scripts_in_dir {
    my ($directory, $exclude_patterns) = @_;
    $exclude_patterns //= ["node_modules", ".git", "__pycache__", "dist", "build"];
    
    my @scripts;
    return \@scripts unless -d $directory;
    
    my @glob_patterns = ("*.py", "*.js", "*.sh", "*.pl", "*.rb");
    for my $pattern (@glob_patterns) {
        find(sub {
            return unless -f $_ && $_ =~ /\Q$pattern\E$/;
            my $full_path = $File::Find::name;
            return if grep { index($full_path, $_) != -1 } @$exclude_patterns;
            push @scripts, $full_path;
        }, $directory);
    }
    
    return \@scripts;
}

sub _build_stub_content {
    my ($script_path, $target_lang, $source_lang, $template) = @_;
    
    my $today = strftime("%Y-%m-%d", localtime);
    
    my @original_lines;
    eval {
        open my $fh, "<:encoding(UTF-8)", $script_path;
        @original_lines = map { chomp; $_ } (split /\n/, <$fh>)[0..14];
        close $fh;
    };
    if ($@) {
        log_message("WARNING", "Originaldatei konnte nicht gelesen werden: $@");
        @original_lines = ();
    }
    
    my $comment_char = ($target_lang eq "go" || $target_lang eq "javascript") ? "//" : "#";
    my $original_preview = join("\n", map { "$comment_char $_" } @original_lines);
    
    my $main_block = $template->{main_block};
    $main_block =~ s/\{source_lang\}/$source_lang/g;
    
    return join("\n",
        $template->{shebang},
        "$comment_char " . (fileparse($script_path))[0] . " - " . ucfirst($target_lang) . " Version",
        "$comment_char Portiert von $source_lang",
        "$comment_char Original: $script_path",
        "$comment_char Erstellt: $today",
        "",
        $template->{header},
        "$comment_char Original-Code-Referenz:",
        $original_preview,
        "",
        $main_block
    );
}

sub create_abstraction {
    my ($script_path, $target_lang) = @_;
    
    unless (exists $TARGET_LANGUAGES{$target_lang}) {
        log_message("ERROR", "Unbekannte Zielsprache: $target_lang");
        return 0;
    }
    
    my $template = $TARGET_LANGUAGES{$target_lang};
    my %ext_map = (py => "Python", js => "JavaScript", sh => "Shell", pl => "Perl", rb => "Ruby");
    my $source_lang = $ext_map{(fileparse($script_path))[2]} || ucfirst((fileparse($script_path))[2]);
    
    my $target_dir = "$ABSTRACTIONS_REPO/$target_lang";
    eval { make_path($target_dir) };
    if ($@) {
        log_message("ERROR", "Zielverzeichnis konnte nicht erstellt werden ($target_dir): $@");
        return 0;
    }
    
    my $target_file = "$target_dir/" . (fileparse($script_path))[0] . $template->{ext};
    if (-f $target_file) {
        log_message("DEBUG", "Bereits vorhanden, übersprungen: $target_file");
        return 0;
    }
    
    my $content = _build_stub_content($script_path, $target_lang, $source_lang, $template);
    
    eval {
        my ($fh, $tmp_path) = tempfile(
            DIR => $target_dir,
            SUFFIX => $template->{ext},
            UNLINK => 0
        );
        print $fh $content;
        close $fh;
        move($tmp_path, $target_file);
        log_message("INFO", "Erstellt: $target_file");
        return 1;
    };
    if ($@) {
        log_message("ERROR", "Stub konnte nicht geschrieben werden ($target_file): $@");
        unlink($tmp_path) if defined $tmp_path && -e $tmp_path;
        return 0;
    }
}

sub process_on_node {
    my ($node_id, $scripts, $target_langs) = @_;
    my $created = 0;
    
    if ($node_id eq "node1") {
        for my $script_path (@$scripts) {
            for my $lang (@$target_langs) {
                $created++ if create_abstraction($script_path, $lang);
            }
        }
    } else {
        log_message("INFO", "Dispatching " . scalar(@$scripts) . " Jobs an $node_id (lokaler Fallback aktiv)");
        for my $script_path (@$scripts) {
            for my $lang (@$target_langs) {
                if (create_abstraction($script_path, $lang)) {
                    $created++;
                    log_message("DEBUG", "Verarbeitet auf $node_id: " . (fileparse($script_path))[0] . " → $lang");
                }
            }
        }
    }
    
    return $created;
}

# ---------------------------------------------------------------------------
# Prioritäts-Verarbeitung
# ---------------------------------------------------------------------------

sub process_priority_high {
    my @target_dirs = (
        ["skill-creator",   "$WORKSPACE/skills/skill-creator/scripts"],
        ["json-utils",      "$WORKSPACE/skills/json-utils/scripts"],
        ["scripting-utils", "$WORKSPACE/skills/scripting-utils/scripts"],
        ["model-usage",     "$WORKSPACE/skills/model-usage/scripts"],
        ["tiktok-live",     "$WORKSPACE/skills/tiktok-live/scripts"],
    );
    my @target_langs = ("perl5", "javascript", "python", "shell", "tcl");
    my $created = 0;
    my @exclude = ("node_modules", ".git", "test", "tests");
    
    for my $dir_info (@target_dirs) {
        my ($skill_name, $scripts_dir) = @$dir_info;
        my $scripts = find_scripts_in_dir($scripts_dir, \@exclude);
        log_message("INFO", "$skill_name: " . scalar(@$scripts) . " Scripts gefunden");
        
        for my $script_path (@$scripts[0..9]) {
            my $script_size = -f $script_path ? (stat($script_path))[7] : 0;
            my $job_weight = get_job_weight($script_size, scalar(@target_langs));
            my $selected_node = get_node_by_priority($job_weight);
            log_message("INFO", "Verarbeite " . (fileparse($script_path))[0] . " ($job_weight) auf $selected_node");
            $created += process_on_node($selected_node, [$script_path], \@target_langs);
        }
    }
    
    return $created;
}

sub process_priority_medium {
    my @target_dirs = (
        ["workspace-scripts", "$WORKSPACE/scripts"],
        ["db-maintainer",     "$WORKSPACE/skills/db-maintainer/scripts"],
        ["log-collector",     "$WORKSPACE/skills/log-collector/scripts"],
    );
    my @target_langs = ("perl5", "javascript", "powershell", "python");
    my $created = 0;
    my @exclude = ("node_modules", ".git");
    
    for my $dir_info (@target_dirs) {
        my ($dir_name, $scripts_dir) = @$dir_info;
        my $scripts = find_scripts_in_dir($scripts_dir, \@exclude);
        
        for my $script_path (@$scripts[0..9]) {
            my $script_size = -f $script_path ? (stat($script_path))[7] : 0;
            my $job_weight = get_job_weight($script_size, scalar(@target_langs));
            my $effective_weight = $job_weight eq "heavy" ? "medium" : $job_weight;
            my $selected_node = get_node_by_priority($effective_weight);
            log_message("INFO", "Verarbeite " . (fileparse($script_path))[0] . " ($job_weight) auf $selected_node");
            $created += process_on_node($selected_node, [$script_path], \@target_langs);
        }
    }
    
    return $created;
}

# ---------------------------------------------------------------------------
# Git-Integration
# ---------------------------------------------------------------------------

sub git_commit {
    my ($message) = @_;
    my $repo_str = $ABSTRACTIONS_REPO;
    
    eval {
        run3(["git", "-C", $repo_str, "add", "."], \undef, \my $stdout, \my $stderr);
        die "git add failed: $stderr" if $? != 0;
        
        run3(["git", "-C", $repo_str, "commit", "-m", $message], \undef, \my $stdout2, \my $stderr2);
        die "git commit failed: $stderr2" if $? != 0;
        
        log_message("INFO", "Git commit erfolgreich: $message");
    };
    if ($@) {
        if ($@ =~ /No such file or directory/) {
            log_message("ERROR", "'git'-Binary nicht gefunden — Commit übersprungen");
        } else {
            log_message("WARNING", "Git-Befehl fehlgeschlagen: $@");
        }
    }
}

# ---------------------------------------------------------------------------
# Status-Report
# ---------------------------------------------------------------------------

sub create_status_report {
    my ($state) = @_;
    
    unless (-d $ABSTRACTIONS_REPO) {
        log_message("WARNING", "Abstractions-Repo existiert nicht: $ABSTRACTIONS_REPO");
        return;
    }
    
    my %lang_counts;
    opendir(my $dh, $ABSTRACTIONS_REPO) or die "Cannot open directory: $!";
    my @lang_dirs = grep { -d "$ABSTRACTIONS_REPO/$_" && exists $TARGET_LANGUAGES{$_} } readdir($dh);
    closedir($dh);
    
    for my $lang_dir (@lang_dirs) {
        opendir(my $ldh, "$ABSTRACTIONS_REPO/$lang_dir") or next;
        my @files = grep { -f "$ABSTRACTIONS_REPO/$lang_dir/$_" } readdir($ldh);
        closedir($ldh);
        $lang_counts{$lang_dir} = scalar @files;
    }
    
    my $report_file = "$ABSTRACTIONS_REPO/STATUS.md";
    eval {
        open my $fh, ">:encoding(UTF-8)", $report_file;
        print $fh "# Script Abstractions - Status Report\n\n";
        print $fh "**Letzte Aktualisierung:** " . strftime("%Y-%m-%d %H:%M", localtime) . "\n\n";
        print $fh "- Aktuelle Priorität: " . ($state->{current_priority} || "high") . "\n";
        print $fh "- Verarbeitete Scripts: " . (scalar keys %{$state->{processed} || {}}) . "\n";
        print $fh "- Abstraktionen gesamt: " . ($state->{stats}{abstractions_created} || 0) . "\n\n";
        
        print $fh "## Abstraktionen pro Sprache\n\n";
        for my $lang (sort keys %lang_counts) {
            print $fh "- $lang: $lang_counts{$lang}\n";
        }
        
        print $fh "\n## Verfügbare Modelle\n\n";
        for my $model (@AVAILABLE_MODELS[0..2]) {
            print $fh "- `$model`\n";
        }
        print $fh "- ... und " . (scalar(@AVAILABLE_MODELS) - 3) . " weitere\n";
        
        print $fh "\n## Multi-Node Support\n\n";
        print $fh "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n";
        print $fh "|------|---------------|-----------|-----------|-------|\n";
        for my $node_id (sort keys %NODES) {
            my $cfg = $NODES{$node_id};
            my $avail = $cfg->{always_available} ? "✅ Immer" : "📱 Bedingt";
            my $device = $cfg->{device} || "Server";
            print $fh "| $node_id | $avail | " . ($cfg->{capacity} || "unknown") . " | " . ($cfg->{priority} || "-") . " | $device |\n";
        }
        
        print $fh "\n### Job-Verteilung\n\n";
        print $fh "- **Heavy Jobs** (>50 KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n";
        print $fh "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n";
        print $fh "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n";
        
        close $fh;
        log_message("INFO", "Status-Report erstellt: $report_file");
    };
    if ($@) {
        log_message("ERROR", "Status-Report konnte nicht geschrieben werden: $@");
    }
}

# ---------------------------------------------------------------------------
# Einstiegspunkt
# ---------------------------------------------------------------------------

sub main {
    log_message("INFO", "Script Abstractions Manager (Multi-Node) gestartet");
    
    my $state = load_state();
    log_message("INFO", "State geladen: " . (scalar keys %{$state->{processed} || {}}) . " bereits verarbeitet");
    
    my $current_priority = $state->{current_priority} || "high";
    my $created = 0;
    
    if ($current_priority eq "high") {
        log_message("INFO", "Verarbeite HIGH-Priorität: Top 5 Skills");
        $created = process_priority_high();
        if ($created > 0) {
            git_commit("High priority: $created abstractions");
        }
        $state->{current_priority} = "medium";
    } elsif ($current_priority eq "medium") {
        log_message("INFO", "Verarbeite MEDIUM-Priorität: Workspace Scripts");
        $created = process_priority_medium();
        if ($created > 0) {
            git_commit("Medium priority: $created abstractions");
        }
        $state->{current_priority} = "high";  # Zyklus zurücksetzen
    }
    
    $state->{stats}{last_run} = strftime("%Y-%m-%dT%H:%M:%S", localtime);
    
    my $total_count = 0;
    for my $lang (keys %TARGET_LANGUAGES) {
        if (-d "$ABSTRACTIONS_REPO/$lang") {
            opendir(my $dh, "$ABSTRACTIONS_REPO/$lang") or next;
            my @files = grep { -f "$ABSTRACTIONS_REPO/$lang/$_" } readdir($dh);
            closedir($dh);
            $total_count += scalar @files;
        }
    }
    $state->{stats}{abstractions_created} = $total_count;
    
    save_state($state);
    create_status_report($state);
    
    log_message("INFO", "Abgeschlossen. $created neue Abstraktionen erstellt.");
}

sub fileparse {
    my ($path) = @_;
    my ($name, $dir, $ext) = ($path =~ m{^(.*)/([^/]+?)((?:\.[^.]+)*)$});
    $dir //= "";
    $ext =~ s/^\.//;
    return ($name, $dir, $ext);
}

sub dirname {
    my ($path) = @_;
    return ($path =~ m{^(.+)/[^/]*$})[0] // ".";
}

main() if !caller;
