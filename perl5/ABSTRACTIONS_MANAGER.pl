#!/usr/bin/env perl
# ABSTRACTIONS_MANAGER.py — portiert nach perl5
# Quelle: python, OpenClaw@gateway1:ABSTRACTIONS_MANAGER.py
# auch in: OpenClaw@gateway1:skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py
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
use Fcntl qw(:DEFAULT :flock);
use Time::Piece;
use Cwd qw(getcwd);
use Config;

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

my $WORKSPACE = $ENV{'OPENCLAW_WORKSPACE'} // '/home/openclaw/.openclaw/workspace';
my $ABSTRACTIONS_REPO = File::Spec->catdir($WORKSPACE, 'git', 'Abstraktionen');
my $LOG_DIR = File::Spec->catdir($WORKSPACE, 'logs', 'abstractions-manager');
my $STATE_FILE = File::Spec->catfile($WORKSPACE, 'db', 'abstractions_state.json');

my %NODES = (
    'node1' => { always_available => 1,  capacity => 'medium', priority => 2 },
    'node2' => { always_available => 1,  capacity => 'medium', priority => 3 },
    'node3' => { always_available => 0,  capacity => 'medium', priority => 4 },
    'node5' => { always_available => 0,  capacity => 'low',    priority => 5,
                 device => 'Redmi Note 11S', condition => 'mobile_internet' },
    'node7' => { always_available => 1,  capacity => 'high',   priority => 1 },
);

my @AVAILABLE_MODELS = (
    'openrouter/moonshotai/kimi-k2.5',
    'openrouter/openai/gpt-4o',
    'openrouter/anthropic/claude-3-5-sonnet-20241022',
    'openrouter/google/gemini-2.0-flash-001',
    'openrouter/nvidia/llama-3.3-nemotron-super-49b-v1',
    'openrouter/qwen/qwen-2.5-coder-32b-instruct',
);

my %TARGET_LANGUAGES = (
    'perl5' => {
        ext => '.pl',
        shebang => '#!/usr/bin/env perl',
        header => "use strict;\nuse warnings;\n",
        main_block => "sub main {\n    # TODO: Implementiere {source_lang} Funktionalität in Perl 5\n}\n\nmain();\n",
    },
    'perl6' => {
        ext => '.raku',
        shebang => '#!/usr/bin/env raku',
        header => "use v6;\n",
        main_block => "sub MAIN() {\n    # TODO: Implementiere {source_lang} Funktionalität in Raku\n}\n",
    },
    'javascript' => {
        ext => '.js',
        shebang => '#!/usr/bin/env node',
        header => "'use strict';\n",
        main_block => "function main() {\n    // TODO: Implementiere {source_lang} Funktionalität in JavaScript\n}\n\nmain();\n",
    },
    'python' => {
        ext => '.py',
        shebang => '#!/usr/bin/env python3',
        header => '',
        main_block => "def main():\n    # TODO: Implementiere {source_lang} Funktionalität in Python\n    pass\n\n\nif __name__ == '__main__':\n    main()\n",
    },
    'shell' => {
        ext => '.sh',
        shebang => '#!/bin/bash',
        header => "set -euo pipefail\n",
        main_block => "main() {\n    # TODO: Implementiere {source_lang} Funktionalität in Bash\n}\n\nmain \"\$@\"\n",
    },
    'powershell' => {
        ext => '.ps1',
        shebang => '#!/usr/bin/env pwsh',
        header => "#Requires -Version 7\n",
        main_block => "function Main {\n    # TODO: Implementiere {source_lang} Funktionalität in PowerShell\n}\n\nMain\n",
    },
    'tcl' => {
        ext => '.tcl',
        shebang => '#!/usr/bin/env tclsh',
        header => "package require Tcl 8.6\n",
        main_block => "proc main {} {\n    # TODO: Implementiere {source_lang} Funktionalität in Tcl\n}\n\nmain\n",
    },
    'ruby' => {
        ext => '.rb',
        shebang => '#!/usr/bin/env ruby',
        header => "# frozen_string_literal: true\nrequire 'json'\nrequire 'fileutils'\n",
        main_block => "def main\n  # TODO: Implementiere {source_lang} Funktionalität in Ruby\nend\n\nmain if __FILE__ == \$PROGRAM_NAME\n",
    },
    'lua' => {
        ext => '.lua',
        shebang => '#!/usr/bin/env lua',
        header => '',
        main_block => "local function main()\n    -- TODO: Implementiere {source_lang} Funktionalität in Lua\nend\n\nmain()\n",
    },
    'go' => {
        ext => '.go',
        shebang => '// +build ignore',
        header => "package main\n\nimport \"fmt\"\n",
        main_block => "func main() {\n    // TODO: Implementiere {source_lang} Funktionalität in Go\n    _ = fmt.Println\n}\n",
    },
);

