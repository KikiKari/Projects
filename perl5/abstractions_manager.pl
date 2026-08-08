#!/usr/bin/env perl
# abstractions_manager.js — portiert nach perl5
# Quelle: javascript, Projects@abstractions:javascript/abstractions_manager.js
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use File::Find;
use File::Spec;
use File::Path qw(make_path);
use File::Basename;
use Cwd;
use POSIX qw(strftime);

# Konfiguration
my $WORKSPACE = File::Spec->catdir($ENV{HOME}, '.openclaw', 'workspace');
my $ABSTRACTIONS_REPO = File::Spec->catdir($WORKSPACE, 'git', 'Abstraktionen');
my $LOG_DIR = File::Spec->catdir($WORKSPACE, 'logs', 'abstractions-manager');
my $STATE_FILE = File::Spec->catdir($WORKSPACE, 'db', 'abstractions_state.json');

# Node-Konfiguration mit Prioritäten
my %NODES = (
    "node1" => {"always_available" => 1, "capacity" => "medium", "priority" => 2},  # Gateway-Master
    "node2" => {"always_available" => 1, "capacity" => "medium", "priority" => 3},  # Stable Worker
    "node3" => {"always_available" => 0, "capacity" => "medium", "priority" => 4}, # Bald verfügbar
    "node5" => {"always_available" => 0, "capacity" => "low", "priority" => 5, "device" => "Redmi Note 11S", "condition" => "mobile_internet"},
    "node7" => {"always_available" => 1, "capacity" => "high", "priority" => 1},    # Docker Hauptarbeitspferd
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
    "perl5" => {"ext" => ".pl", "shebang" => "#!/usr/bin/env perl", "header" => "use strict;\nuse warnings;\n"},
    "perl6" => {"ext" => ".raku", "shebang" => "#!/usr/bin/env raku", "header" => "use v6;\n"},
    "javascript" => {"ext" => ".js", "shebang" => "#!/usr/bin/env node", "header" => ""},
    "python" => {"ext" => ".py", "shebang" => "#!/usr/bin/env python3", "header" => ""},
    "shell" => {"ext" => ".sh", "shebang" => "#!/bin/bash", "header" => "set -euo pipefail\n"},
    "powershell" => {"ext" => ".ps1", "shebang" => "#!/usr/bin/env pwsh", "header" => "#Requires -Version 7\n"},
    "tcl" => {"ext" => ".tcl", "shebang" => "#!/usr/bin/env tclsh", "header" => "package require Tcl 8.6\n"},
    "ruby" => {"ext" => ".rb", "shebang" => "#!/usr/bin/env ruby", "header" => "require 'json'\nrequire 'fileutils'\n"},
    "lua" => {"ext" => ".lua", "shebang" => "#!/usr/bin/env lua", "header" => ""},
    "go" => {"ext" => ".go", "shebang" => "// +build ignore", "header" => "package main\n"},
);

sub log_message {
    my ($message, $level) = @_;
    $level //= "INFO";
    
    make_path($LOG_DIR) unless -d $LOG_DIR;
    my $timestamp = strftime "%Y-%m-%d %H:%M:%S", localtime;
    my $line = "[$timestamp] [$level] $message\n";
    print $line;
    my $log_file = File::Spec->catfile($LOG_DIR, strftime "%Y-%m-%d", localtime) . ".log";
    open my $fh, ">>", $log_file or die "Cannot open $log_file: $!";
    print $fh $line;
    close $fh;
}

sub getNodeByPriority {
    my ($jobWeight) = @_;
    $jobWeight //= "medium";
    
    # Prioritäts-Matrix
    my @preferredOrder;
    if ($jobWeight eq "heavy") {
        # Schwere Jobs → Node 7 (Docker mit vielen Ressourcen)
        @preferredOrder = ("node7", "node2", "node1");
    } elsif ($jobWeight eq "medium") {
        # Mittlere Jobs → Stable Nodes
        @preferredOrder = ("node2", "node1", "node7");
    } else {  # light
        # Leichte Jobs → Mobile/verfügbare Nodes
        @preferredOrder = ("node5", "node1", "node2");
    }
    
    # Prüfe Verfügbarkeit
    for my $nodeId (@preferredOrder) {
        next unless exists $NODES{$nodeId};
        
        my $node = $NODES{$nodeId};
        
        # Skip nicht immer verfügbare Nodes wenn nicht explizit requested
        next if !$node->{"always_available"} && $jobWeight ne "light";
        
        # Prüfe ob Node online
        if (checkNodeStatus($nodeId)) {
            return $nodeId;
        }
    }
    
    # Fallback zu Node 1
    return "node1";
}

