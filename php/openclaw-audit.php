<?php
// abstraction-provenance: {"artifact_sha256": "3aaa3b993fdbca0ae9ca849a12ee2d354542af8c0b5f213eb9650399fd08e5df", "source_sha256": "e51b94641336291974fe14bf4bb7299a75ec7dcce49e1d413282c8043e9f09f1", "target_language": "php"}
// openclaw-audit.sh — portiert nach php
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-audit.sh
// auch in: OpenClaw@gateway2:scripts/openclaw-audit.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
// OpenClaw read-only audit/diagnostic sweep
// Output: openclaw-audit-YYYY-MM-DD.log im selben Verzeichnis wie dieses Script

$scriptDir = dirname(__FILE__);
$dateStamp = date('Y-m-d');
$out = "{$scriptDir}/openclaw-audit-{$dateStamp}.log";

$oc = ['openclaw', '--no-color'];

file_put_contents($out, implode("\n", [
  "================================================================",
  "OpenClaw audit run",
  "Started:  " . date('c'),
  "Host:     " . gethostname(),
  "User:     " . get_current_user(),
  "Version:  " . (shell_exec('openclaw --version 2>/dev/null') ?: 'unknown'),
  "Output:   {$out}",
  "================================================================"
]) . "\n");

function run_cmd($title, $cmd) {
  global $out;
  $output = [];
  $returnCode = 0;
  
  $cmdStr = is_array($cmd) ? implode(' ', array_map('escapeshellarg', $cmd)) : $cmd;
  
  exec("{$cmdStr} 2>&1", $output, $returnCode);
  
  $log = [
    "",
    "----------------------------------------------------------------",
    "### {$title}",
    "### \$ {$cmdStr}",
    "### " . date('c'),
    "----------------------------------------------------------------"
  ];
  
  $log = array_merge($log, $output);
  $log[] = "[exit: {$returnCode}]";
  
  file_put_contents($out, implode("\n", $log) . "\n", FILE_APPEND);
}

run_cmd("tasks audit --severity error", array_merge($oc, ['tasks', 'audit', '--severity', 'error']));
run_cmd("secrets audit", array_merge($oc, ['secrets', 'audit']));
run_cmd("security audit", array_merge($oc, ['security', 'audit']));
run_cmd("plugins doctor", array_merge($oc, ['plugins', 'doctor']));
run_cmd("plugins deps", array_merge($oc, ['plugins', 'deps']));
run_cmd("plugins registry", array_merge($oc, ['plugins', 'registry']));
run_cmd("skills check", array_merge($oc, ['skills', 'check']));
run_cmd("hooks check", array_merge($oc, ['hooks', 'check']));
run_cmd("gateway status --deep", array_merge($oc, ['gateway', 'status', '--deep']));
run_cmd("channels status --probe", array_merge($oc, ['channels', 'status', '--probe']));
run_cmd("memory status --deep", array_merge($oc, ['memory', 'status', '--deep']));
run_cmd("sessions --all-agents", array_merge($oc, ['sessions', '--all-agents']));
run_cmd("tasks list", array_merge($oc, ['tasks', 'list']));
run_cmd("cron list", array_merge($oc, ['cron', 'list']));

file_put_contents($out, implode("\n", [
  "",
  "================================================================",
  "Audit complete: " . date('c'),
  "================================================================"
]) . "\n", FILE_APPEND);

echo "Audit complete. Output: {$out}\n";
?>
