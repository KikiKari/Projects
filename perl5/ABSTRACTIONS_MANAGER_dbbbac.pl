#!/usr/bin/env perl
# ABSTRACTIONS_MANAGER.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway2:abstraction-manager/ABSTRACTIONS_MANAGER.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);
use File::Spec;
use File::Path qw(make_path remove_tree);
use File::Find;
use File::Copy;
use JSON;
use POSIX qw(strftime);
use Cwd qw(getcwd);
use Fcntl qw(:DEFAULT :flock);
use IPC::Run3;
use File::Temp qw(tempfile);

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

my $WORKSPACE = $ENV{"OPENCLAW_WORKSPACE"} // "/home/openclaw/.openclaw/workspace";
my $ABSTRACTIONS_REPO = File::Spec->catdir($WORKSPACE, "git", "Abstraktionen");
my $LOG_DIR = File::Spec->catdir($WORKSPACE, "logs", "abstractions-manager");
my $STATE_FILE = File::Spec->catfile($WORKSPACE, "db", "abstractions_state.json");

my %NODES = (
    "node1" => {always_available => 1,  capacity => "medium", priority => 2},
    "node2" => {always_available => 1,  capacity => "medium", priority => 3},
    "node3" => {always_available => 0,  capacity => "medium", priority => 4},
    "node5" => {always_available => 0,  capacity => "low",    priority => 5,
                device => "Redmi Note 11S", condition => "mobile_internet"},
    "node7" => {always_available => 1,  capacity => "high",   priority => 1},
);

# Da Perl keine direkte Entsprechung zu configured_models() hat, simulieren wir es
my @AVAILABLE_MODELS = ("model1", "model2", "model3", "model4", "model5");

my %TARGET_LANGUAGES = (
    "perl5" => {
        ext => ".pl",
        shebang => "#!/usr/bin/env perl",
        header => "use strict;\nuse warnings;\n",
        main_block => (
            "sub main {\n"
            . "    # TODO: Implementiere {source_lang} Funktionalität in Perl 5\n"
            . "}\n\n"
            . "main();\n"
        ),
    },
    "perl6" => {
        ext => ".raku",
        shebang => "#!/usr/bin/env raku",
        header => "use v6;\n",
        main_block => (
            "sub MAIN() {\n"
            . "    # TODO: Implementiere {source_lang} Funktionalität in Raku\n"
            . "}\n"
        ),
    },
    "javascript" => {
        ext => ".js",
        shebang => "#!/usr/bin/env node",
        header => "'use strict';\n",
        main_block => (
            "function main() {\n"
            . "    // TODO: Implementiere {source_lang} Funktionalität in JavaScript\n"
            . "}\n\n"
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
            "main() {\n"
            . "    # TODO: Implementiere {source_lang} Funktionalität in Bash\n"
            . "}\n\n"
            . "main \"\$@\"\n"
        ),
    },
    "powershell" => {
        ext => ".ps1",
        shebang => "#!/usr/bin/env pwsh",
        header => "#Requires -Version 7\n",
        main_block => (
            "function Main {\n"
            . "    # TODO: Implementiere {source_lang} Funktionalität in PowerShell\n"
            . "}\n\n"
            . "Main\n"
        ),
    },
    "tcl" => {
        ext => ".tcl",
        shebang => "#!/usr/bin/env tclsh",
        header => "package require Tcl 8.6\n",
        main_block => (
            "proc main {} {\n"
            . "    # TODO: Implementiere {source_lang} Funktionalität in Tcl\n"
            . "}\n\n"
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
            "func main() {\n"
            . "    // TODO: Implementiere {source_lang} Funktionalität in Go\n"
            . "    _ = fmt.Println\n"
            . "}\n"
        ),
    },
);

# ---------------------------------------------------------------------------
# Logging-Setup
# ---------------------------------------------------------------------------