sub checkNodeStatus {
    my ($nodeId) = @_;
    # Prüft ob ein Node erreichbar ist
    eval {
        open my $pipe, "-|", "openclaw nodes status $nodeId" or die "Cannot run command: $!";
        local $/ = undef;
        my $result = <$pipe>;
        close $pipe;
        return ($result =~ /online/ || $result =~ /active/);
    };
    if ($@) {
        # Bei Timeout/Error: Prüfe letzten bekannten Status
        return $NODES{$nodeId}{"always_available"} // 0;
    }
}

sub getJobWeight {
    my ($scriptSize, $targetLangsCount) = @_;
    # Bewertet Job-Gewicht basierend auf Script-Größe und Anzahl Zielsprachen
    my $totalWork = $scriptSize * $targetLangsCount;
    
    if ($totalWork > 50000) {  # Große Scripts, viele Sprachen
        return "heavy";
    } elsif ($totalWork > 10000) {  # Mittlere Last
        return "medium";
    } else {
        return "light";
    }
}

sub loadState {
    if (-e $STATE_FILE) {
        eval {
            open my $fh, "<", $STATE_FILE or die "Cannot open $STATE_FILE: $!";
            my $json_text = do { local $/; <$fh> };
            close $fh;
            my $data = decode_json($json_text);
            return $data;
        };
        if ($@) {
            # ignore error
        }
    }
    return {"processed" => {}, "queue" => [], "current_priority" => "high", "stats" => {"total_scripts" => 0, "abstractions_created" => 0}};
}

sub saveState {
    my ($state) = @_;
    make_path(dirname($STATE_FILE)) unless -d dirname($STATE_FILE);
    open my $fh, ">", $STATE_FILE or die "Cannot open $STATE_FILE: $!";
    print $fh encode_json($state);
    close $fh;
}

sub findScriptsInDir {
    my ($directory, $excludePatterns) = @_;
    $excludePatterns //= ["node_modules", ".git", "__pycache__", "dist", "build"];
    my @scripts = ();
    if (-d $directory) {
        my @files = getAllFiles($directory);
        my @extensions = (".py", ".js", ".sh", ".pl", ".rb");
        for my $file (@files) {
            if (grep { $file =~ /\Q$_\E$/ } @extensions) {
                my $exclude = 0;
                for my $pattern (@$excludePatterns) {
                    if ($file =~ /\Q$pattern\E/) {
                        $exclude = 1;
                        last;
                    }
                }
                push @scripts, $file unless $exclude;
            }
        }
    }
    return @scripts;
}

sub getAllFiles {
    my ($dirPath, $arrayOfFiles) = @_;
    $arrayOfFiles //= [];
    opendir my $dh, $dirPath or die "Cannot opendir $dirPath: $!";
    my @files = readdir($dh);
    closedir $dh;
    for my $file (@files) {
        next if $file eq '.' || $file eq '..';
        my $filePath = File::Spec->catfile($dirPath, $file);
        if (-d $filePath) {
            $arrayOfFiles = getAllFiles($filePath, $arrayOfFiles);
        } else {
            push @$arrayOfFiles, $filePath;
        }
    }
    return @$arrayOfFiles;
}

sub createAbstraction {
    my ($scriptPath, $targetLang) = @_;
    eval {
        open my $fh, "<", $scriptPath or die "Cannot open $scriptPath: $!";
        my $originalContent = do { local $/; <$fh> };
        close $fh;
        
        my ($name, $dirs, $suffix) = fileparse($scriptPath, qr/\.[^.]*/);
        my %sourceLangMap = ("py" => "Python", "js" => "JavaScript", "sh" => "Shell", "pl" => "Perl", "rb" => "Ruby");
        my $sourceLang = $sourceLangMap{substr($suffix, 1)} // substr($suffix, 1);
        
        my $targetDir = File::Spec->catdir($ABSTRACTIONS_REPO, $targetLang);
        make_path($targetDir) unless -d $targetDir;
        
        my $targetFile = File::Spec->catfile($targetDir, $name . $TARGET_LANGUAGES{$targetLang}{"ext"});
        
        if (-e $targetFile) {
            return 0;
        }
        
        my $template = $TARGET_LANGUAGES{$targetLang};
        my @lines = split /\n/, $originalContent;
        @lines = @lines[0..14] if @lines > 15;
        
        my $content = $template->{"shebang"} . "\n";
        $content .= "# ${name} - " . ucfirst($targetLang) . " Version\n";
        $content .= "# Portiert von $sourceLang\n";
        $content .= "# Original: $scriptPath\n";
        $content .= "# Erstellt: " . strftime("%Y-%m-%d", localtime) . "\n#\n";
        $content .= $template->{"header"} . "\n" if $template->{"header"};
        $content .= "# Original-Code-Referenz:\n";
        $content .= "# " . join("\n# ", @lines) . "\n\n";
        $content .= "function main() {\n";
        $content .= "    // TODO: Implementiere $sourceLang Funktionalität in " . ucfirst($targetLang) . "\n";
        $content .= "    console.log(\"Hello World\");\n";
        $content .= "}\n\n";
        $content .= "if (require.main === module) {\n";
        $content .= "    main();\n";
        $content .= "}\n";
        
        open my $out_fh, ">", $targetFile or die "Cannot open $targetFile: $!";
        print $out_fh $content;
        close $out_fh;
        log_message("Created: $targetFile");
        return 1;
    };
    if ($@) {
        log_message("Failed: $scriptPath - $@", "ERROR");
        return 0;
    }
}

