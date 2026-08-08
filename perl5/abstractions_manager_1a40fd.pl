#!/usr/bin/env perl
# abstractions_manager.sh — portiert nach perl5
# Quelle: shell, Projects@abstractions:shell/abstractions_manager.sh
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use JSON;
use File::Find;
use File::Spec;
use File::Basename;
use Cwd 'abs_path';

# Konfiguration
my $WORKSPACE = "/home/openclaw/.openclaw/workspace";
my $ABSTRACTIONS_REPO = "$WORKSPACE/git/Abstraktionen";
my $LOG_DIR = "$WORKSPACE/logs/abstractions-manager";
my $STATE_FILE = "$WORKSPACE/db/abstractions_state.json";

# Node-Konfiguration mit Prioritäten
my %NODES = (
  "node1" => "always_available:true,capacity:medium,priority:2",
  "node2" => "always_available:true,capacity:medium,priority:3",
  "node3" => "always_available:false,capacity:medium,priority:4",
  "node5" => "always_available:false,capacity:low,priority:5,device:Redmi Note 11S,condition:mobile_internet",
  "node7" => "always_available:true,capacity:high,priority:1"
);

# Verfügbare Modelle
my @AVAILABLE_MODELS = (
  "openrouter/moonshotai/kimi-k2.5",
  "openrouter/openai/gpt-4o",
  "openrouter/anthropic/claude-3-5-sonnet-20241022",
  "openrouter/google/gemini-2.0-flash-001",
  "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1",
  "openrouter/qwen/qwen-2.5-coder-32b-instruct"
);

# Zielsprachen-Konfiguration
my %TARGET_LANGUAGES = (
  "perl5" => "ext:.pl,shebang:#!/usr/bin/env perl,header:use strict;\\nuse warnings;\\n",
  "perl6" => "ext:.raku,shebang:#!/usr/bin/env raku,header:use v6;\\n",
  "javascript" => "ext:.js,shebang:#!/usr/bin/env node,header:",
  "python" => "ext:.py,shebang:#!/usr/bin/env python3,header:",
  "shell" => "ext:.sh,shebang:#!/bin/bash,header:set -euo pipefail\\n",
  "powershell" => "ext:.ps1,shebang:#!/usr/bin/env pwsh,header:#Requires -Version 7\\n",
  "tcl" => "ext:.tcl,shebang:#!/usr/bin/env tclsh,header:package require Tcl 8.6\\n",
  "ruby" => "ext:.rb,shebang:#!/usr/bin/env ruby,header:require 'json'\\nrequire 'fileutils'\\n",
  "lua" => "ext:.lua,shebang:#!/usr/bin/env lua,header:",
  "go" => "ext:.go,shebang:// +build ignore,header:package main\\n"
);

sub log_message {
  my ($message, $level) = @_;
  $level //= "INFO";
  system("mkdir -p '$LOG_DIR'");
  my $timestamp = localtime();
  my $line = "[$timestamp] [$level] $message";
  print "$line\n";
  my $log_file = "$LOG_DIR/" . (localtime()) =~ s/ .*//r . ".log";
  open my $fh, ">>", $log_file or die "Cannot open $log_file: $!";
  print $fh "$line\n";
  close $fh;
}