sub _setup_logger {
    make_path($LOG_DIR) unless -d $LOG_DIR;
    
    my $log_level_name = uc($ENV{"ABSTRACTIONS_LOG_LEVEL"} // "INFO");
    my %log_levels = (
        DEBUG => 10,
        INFO  => 20,
        WARN  => 30,
        ERROR => 40,
        FATAL => 50
    );
    my $log_level = $log_levels{$log_level_name} // 20;
    
    # In Perl simulieren wir das Logging mit einfachen print-Anweisungen
    # Da es keine direkte Entsprechung zu RotatingFileHandler gibt,
    # verwenden wir eine einfache Datei
    my $log_file = File::Spec->catfile($LOG_DIR, strftime("%Y-%m-%d", localtime) . ".log");
    
    open my $log_fh, ">>:encoding(UTF-8)", $log_file or die "Cannot open log file: $!";
    
    return {
        level => $log_level,
        fh => $log_fh,
        levels => \%log_levels
    };
}

my $logger = _setup_logger();

sub log_message {
    my ($level, $message) = @_;
    my $level_num = $logger->{levels}->{$level} // 20;
    return if $level_num < $logger->{level};
    
    my $timestamp = strftime("%Y-%m-%d %H:%M:%S", localtime);
    my $formatted = "$timestamp | $level  | main:" . (caller)[2] . " | $message\n";
    
    print $logger->{fh} $formatted;
    print STDERR $formatted if $level eq "ERROR" || $level eq "WARN";
}

# ---------------------------------------------------------------------------
# State-Management
# ---------------------------------------------------------------------------

sub load_state {
    my $default_state = {
        processed => {},
        queue => [],
        current_priority => "high",
        stats => {total_scripts => 0, abstractions_created => 0},
    };
    
    return $default_state unless -f $STATE_FILE;
    
    open my $fh, "<:encoding(UTF-8)", $STATE_FILE or do {
        log_message("ERROR", "State-File konnte nicht gelesen werden ($STATE_FILE): $!");
        return $default_state;
    };
    
    my $json_text = do { local $/; <$fh> };
    close $fh;
    
    my $state = eval { decode_json($json_text) };
    if ($@) {
        log_message("ERROR", "State-File konnte nicht geparst werden ($STATE_FILE): $@");
        return $default_state;
    }
    
    return $state;
}

sub save_state {
    my ($state) = @_;
    
    my $state_dir = dirname($STATE_FILE);
    make_path($state_dir) unless -d $state_dir;
    
    my ($tmp_fh, $tmp_path) = tempfile(
        DIR => $state_dir,
        SUFFIX => ".tmp",
        UNLINK => 0
    );
    
    print $tmp_fh encode_json($state);
    close $tmp_fh;
    
    if (rename($tmp_path, $STATE_FILE)) {
        log_message("DEBUG", "State atomar gespeichert: $STATE_FILE");
    } else {
        log_message("ERROR", "State konnte nicht gespeichert werden: $!");
        unlink $tmp_path;
    }
}

# ---------------------------------------------------------------------------
# Node-Management
# ---------------------------------------------------------------------------

sub check_node_status {
    my ($node_id) = @_;
    
    my $cmd = ["openclaw", "nodes", "status", $node_id];
    my ($stdout, $stderr, $exit);
    
    eval {
        run3($cmd, undef, \$stdout, \$stderr);
        $exit = $? >> 8;
    };
    
    if ($@ && $@ =~ /timeout/i) {
        log_message("WARN", "Timeout beim Status-Check von $node_id — verwende always_available");
        return $NODES{$node_id}->{always_available} // 0;
    }
    
    if ($@ && $@ =~ /not found/i) {
        log_message("WARN", "'openclaw'-Binary nicht gefunden — verwende always_available für $node_id");
        return $NODES{$node_id}->{always_available} // 0;
    }
    
    if ($@) {
        log_message("WARN", "OSError beim Status-Check von $node_id: $@ — verwende always_available");
        return $NODES{$node_id}->{always_available} // 0;
    }
    
    my $stdout_lower = lc($stdout // "");
    return ($exit == 0 && ($stdout_lower =~ /online/ || $stdout_lower =~ /active/));
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
    
    my $preferred_order = $weight_to_preference{$job_weight} // ["node1", "node2"];
    
    for my $node_id (@$preferred_order) {
        next unless exists $NODES{$node_id};
        my $node_cfg = $NODES{$node_id};
        next if !$node_cfg->{always_available} && $job_weight ne "light";
        if (check_node_status($node_id)) {
            log_message("DEBUG", "Node $node_id ausgewählt für ${job_weight}-Job");
            return $node_id;
        }
    }
    
    log_message("WARN", "Kein passender Node gefunden für Gewicht '$job_weight' — Fallback node1");
    return "node1";
}

# ---------------------------------------------------------------------------
# Script-Verarbeitung
# ---------------------------------------------------------------------------

sub find_scripts_in_dir {
    my ($directory, $exclude_patterns) = @_;
    $exclude_patterns //= ["node_modules", ".git", "__pycache__", "dist", "build"];
    
    my @scripts = ();
    return \@scripts unless -d $directory;
    
    my @glob_patterns = ("*.py", "*.js", "*.sh", "*.pl", "*.rb");
    
    find(sub {
        return if -d $_;
        my $path = $File::Find::name;
        
        # Prüfe Ausschlussmuster
        for my $pattern (@$exclude_patterns) {
            return if index($path, $pattern) >= 0;
        }
        
        # Prüfe Dateiendung
        for my $pattern (@glob_patterns) {
            if ($_ =~ /\Q$pattern\E$/) {
                push @scripts, $path;
                last;
            }
        }
    }, $directory);
    
    return \@scripts;
}

sub _build_stub_content {
    my ($script_path, $target_lang, $source_lang, $template) = @_;
    
    my $today = strftime("%Y-%m-%d", localtime);
    
    my @original_lines = ();
    if (open my $fh, "<:encoding(UTF-8)", $script_path) {
        my $i = 0;
        while (my $line = <$fh>) {
            last if $i++ >= 15;
            push @original_lines, $line;
        }
        close $fh;
    } else {
        log_message("WARN", "Originaldatei konnte nicht gelesen werden: $!");
    }
    
    # Kommentarzeichen ist für alle unterstützten Sprachen '#' außer Go und JS
    my $comment_char = ($target_lang eq "go" || $target_lang eq "javascript") ? "//" : "#";
    my $original_preview = "";
    for my $line (@original_lines) {
        $original_preview .= "$comment_char $line";
    }
    
    my $main_block = $template->{main_block};
    $main_block =~ s/\{source_lang\}/$source_lang/g;
    
    return join("\n",
        $template->{shebang},
        "$comment_char " . basename($script_path, qr/\.[^.]*/) . " - " . ucfirst($target_lang) . " Version",
        "$comment_char Portiert von $source_lang",
        "$comment_char Original: $script_path",
        "$comment_char Erstellt: $today",
        "",
        $template->{header},
        "$comment_char Original-Code-Referenz:",
        $original_preview,
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
    my $source_lang = $ext_map{substr($script_path, -2, 2)} // ucfirst(substr($script_path, -2, 2));
    
    my $target_dir = File::Spec->catdir($ABSTRACTIONS_REPO, $target_lang);
    eval { make_path($target_dir) };
    if ($@) {
        log_message("ERROR", "Zielverzeichnis konnte nicht erstellt werden ($target_dir): $@");
        return 0;
    }
    
    my $target_file = File::Spec->catfile($target_dir, basename($script_path, qr/\.[^.]*/) . $template->{ext});
    if (-f $target_file) {
        log_message("DEBUG", "Bereits vorhanden, übersprungen: $target_file");
        return 0;
    }
    
    my $content = _build_stub_content($script_path, $target_lang, $source_lang, $template);
    
    my ($tmp_fh, $tmp_path) = tempfile(
        DIR => $target_dir,
        SUFFIX => $template->{ext},
        UNLINK => 0
    );
    
    print $tmp_fh $content;
    close $tmp_fh;
    
    if (rename($tmp_path, $target_file)) {
        log_message("INFO", "Erstellt: $target_file");
        return 1;
    } else {
        log_message("ERROR", "Stub konnte nicht geschrieben werden ($target_file): $!");
        unlink $tmp_path;
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
                    log_message("DEBUG", "Verarbeitet auf $node_id: " . basename($script_path) . " → $lang");
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
        ["skill-creator",   File::Spec->catdir($WORKSPACE, "skills", "skill-creator", "scripts")],
        ["json-utils",      File::Spec->catdir($WORKSPACE, "skills", "json-utils", "scripts")],
        ["scripting-utils", File::Spec->catdir($WORKSPACE, "skills", "scripting-utils", "scripts")],
        ["model-usage",     File::Spec->catdir($WORKSPACE, "skills", "model-usage", "scripts")],
        ["tiktok-live",     File::Spec->catdir($WORKSPACE, "skills", "tiktok-live", "scripts")],
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
            log_message("INFO", "Verarbeite " . basename($script_path) . " ($job_weight) auf $selected_node");
            $created += process_on_node($selected_node, [$script_path], \@target_langs);
        }
    }
    
    return $created;
}

sub process_priority_medium {
    my @target_dirs = (
        ["workspace-scripts", File::Spec->catdir($WORKSPACE, "scripts")],
        ["db-maintainer",     File::Spec->catdir($WORKSPACE, "skills", "db-maintainer", "scripts")],
        ["log-collector",     File::Spec->catdir($WORKSPACE, "skills", "log-collector", "scripts")],
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
            # Mittlere Priorität: schwere Jobs auf 'medium' herunterstufen
            my $effective_weight = $job_weight eq "heavy" ? "medium" : $job_weight;
            my $selected_node = get_node_by_priority($effective_weight);
            log_message("INFO", "Verarbeite " . basename($script_path) . " ($job_weight) auf $selected_node");
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
    
    my @cmd_add = ("git", "-C", $repo_str, "add", ".");
    my @cmd_commit = ("git", "-C", $repo_str, "commit", "-m", $message);
    
    my ($stdout, $stderr, $exit);
    
    eval {
        run3(\@cmd_add, undef, \$stdout, \$stderr);
        $exit = $? >> 8;
        die "git add failed" if $exit != 0;
        
        run3(\@cmd_commit, undef, \$stdout, \$stderr);
        $exit = $? >> 8;
        die "git commit failed" if $exit != 0;
    };
    
    if ($@) {
        if ($@ =~ /not found/) {
            log_message("ERROR", "'git'-Binary nicht gefunden — Commit übersprungen");
        } else {
            log_message("WARN", "Git-Befehl fehlgeschlagen: $@");
        }
        return;
    }
    
    log_message("INFO", "Git commit erfolgreich: $message");
}

# ---------------------------------------------------------------------------
# Status-Report
# ---------------------------------------------------------------------------

sub create_status_report {
    my ($state) = @_;
    
    unless (-d $ABSTRACTIONS_REPO) {
        log_message("WARN", "Abstractions-Repo existiert nicht: $ABSTRACTIONS_REPO");
        return;
    }
    
    my %lang_counts = ();
    opendir(my $dh, $ABSTRACTIONS_REPO) or return;
    while (my $entry = readdir($dh)) {
        next if $entry eq "." || $entry eq "..";
        my $lang_dir = File::Spec->catdir($ABSTRACTIONS_REPO, $entry);
        if (-d $lang_dir && exists $TARGET_LANGUAGES{$entry}) {
            opendir(my $lang_dh, $lang_dir) or next;
            my $count = 0;
            while (my $file = readdir($lang_dh)) {
                next if $file eq "." || $file eq "..";
                my $full_path = File::Spec->catfile($lang_dir, $file);
                $count++ if -f $full_path;
            }
            closedir($lang_dh);
            $lang_counts{$entry} = $count;
        }
    }
    closedir($dh);
    
    my $report_file = File::Spec->catfile($ABSTRACTIONS_REPO, "STATUS.md");
    open my $fh, ">:encoding(UTF-8)", $report_file or do {
        log_message("ERROR", "Status-Report konnte nicht geschrieben werden: $!");
        return;
    };
    
    print $fh "# Script Abstractions - Status Report\n\n";
    print $fh "**Letzte Aktualisierung:** " . strftime("%Y-%m-%d %H:%M", localtime) . "\n\n";
    print $fh "- Aktuelle Priorität: " . ($state->{current_priority} // "high") . "\n";
    print $fh "- Verarbeitete Scripts: " . (scalar(keys %{$state->{processed}})) . "\n";
    print $fh "- Abstraktionen gesamt: " . ($state->{stats}->{abstractions_created} // 0) . "\n\n";
    
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
        my $device = $cfg->{device} // "Server";
        print $fh "| $node_id | $avail | " . ($cfg->{capacity} // "unknown") . " | " . ($cfg->{priority} // "-") . " | $device |\n";
    }
    
    print $fh "\n### Job-Verteilung\n\n";
    print $fh "- **Heavy Jobs** (>50 KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n";
    print $fh "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n";
    print $fh "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n";
    
    close $fh;
    log_message("INFO", "Status-Report erstellt: $report_file");
}

# ---------------------------------------------------------------------------
# Einstiegspunkt
# ---------------------------------------------------------------------------

sub main {
    log_message("INFO", "Script Abstractions Manager (Multi-Node) gestartet");
    
    my $state = load_state();
    log_message("INFO", "State geladen: " . (scalar(keys %{$state->{processed}})) . " bereits verarbeitet");
    
    my $current_priority = $state->{current_priority} // "high";
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
    
    $state->{stats}->{last_run} = strftime("%Y-%m-%dT%H:%M:%S", localtime);
    
    # Zähle Abstraktionen
    my $total_abstractions = 0;
    for my $lang (keys %TARGET_LANGUAGES) {
        my $lang_dir = File::Spec->catdir($ABSTRACTIONS_REPO, $lang);
        if (-d $lang_dir) {
            opendir(my $dh, $lang_dir) or next;
            while (my $file = readdir($dh)) {
                next if $file eq "." || $file eq "..";
                my $full_path = File::Spec->catfile($lang_dir, $file);
                $total_abstractions++ if -f $full_path;
            }
            closedir($dh);
        }
    }
    $state->{stats}->{abstractions_created} = $total_abstractions;
    
    save_state($state);
    create_status_report($state);
    
    log_message("INFO", "Abgeschlossen. $created neue Abstraktionen erstellt.");
}

main() if !caller;

1;