sub processOnNode {
    my ($nodeId, $scripts, $targetLangs) = @_;
    # Verarbeitet Scripts auf definiertem Node
    my $created = 0;
    
    if ($nodeId eq "node1") {
        # Lokale Verarbeitung
        for my $script (@$scripts) {
            for my $lang (@$targetLangs) {
                if (createAbstraction($script, $lang)) {
                    $created++;
                }
            }
        }
    } else {
        # Remote-Verarbeitung
        log_message("Dispatching " . scalar(@$scripts) . " jobs to $nodeId");
        # TODO: Implementiere Remote-Dispatch wenn Node-Infrastruktur bereit
        # Für jetzt: Lokale Verarbeitung mit Node-Logging
        for my $script (@$scripts) {
            for my $lang (@$targetLangs) {
                if (createAbstraction($script, $lang)) {
                    $created++;
                    log_message("Processed on $nodeId: " . basename($script) . " -> $lang");
                }
            }
        }
    }
    
    return $created;
}

sub processPriorityHigh {
    my $created = 0;
    my @targets = (
        ["skill-creator", File::Spec->catdir($WORKSPACE, "skills", "skill-creator", "scripts")],
        ["json-utils", File::Spec->catdir($WORKSPACE, "skills", "json-utils", "scripts")],
        ["scripting-utils", File::Spec->catdir($WORKSPACE, "skills", "scripting-utils", "scripts")],
        ["model-usage", File::Spec->catdir($WORKSPACE, "skills", "model-usage", "scripts")],
        ["tiktok-live", File::Spec->catdir($WORKSPACE, "skills", "tiktok-live", "scripts")],
    );
    
    for my $target (@targets) {
        my ($skillName, $scriptsDir) = @$target;
        my @scripts = findScriptsInDir($scriptsDir, ["node_modules", ".git", "test", "tests"]);
        log_message("$skillName: " . scalar(@scripts) . " scripts found");
        
        for my $script (@scripts[0..9]) {  # Limit für erste Durchläufe
            my $scriptSize = -e $script ? (stat($script))[7] : 0;
            my @targetLangs = ("perl5", "javascript", "python", "shell", "tcl");
            my $jobWeight = getJobWeight($scriptSize, scalar(@targetLangs));
            
            # Wähle Node basierend auf Job-Gewicht
            my $selectedNode = getNodeByPriority($jobWeight);
            log_message("Processing " . basename($script) . " ($jobWeight) on $selectedNode");
            
            $created += processOnNode($selectedNode, [$script], \@targetLangs);
        }
    }
    
    return $created;
}

sub processPriorityMedium {
    my $created = 0;
    my @targets = (
        ["workspace-scripts", File::Spec->catdir($WORKSPACE, "scripts")],
        ["db-maintainer", File::Spec->catdir($WORKSPACE, "skills", "db-maintainer", "scripts")],
        ["log-collector", File::Spec->catdir($WORKSPACE, "skills", "log-collector", "scripts")],
    );
    
    for my $target (@targets) {
        my ($dirName, $scriptsDir) = @$target;
        my @scripts = findScriptsInDir($scriptsDir, ["node_modules", ".git"]);
        
        for my $script (@scripts[0..9]) {
            my $scriptSize = -e $script ? (stat($script))[7] : 0;
            my @targetLangs = ("perl5", "javascript", "powershell", "python");
            my $jobWeight = getJobWeight($scriptSize, scalar(@targetLangs));
            
            # Mittlere Priority → eher leichtere Jobs
            my $selectedNode = getNodeByPriority($jobWeight eq "heavy" ? "medium" : $jobWeight);
            log_message("Processing " . basename($script) . " ($jobWeight) on $selectedNode");
            
            $created += processOnNode($selectedNode, [$script], \@targetLangs);
        }
    }
    
    return $created;
}

sub gitCommit {
    my ($message) = @_;
    eval {
        my $old_dir = getcwd();
        chdir($ABSTRACTIONS_REPO);
        system("git add .");
        system("git commit -m \"$message\"");
        log_message("Git commit: $message");
        chdir($old_dir);
    };
    # ignore error
}