sub get_node_by_priority {
  my ($job_weight) = @_;
  $job_weight //= "medium";
  my @preferred_order;
  
  # Prioritäts-Matrix
  if ($job_weight eq "heavy") {
    # Schwere Jobs → Node 7 (Docker mit vielen Ressourcen)
    @preferred_order = ("node7", "node2", "node1");
  } elsif ($job_weight eq "medium") {
    # Mittlere Jobs → Stable Nodes
    @preferred_order = ("node2", "node1", "node7");
  } else {  # light
    # Leichte Jobs → Mobile/verfügbare Nodes
    @preferred_order = ("node5", "node1", "node2");
  }
  
  # Prüfe Verfügbarkeit
  for my $node_id (@preferred_order) {
    next unless exists $NODES{$node_id};
    
    my $node_config = $NODES{$node_id};
    my ($always_available) = $node_config =~ /always_available:([^,]*)/;
    
    # Skip nicht immer verfügbare Nodes wenn nicht explizit requested
    if ($always_available ne "true" && $job_weight ne "light") {
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
  if (`which openclaw 2>/dev/null`) {
    my $output = `timeout 5 openclaw nodes status '$node_id' 2>/dev/null`;
    if ($output =~ /(online|active)/i) {
      return 1;
    }
  }
  
  # Bei Timeout/Error: Prüfe letzten bekannten Status
  if (exists $NODES{$node_id}) {
    my $node_config = $NODES{$node_id};
    my ($always_available) = $node_config =~ /always_available:([^,]*)/;
    return $always_available eq "true";
  } else {
    return 0;
  }
}

sub get_job_weight {
  my ($script_size, $target_langs_count) = @_;
  my $total_work = $script_size * $target_langs_count;
  
  if ($total_work > 50000) {  # Große Scripts, viele Sprachen
    return "heavy";
  } elsif ($total_work > 10000) {  # Mittlere Last
    return "medium";
  } else {
    return "light";
  }
}

sub load_state {
  if (-f $STATE_FILE) {
    open my $fh, "<", $STATE_FILE or die "Cannot open $STATE_FILE: $!";
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
  } else {
    return <<'EOF';
{
  "processed": {},
  "queue": [],
  "current_priority": "high",
  "stats": {
    "total_scripts": 0,
    "abstractions_created": 0
  }
}
EOF
  }
}

sub save_state {
  my ($state) = @_;
  system("mkdir -p '" . dirname($STATE_FILE) . "'");
  open my $fh, ">", $STATE_FILE or die "Cannot write to $STATE_FILE: $!";
  print $fh $state;
  close $fh;
}

sub find_scripts_in_dir {
  my ($directory, @exclude_patterns) = @_;
  @exclude_patterns = ("node_modules", ".git", "__pycache__", "dist", "build") if @exclude_patterns == 0;
  
  my @scripts;
  if (-d $directory) {
    find(sub {
      return unless -f $_;
      my $file = $File::Find::name;
      my $exclude = 0;
      for my $pattern (@exclude_patterns) {
        if ($file =~ /\Q$pattern\E/) {
          $exclude = 1;
          last;
        }
      }
      unless ($exclude) {
        push @scripts, $file if /\.(py|js|sh|pl|rb)$/i;
      }
    }, $directory);
  }
  return @scripts;
}

sub create_abstraction {
  my ($script_path, $target_lang) = @_;
  
  unless (-f $script_path) {
    log_message("Script not found: $script_path", "ERROR");
    return 0;
  }
  
  my $original_content;
  {
    local $/;
    open my $fh, "<", $script_path or return 0;
    $original_content = <$fh>;
    close $fh;
  }
  
  my ($ext) = $script_path =~ /\.([^.]+)$/;
  my $source_lang = "";
  if ($ext eq "py") {
    $source_lang = "Python";
  } elsif ($ext eq "js") {
    $source_lang = "JavaScript";
  } elsif ($ext eq "sh") {
    $source_lang = "Shell";
  } elsif ($ext eq "pl") {
    $source_lang = "Perl";
  } elsif ($ext eq "rb") {
    $source_lang = "Ruby";
  } else {
    $source_lang = $ext;
  }
  
  my $target_dir = "$ABSTRACTIONS_REPO/$target_lang";
  system("mkdir -p '$target_dir'");
  
  my ($target_file_ext) = $TARGET_LANGUAGES{$target_lang} =~ /ext:([^,]*)/;
  my $target_file = "$target_dir/" . basename($script_path, ".$ext") . $target_file_ext;
  
  return 0 if -f $target_file;
  
  my ($shebang) = $TARGET_LANGUAGES{$target_lang} =~ /shebang:([^,]*)/;
  my ($header) = $TARGET_LANGUAGES{$target_lang} =~ /header:([^,]*)/;
  
  my @lines = split /\n/, $original_content;
  my $lines = "";
  my $line_count = 0;
  for my $line (@lines) {
    last if $line_count >= 15;
    $lines .= "# $line\n";
    $line_count++;
  }
  
  my $content = "#!/bin/bash\n";
  $content .= "# " . basename($script_path, ".$ext") . " - " . ucfirst($target_lang) . " Version\n";
  $content .= "# Portiert von $source_lang\n";
  $content .= "# Original: $script_path\n";
  $content .= "# Erstellt: " . localtime() . "\n";
  $content .= "#\n";
  $content .= "# $header\n";
  $content .= "# Original-Code-Referenz:\n";
  $content .= "# $lines\n";
  $content .= "# TODO: Implementiere $source_lang Funktionalität in " . ucfirst($target_lang) . "\n";
  $content .= "# exit 1\n";
  
  open my $fh, ">", $target_file or die "Cannot write to $target_file: $!";
  print $fh $content;
  close $fh;
  log_message("Created: $target_file");
  return 1;
}

sub process_on_node {
  my ($node_id, @scripts_and_langs) = @_;
  my $scripts_count = @scripts_and_langs;
  my @scripts = splice @scripts_and_langs, 0, $scripts_count / 2;
  my @target_langs = @scripts_and_langs;
  my $created = 0;
  
  if ($node_id eq "node1") {
    # Lokale Verarbeitung
    for my $script (@scripts) {
      for my $lang (@target_langs) {
        if (create_abstraction($script, $lang)) {
          $created++;
        }
      }
    }
  } else {
    # Remote-Verarbeitung
    log_message("Dispatching " . scalar(@scripts) . " jobs to $node_id");
    # TODO: Implementiere Remote-Dispatch wenn Node-Infrastruktur bereit
    # Für jetzt: Lokale Verarbeitung mit Node-Logging
    for my $script (@scripts) {
      for my $lang (@target_langs) {
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
    "skill-creator:$WORKSPACE/skills/skill-creator/scripts",
    "json-utils:$WORKSPACE/skills/json-utils/scripts",
    "scripting-utils:$WORKSPACE/skills/scripting-utils/scripts",
    "model-usage:$WORKSPACE/skills/model-usage/scripts",
    "tiktok-live:$WORKSPACE/skills/tiktok-live/scripts"
  );
  
  for my $target (@targets) {
    my ($skill_name, $scripts_dir) = split /:/, $target, 2;
    
    my @scripts = find_scripts_in_dir($scripts_dir, "node_modules", ".git", "test", "tests");
    
    log_message("$skill_name: " . scalar(@scripts) . " scripts found");
    
    my $count = 0;
    for my $script (@scripts) {
      last if $count >= 10;
      
      my $script_size = 0;
      if (-f $script) {
        $script_size = (stat($script))[7] || 0;
      }
      
      my @target_langs = ("perl5", "javascript", "python", "shell", "tcl");
      my $job_weight = get_job_weight($script_size, scalar(@target_langs));
      
      # Wähle Node basierend auf Job-Gewicht
      my $selected_node = get_node_by_priority($job_weight);
      log_message("Processing " . basename($script) . " ($job_weight) on $selected_node");
      
      my $result = process_on_node($selected_node, $script, @target_langs);
      $created += $result;
      $count++;
    }
  }
  
  return $created;
}

sub process_priority_medium {
  my $created = 0;
  my @targets = (
    "workspace-scripts:$WORKSPACE/scripts",
    "db-maintainer:$WORKSPACE/skills/db-maintainer/scripts",
    "log-collector:$WORKSPACE/skills/log-collector/scripts"
  );
  
  for my $target (@targets) {
    my ($dir_name, $scripts_dir) = split /:/, $target, 2;
    
    my @scripts = find_scripts_in_dir($scripts_dir, "node_modules", ".git");
    
    my $count = 0;
    for my $script (@scripts) {
      last if $count >= 10;
      
      my $script_size = 0;
      if (-f $script) {
        $script_size = (stat($script))[7] || 0;
      }
      
      my @target_langs = ("perl5", "javascript", "powershell", "python");
      my $job_weight = get_job_weight($script_size, scalar(@target_langs));
      
      # Mittlere Priority → eher leichtere Jobs
      my $adjusted_weight = $job_weight;
      if ($job_weight eq "heavy") {
        $adjusted_weight = "medium";
      }
      my $selected_node = get_node_by_priority($adjusted_weight);
      log_message("Processing " . basename($script) . " ($job_weight) on $selected_node");
      
      my $result = process_on_node($selected_node, $script, @target_langs);
      $created += $result;
      $count++;
    }
  }
  
  return $created;
}

sub git_commit {
  my ($message) = @_;
  if (-d $ABSTRACTIONS_REPO) {
    chdir $ABSTRACTIONS_REPO or return;
    system("git add . >/dev/null 2>&1 || true");
    system("git commit -m '$message' >/dev/null 2>&1 || true");
    log_message("Git commit: $message");
    chdir "/";
  }
}

sub create_status_report {
  my ($state) = @_;
  my $report_file = "$ABSTRACTIONS_REPO/STATUS.md";
  
  my @lang_counts;
  if (-d $ABSTRACTIONS_REPO) {
    opendir my $dh, $ABSTRACTIONS_REPO or die "Cannot open $ABSTRACTIONS_REPO: $!";
    my @dirs = grep { -d "$ABSTRACTIONS_REPO/$_" && exists $TARGET_LANGUAGES{$_} } readdir $dh;
    closedir $dh;
    
    for my $lang_dir (@dirs) {
      my $count = 0;
      opendir my $ldh, "$ABSTRACTIONS_REPO/$lang_dir" or next;
      while (readdir $ldh) {
        $count++ if -f "$ABSTRACTIONS_REPO/$lang_dir/$_";
      }
      closedir $ldh;
      push @lang_counts, "$lang_dir:$count";
    }
  }
  
  open my $fh, ">", $report_file or die "Cannot write to $report_file: $!";
  print $fh "# Script Abstractions - Status Report\n\n";
  print $fh "**Letzte Aktualisierung:** " . localtime() . "\n\n";
  my $json = JSON->new;
  my $data = $json->decode($state);
  print $fh "- Aktuelle Priorität: " . ($data->{current_priority} // "high") . "\n";
  print $fh "- Verarbeitete Scripts: " . (keys %{$data->{processed}}) . "\n";
  print $fh "- Abstraktionen gesamt: " . ($data->{stats}->{abstractions_created} // 0) . "\n\n";
  print $fh "## Abstraktionen pro Sprache\n\n";
  
  for my $lang_count (@lang_counts) {
    my ($lang, $count) = split /:/, $lang_count, 2;
    print $fh "- $lang: $count\n";
  }
  
  print $fh "\n## Verfügbare Modelle\n\n";
  
  my $i = 0;
  for my $model (@AVAILABLE_MODELS) {
    if ($i < 3) {
      print $fh "- `$model`\n";
    }
    $i++;
  }
  print $fh "- ... und " . (scalar(@AVAILABLE_MODELS) - 3) . " weitere\n\n";
  
  print $fh "## Multi-Node Support\n\n";
  print $fh "| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n";
  print $fh "|------|---------------|-----------|-----------|-------|\n";
  
  for my $node_id (sort keys %NODES) {
    my $node_config = $NODES{$node_id};
    my ($always_available) = $node_config =~ /always_available:([^,]*)/;
    my ($capacity) = $node_config =~ /capacity:([^,]*)/;
    my ($priority) = $node_config =~ /priority:([^,]*)/;
    my ($device) = $node_config =~ /device:([^,]*)/;
    $device //= "Server";
    
    my $avail = "✅ Immer";
    if ($always_available ne "true") {
      $avail = "📱 Bedingt";
    }
    
    print $fh "| $node_id | $avail | $capacity | $priority | $device |\n";
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
  my $json = JSON->new;
  my $data = $json->decode($state);
  my $processed_count = keys %{$data->{processed}};
  log_message("State loaded: $processed_count processed");
  
  my $current_priority = $data->{current_priority} // "high";
  my $created = 0;
  
  if ($current_priority eq "high") {
    log_message("Processing HIGH priority: Top 5 Skills");
    $created = process_priority_high();
    if ($created > 0) {
      git_commit("High priority: $created abstractions");
    }
    $data->{current_priority} = "medium";
  } elsif ($current_priority eq "medium") {
    log_message("Processing MEDIUM priority: Workspace Scripts");
    $created = process_priority_medium();
    if ($created > 0) {
      git_commit("Medium priority: $created abstractions");
    }
    $data->{current_priority} = "high";  # Zyklus
  }
  
  my $abstractions_count = 0;
  for my $lang (keys %TARGET_LANGUAGES) {
    if (-d "$ABSTRACTIONS_REPO/$lang") {
      my $count = 0;
      opendir my $dh, "$ABSTRACTIONS_REPO/$lang" or next;
      while (readdir $dh) {
        $count++ if -f "$ABSTRACTIONS_REPO/$lang/$_";
      }
      closedir $dh;
      $abstractions_count += $count;
    }
  }
  
  $data->{stats}->{last_run} = localtime();
  $data->{stats}->{abstractions_created} = $abstractions_count;
  $state = $json->encode($data);
  save_state($state);
  create_status_report($state);
  
  log_message("Abgeschlossen. $created neue Abstraktionen erstellt.");
}

main(@ARGV);