# ---------------------------------------------------------------------------
# Logging-Setup
# ---------------------------------------------------------------------------

sub _setup_logger {
    make_path($LOG_DIR) unless -d $LOG_DIR;
    
    my $log_level_name = uc($ENV{'ABSTRACTIONS_LOG_LEVEL'} // 'INFO');
    my %log_levels = (
        'DEBUG' => 10,
        'INFO'  => 20,
        'WARN'  => 30,
        'ERROR' => 40,
    );
    my $log_level = $log_levels{$log_level_name} // 20;
    
    return {
        level => $log_level,
        levels => \%log_levels,
        log_dir => $LOG_DIR,
    };
}

my $logger = _setup_logger();

sub log_message {
    my ($level, $message) = @_;
    my $level_num = $logger->{levels}->{$level} // 20;
    
    return if $level_num < $logger->{level};
    
    my $timestamp = strftime('%Y-%m-%d %H:%M:%S', localtime);
    my $log_line = sprintf("%s | %-8s | %s\n", $timestamp, $level, $message);
    
    print STDERR $log_line;
    
    my $log_file = File::Spec->catfile($logger->{log_dir}, strftime('%Y-%m-%d', localtime) . '.log');
    open(my $fh, '>>:encoding(UTF-8)', $log_file) or return;
    print $fh $log_line;
    close $fh;
}

# ---------------------------------------------------------------------------
# State-Management
# ---------------------------------------------------------------------------

sub load_state {
    my $default_state = {
        processed => {},
        queue => [],
        current_priority => 'high',
        stats => { total_scripts => 0, abstractions_created => 0 },
    };
    
    return $default_state unless -f $STATE_FILE;
    
    open(my $fh, '<:encoding(UTF-8)', $STATE_FILE) or do {
        log_message('ERROR', "State-File konnte nicht gelesen werden ($STATE_FILE): $!");
        return $default_state;
    };
    
    my $json_text = do { local $/; <$fh> };
    close $fh;
    
    eval {
        my $data = decode_json($json_text);
        return $data;
    };
    if ($@) {
        log_message('ERROR', "State-File konnte nicht geparst werden ($STATE_FILE): $@");
        return $default_state;
    }
}

sub save_state {
    my ($state) = @_;
    
    my $state_dir = File::Spec->catdir($WORKSPACE, 'db');
    make_path($state_dir) unless -d $state_dir;
    
    my $tmp_path = File::Spec->catfile($state_dir, '.abstractions_state_' . time() . $$ . '.tmp');
    
    eval {
        open(my $fh, '>:encoding(UTF-8)', $tmp_path) or die "Cannot create temp file: $!";
        print $fh to_json($state, { pretty => 1, utf8 => 1 });
        close $fh;
        
        rename($tmp_path, $STATE_FILE) or die "Cannot replace state file: $!";
        log_message('DEBUG', "State atomar gespeichert: $STATE_FILE");
    };
    if ($@) {
        log_message('ERROR', "State konnte nicht gespeichert werden: $@");
        unlink($tmp_path) if -e $tmp_path;
    }
}

# ---------------------------------------------------------------------------
# Node-Management
# ---------------------------------------------------------------------------

sub check_node_status {
    my ($node_id) = @_;
    
    eval {
        local $SIG{ALRM} = sub { die "timeout\n" };
        alarm(5);
        
        my $output = `openclaw nodes status $node_id 2>&1`;
        alarm(0);
        
        my $exit_code = $? >> 8;
        my $stdout_lower = lc($output);
        return ($exit_code == 0 && ($stdout_lower =~ /online/ || $stdout_lower =~ /active/));
    };
    if ($@) {
        if ($@ eq "timeout\n") {
            log_message('WARNING', "Timeout beim Status-Check von $node_id — verwende always_available");
        } elsif ($@ =~ /openclaw/) {
            log_message('WARNING', "'openclaw'-Binary nicht gefunden — verwende always_available für $node_id");
        } else {
            chomp($@);
            log_message('WARNING', "OSError beim Status-Check von $node_id: $@ — verwende always_available");
        }
    }
    
    return $NODES{$node_id}->{always_available} // 0;
}

sub get_job_weight {
    my ($script_size, $target_langs_count) = @_;
    
    my $total_work = $script_size * $target_langs_count;
    return 'heavy' if $total_work > 50000;
    return 'medium' if $total_work > 10000;
    return 'light';
}

sub get_node_by_priority {
    my ($job_weight) = @_;
    $job_weight //= 'medium';
    
    my %weight_to_preference = (
        heavy => ['node7', 'node2', 'node1'],
        medium => ['node2', 'node1', 'node7'],
        light => ['node5', 'node1', 'node2'],
    );
    
    my $preferred_order = $weight_to_preference{$job_weight} // ['node1', 'node2'];
    
    for my $node_id (@$preferred_order) {
        next unless exists $NODES{$node_id};
        my $node_cfg = $NODES{$node_id};
        next if !$node_cfg->{always_available} && $job_weight ne 'light';
        if (check_node_status($node_id)) {
            log_message('DEBUG', "Node $node_id ausgewählt für ${job_weight}-Job");
            return $node_id;
        }
    }
    
    log_message('WARNING', "Kein passender Node gefunden für Gewicht '$job_weight' — Fallback node1");
    return 'node1';
}

# ---------------------------------------------------------------------------
# Script-Verarbeitung
# ---------------------------------------------------------------------------

sub find_scripts_in_dir {
    my ($directory, $exclude_patterns) = @_;
    $exclude_patterns //= ['node_modules', '.git', '__pycache__', 'dist', 'build'];
    
    my @scripts = ();
    return \@scripts unless -d $directory;
    
    my @glob_patterns = ('*.py', '*.js', '*.sh', '*.pl', '*.rb');
    
    find(sub {
        return unless -f $_;
        my $file_path = $File::Find::name;
        
        # Check if file matches any glob pattern
        my $match = 0;
        for my $pattern (@glob_patterns) {
            if ($_ =~ /\Q${pattern}\E$/) {
                $match = 1;
                last;
            }
        }
        return unless $match;
        
        # Check exclude patterns
        my $exclude = 0;
        for my $exclude_pattern (@$exclude_patterns) {
            if ($file_path =~ /\Q$exclude_pattern\E/) {
                $exclude = 1;
                last;
            }
        }
        return if $exclude;
        
        push @scripts, $file_path;
    }, $directory);
    
    return \@scripts;
}

sub _build_stub_content {
    my ($script_path, $target_lang, $source_lang, $template) = @_;
    
    my $today = strftime('%Y-%m-%d', localtime);
    
    my @original_lines = ();
    eval {
        open(my $fh, '<:encoding(UTF-8)', $script_path) or die "Cannot open file: $!";
        my $line_count = 0;
        while (my $line = <$fh>) {
            last if $line_count++ >= 15;
            push @original_lines, $line;
        }
        close $fh;
    };
    if ($@) {
        log_message('WARNING', "Originaldatei konnte nicht gelesen werden: $@");
        @original_lines = ();
    }
    
    # Kommentarzeichen ist für alle unterstützten Sprachen '#' außer Go und JS
    my $comment_char = ($target_lang eq 'go' || $target_lang eq 'javascript') ? '//' : '#';
    my $original_preview = join('', map { "${comment_char} $_" } @original_lines);
    
    my $main_block = $template->{main_block};
    $main_block =~ s/\{source_lang\}/$source_lang/g;
    
    my $filename = (File::Spec->splitpath($script_path))[2];
    $filename =~ s/\.[^.]+$//; # remove extension
    
    return join("\n",
        $template->{shebang},
        "${comment_char} ${filename} - " . ucfirst($target_lang) . " Version",
        "${comment_char} Portiert von $source_lang",
        "${comment_char} Original: $script_path",
        "${comment_char} Erstellt: $today",
        "",
        $template->{header},
        "${comment_char} Original-Code-Referenz:",
        $original_preview,
        "",
        $main_block
    );
}

sub create_abstraction {
    my ($script_path, $target_lang) = @_;
    
    unless (exists $TARGET_LANGUAGES{$target_lang}) {
        log_message('ERROR', "Unbekannte Zielsprache: $target_lang");
        return 0;
    }
    
    my $template = $TARGET_LANGUAGES{$target_lang};
    my %ext_map = (py => 'Python', js => 'JavaScript', sh => 'Shell', pl => 'Perl', rb => 'Ruby');
    my $source_lang = $ext_map{(split(/\./, $script_path))[-1]} // ucfirst((split(/\./, $script_path))[-1]);
    
    my $target_dir = File::Spec->catdir($ABSTRACTIONS_REPO, $target_lang);
    eval { make_path($target_dir) };
    if ($@) {
        log_message('ERROR', "Zielverzeichnis konnte nicht erstellt werden ($target_dir): $@");
        return 0;
    }
    
    my $filename = (File::Spec->splitpath($script_path))[2];
    $filename =~ s/\.[^.]+$//; # remove extension
    my $target_file = File::Spec->catfile($target_dir, $filename . $template->{ext});
    
    if (-e $target_file) {
        log_message('DEBUG', "Bereits vorhanden, übersprungen: $target_file");
        return 0;
    }
    
    my $content = _build_stub_content($script_path, $target_lang, $source_lang, $template);
    
    eval {
        my ($fh, $tmp_path) = tempfile(
            'stub_XXXXXX',
            SUFFIX => $template->{ext},
            DIR => $target_dir
        );
        print $fh $content;
        close $fh;
        rename($tmp_path, $target_file) or die "Cannot rename temp file: $!";
        log_message('INFO', "Erstellt: $target_file");
        return 1;
    };
    if ($@) {
        log_message('ERROR', "Stub konnte nicht geschrieben werden ($target_file): $@");
        return 0;
    }
}

sub process_on_node {
    my ($node_id, $scripts, $target_langs) = @_;
    
    my $created = 0;
    
    if ($node_id eq 'node1') {
        for my $script_path (@$scripts) {
            for my $lang (@$target_langs) {
                $created++ if create_abstraction($script_path, $lang);
            }
        }
    } else {
        log_message('INFO', "Dispatching " . scalar(@$scripts) . " Jobs an $node_id (lokaler Fallback aktiv)");
        # TODO: Remote-Dispatch implementieren wenn Node-Infrastruktur bereit ist
        for my $script_path (@$scripts) {
            for my $lang (@$target_langs) {
                if (create_abstraction($script_path, $lang)) {
                    $created++;
                    log_message('DEBUG', "Verarbeitet auf $node_id: " . (File::Spec->splitpath($script_path))[2] . " → $lang");
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
        ['skill-creator',   File::Spec->catdir($WORKSPACE, 'skills', 'skill-creator',   'scripts')],
        ['json-utils',      File::Spec->catdir($WORKSPACE, 'skills', 'json-utils',       'scripts')],
        ['scripting-utils', File::Spec->catdir($WORKSPACE, 'skills', 'scripting-utils',  'scripts')],
        ['model-usage',     File::Spec->catdir($WORKSPACE, 'skills', 'model-usage',      'scripts')],
        ['tiktok-live',     File::Spec->catdir($WORKSPACE, 'skills', 'tiktok-live',      'scripts')],
    );
    my @target_langs = ('perl5', 'javascript', 'python', 'shell', 'tcl');
    my $created = 0;
    my @exclude = ('node_modules', '.git', 'test', 'tests');
    
    for my $dir_info (@target_dirs) {
        my ($skill_name, $scripts_dir) = @$dir_info;
        my $scripts = find_scripts_in_dir($scripts_dir, \@exclude);
        log_message('INFO', "$skill_name: " . scalar(@$scripts) . " Scripts gefunden");
        
        my $count = 0;
        for my $script_path (@$scripts) {
            last if $count++ >= 10;
            
            my $script_size = -f $script_path ? (stat($script_path))[7] : 0;
            my $job_weight = get_job_weight($script_size, scalar(@target_langs));
            my $selected_node = get_node_by_priority($job_weight);
            log_message('INFO', "Verarbeite " . (File::Spec->splitpath($script_path))[2] . " ($job_weight) auf $selected_node");
            $created += process_on_node($selected_node, [$script_path], \@target_langs);
        }
    }
    
    return $created;
}

sub process_priority_medium {
    my @target_dirs = (
        ['workspace-scripts', File::Spec->catdir($WORKSPACE, 'scripts')],
        ['db-maintainer',     File::Spec->catdir($WORKSPACE, 'skills', 'db-maintainer',  'scripts')],
        ['log-collector',     File::Spec->catdir($WORKSPACE, 'skills', 'log-collector',   'scripts')],
    );
    my @target_langs = ('perl5', 'javascript', 'powershell', 'python');
    my $created = 0;
    my @exclude = ('node_modules', '.git');
    
    for my $dir_info (@target_dirs) {
        my ($dir_name, $scripts_dir) = @$dir_info;
        my $scripts = find_scripts_in_dir($scripts_dir, \@exclude);
        
        my $count = 0;
        for my $script_path (@$scripts) {
            last if $count++ >= 10;
            
            my $script_size = -f $script_path ? (stat($script_path))[7] : 0;
            my $job_weight = get_job_weight($script_size, scalar(@target_langs));
            # Mittlere Priorität: schwere Jobs auf 'medium' herunterstufen
            my $effective_weight = $job_weight eq 'heavy' ? 'medium' : $job_weight;
            my $selected_node = get_node_by_priority($effective_weight);
            log_message('INFO', "Verarbeite " . (File::Spec->splitpath($script_path))[2] . " ($job_weight) auf $selected_node");
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
    
    return unless -d $ABSTRACTIONS_REPO;
    
    eval {
        chdir($ABSTRACTIONS_REPO) or die "Cannot change directory: $!";
        system('git', 'add', '.') == 0 or die "Git add failed";
        system('git', 'commit', '-m', $message) == 0 or die "Git commit failed";
        log_message('INFO', "Git commit erfolgreich: $message");
        chdir(getcwd()) or die "Cannot change back to original directory: $!";
    };
    if ($@) {
        if ($@ =~ /git/) {
            log_message('WARNING', "Git-Befehl fehlgeschlagen: $@");
        } elsif ($@ =~ /git/) {
            log_message('ERROR', "'git'-Binary nicht gefunden — Commit übersprungen");
        } else {
            log_message('ERROR', "OSError beim Git-Commit: $@");
        }
        chdir(getcwd()) if -d getcwd(); # Try to change back anyway
    }
}

# ---------------------------------------------------------------------------
# Status-Report
# ---------------------------------------------------------------------------

sub create_status_report {
    my ($state) = @_;
    
    return unless -d $ABSTRACTIONS_REPO;
    
    my %lang_counts = ();
    opendir(my $dh, $ABSTRACTIONS_REPO) or return;
    while (my $lang_dir = readdir($dh)) {
        next if $lang_dir =~ /^\.\.?$/;
        my $full_path = File::Spec->catdir($ABSTRACTIONS_REPO, $lang_dir);
        next unless -d $full_path && exists $TARGET_LANGUAGES{$lang_dir};
        
        opendir(my $files_dh, $full_path) or next;
        my $count = 0;
        while (my $file = readdir($files_dh)) {
            next if $file =~ /^\.\.?$/;
            my $file_path = File::Spec->catfile($full_path, $file);
            $count++ if -f $file_path;
        }
        closedir($files_dh);
        $lang_counts{$lang_dir} = $count;
    }
    closedir($dh);
    
    my $report_file = File::Spec->catfile($ABSTRACTIONS_REPO, 'STATUS.md');
    eval {
        open(my $fh, '>:encoding(UTF-8)', $report_file) or die "Cannot create report file: $!";
        print $fh "# Script Abstractions - Status Report\n\n";
        print $fh "**Letzte Aktualisierung:** " . strftime('%Y-%m-%d %H:%M', localtime) . "\n\n";
        print $fh "- Aktuelle Priorität: " . ($state->{current_priority} // 'high') . "\n";
        print $fh "- Verarbeitete Scripts: " . (scalar(keys %{$state->{processed} // {}})) . "\n";
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
            my $cfg = $NODES{$node_id};
            my $avail = $cfg->{always_available} ? '✅ Immer' : '📱 Bedingt';
            my $device = $cfg->{device} // 'Server';
            print $fh "| $node_id | $avail | " . ($cfg->{capacity} // 'unknown') . " | " . ($cfg->{priority} // '-') . " | $device |\n";
        }
        
        print $fh "\n### Job-Verteilung\n\n";
        print $fh "- **Heavy Jobs** (>50 KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n";
        print $fh "- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n";
        print $fh "- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n";
        
        close $fh;
        log_message('INFO', "Status-Report erstellt: $report_file");
    };
    if ($@) {
        log_message('ERROR', "Status-Report konnte nicht geschrieben werden: $@");
    }
}

# ---------------------------------------------------------------------------
# Einstiegspunkt
# ---------------------------------------------------------------------------

sub main {
    log_message('INFO', "Script Abstractions Manager (Multi-Node) gestartet");
    
    my $state = load_state();
    log_message('INFO', "State geladen: " . (scalar(keys %{$state->{processed} // {}})) . " bereits verarbeitet");
    
    my $current_priority = $state->{current_priority} // 'high';
    my $created = 0;
    
    if ($current_priority eq 'high') {
        log_message('INFO', "Verarbeite HIGH-Priorität: Top 5 Skills");
        $created = process_priority_high();
        if ($created > 0) {
            git_commit("High priority: $created abstractions");
        }
        $state->{current_priority} = 'medium';
    } elsif ($current_priority eq 'medium') {
        log_message('INFO', "Verarbeite MEDIUM-Priorität: Workspace Scripts");
        $created = process_priority_medium();
        if ($created > 0) {
            git_commit("Medium priority: $created abstractions");
        }
        $state->{current_priority} = 'high';  # Zyklus zurücksetzen
    }
    
    $state->{stats}->{last_run} = strftime('%Y-%m-%dT%H:%M:%S', localtime);
    
    my $total_abstractions = 0;
    for my $lang (keys %TARGET_LANGUAGES) {
        my $lang_dir = File::Spec->catdir($ABSTRACTIONS_REPO, $lang);
        next unless -d $lang_dir;
        
        opendir(my $dh, $lang_dir) or next;
        while (my $file = readdir($dh)) {
            next if $file =~ /^\.\.?$/;
            my $file_path = File::Spec->catfile($lang_dir, $file);
            $total_abstractions++ if -f $file_path;
        }
        closedir($dh);
    }
    $state->{stats}->{abstractions_created} = $total_abstractions;
    
    save_state($state);
    create_status_report($state);
    
    log_message('INFO', "Abgeschlossen. $created neue Abstraktionen erstellt.");
}

main() if __FILE__ eq $0;

# Helper function to mimic Python's tempfile.mkstemp
sub tempfile {
    my (%args) = @_;
    my $suffix = $args{SUFFIX} // '';
    my $dir = $args{DIR} // '.';
    
    my $tmp_name = File::Spec->catfile($dir, "temp_" . time() . "_" . $$ . "_$$" . $suffix);
    open(my $fh, '+>', $tmp_name) or die "Cannot create temp file: $!";
    
    return ($fh, $tmp_name);
}