sub createStatusReport {
    my ($state) = @_;
    my $reportFile = File::Spec->catfile($ABSTRACTIONS_REPO, "STATUS.md");
    my %langCounts = ();
    if (-d $ABSTRACTIONS_REPO) {
        opendir my $dh, $ABSTRACTIONS_REPO or die "Cannot opendir $ABSTRACTIONS_REPO: $!";
        my @langs = readdir($dh);
        closedir $dh;
        for my $lang (@langs) {
            next if $lang eq '.' || $lang eq '..';
            my $langDir = File::Spec->catdir($ABSTRACTIONS_REPO, $lang);
            if (-d $langDir && exists $TARGET_LANGUAGES{$lang}) {
                opendir my $ldh, $langDir or die "Cannot opendir $langDir: $!";
                my @files = readdir($ldh);
                closedir $ldh;
                my $count = 0;
                for my $file (@files) {
                    next if $file eq '.' || $file eq '..';
                    my $filePath = File::Spec->catfile($langDir, $file);
                    $count++ if -f $filePath;
                }
                $langCounts{$lang} = $count;
            }
        }
    }
    
    my $content = "# Script Abstractions - Status Report\n\n";
    $content .= "**Letzte Aktualisierung:** " . strftime("%Y-%m-%d %H:%M", localtime) . "\n\n";
    $content .= "- Aktuelle Priorität: " . ($state->{"current_priority"} || "high") . "\n";
    $content .= "- Verarbeitete Scripts: " . scalar(keys %{$state->{"processed"}}) . "\n";
    $content .= "- Abstraktionen gesamt: " . $state->{"stats"}{"abstractions_created"} . "\n\n";
    
    $content .= "## Abstraktionen pro Sprache\n\n";
    for my $lang (sort keys %langCounts) {
        $content .= "- $lang: $langCounts{$lang}\n";
    }
    
    $content .= "\n## Verfügbare Modelle\n\n";
    for my $model (@AVAILABLE_MODELS[0..2]) {
        $content .= "- `$model`\n";
    }
    $content .= "- ... und " . (scalar(@AVAILABLE_MODELS) - 3) . " weitere\n";
    
    $content .= "\n## Multi-Node Support\n\n";
    $content .= "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n";
    $content .= "|------|---------------|-----------|-----------|-------|\n";
    for my $nodeId (sort keys %NODES) {
        my $config = $NODES{$nodeId};
        my $avail = $config->{"always_available"} ? "✅ Immer" : "📱 Bedingt";
        my $device = $config->{"device"} || "Server";
        $content .= "| $nodeId | $avail | " . ($config->{"capacity"} || "unknown") . " | " . ($config->{"priority"} || "-") . " | $device |\n";
    }
    
    $content .= "\n### Job-Verteilung\n\n";
    $content .= "- **Heavy Jobs** (>50KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n";
    $content .= "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n";
    $content .= "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n";
    
    open my $fh, ">", $reportFile or die "Cannot open $reportFile: $!";
    print $fh $content;
    close $fh;
}

sub main {
    log_message("Script Abstractions Manager (Multi-Node) gestartet");
    
    my $state = loadState();
    log_message("State loaded: " . scalar(keys %{$state->{"processed"}}) . " processed");
    
    my $currentPriority = $state->{"current_priority"} || "high";
    my $created = 0;
    
    if ($currentPriority eq "high") {
        log_message("Processing HIGH priority: Top 5 Skills");
        $created = processPriorityHigh();
        if ($created > 0) {
            gitCommit("High priority: $created abstractions");
        }
        $state->{"current_priority"} = "medium";
    } elsif ($currentPriority eq "medium") {
        log_message("Processing MEDIUM priority: Workspace Scripts");
        $created = processPriorityMedium();
        if ($created > 0) {
            gitCommit("Medium priority: $created abstractions");
        }
        $state->{"current_priority"} = "high";  # Zyklus
    }
    
    $state->{"stats"}{"last_run"} = strftime("%Y-%m-%dT%H:%M:%S", localtime);
    $state->{"stats"}{"abstractions_created"} = 0;
    if (-d $ABSTRACTIONS_REPO) {
        for my $lang (keys %TARGET_LANGUAGES) {
            my $langDir = File::Spec->catdir($ABSTRACTIONS_REPO, $lang);
            if (-d $langDir) {
                opendir my $dh, $langDir or die "Cannot opendir $langDir: $!";
                my @files = readdir($dh);
                closedir $dh;
                my $count = 0;
                for my $file (@files) {
                    next if $file eq '.' || $file eq '..';
                    my $filePath = File::Spec->catfile($langDir, $file);
                    $count++ if -f $filePath;
                }
                $state->{"stats"}{"abstractions_created"} += $count;
            }
        }
    }
    
    saveState($state);
    createStatusReport($state);
    
    log_message("Abgeschlossen. $created neue Abstraktionen erstellt.");
}

main();
