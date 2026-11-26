<?php
// abstraction-provenance: {"artifact_sha256": "5201d2bee751cac9efc932477b0cf3517c8acf6822800bd8bee9172cdc5fe0be", "source_sha256": "a77f5c2629fe7fafac268cfbf2f0b3e77a194322aee8f9c06967eb6c33db043e", "target_language": "php"}
// openclaw-maintenance.sh — portiert nach php
// Quelle: shell, OpenClaw@gateway2:scripts/openclaw-maintenance.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
$openclaw_bin = getenv('OPENCLAW_BIN') ?: $_SERVER['HOME'] . '/.local/bin/openclaw';

if (!file_exists($openclaw_bin) || !is_executable($openclaw_bin)) {
    fwrite(STDERR, "ERROR: OpenClaw binary not found: $openclaw_bin\n");
    exit(1);
}

echo "Using OpenClaw: " . shell_exec("$openclaw_bin --version") . "\n";

// === 1. Service-/Config-Drift ===
echo shell_exec("$openclaw_bin doctor");

// === 2. Plugin-Stage (Registry refresh only; updates are explicit/manual) ===
echo shell_exec("$openclaw_bin plugins registry --refresh");

$run_plugin_update = getenv('RUN_PLUGIN_UPDATE') ?: '0';
if ($run_plugin_update === '1') {
    echo shell_exec("$openclaw_bin plugins update --all");
} else {
    echo "Skipping plugin update. Run with RUN_PLUGIN_UPDATE=1 to enable.\n";
}

// === 3. Tasks ===
echo shell_exec("$openclaw_bin tasks maintenance --apply");

// === 4. Sessions – alle Agents auf einmal ===
echo shell_exec("$openclaw_bin sessions cleanup --enforce --all-agents");

// === 5. Memory – status/index decken alle Agents ab ===
echo shell_exec("$openclaw_bin memory status --deep --fix");
echo shell_exec("$openclaw_bin memory index --force");

// === 6. Memory promote – MUSS pro Agent ===
$agents = ['main', 'knecht', 'docs', 'ops-hub', 'cron'];
foreach ($agents as $agent) {
    echo shell_exec("$openclaw_bin memory promote --apply --agent " . escapeshellarg($agent));
}

// === 7. Secrets ===
echo shell_exec("$openclaw_bin secrets reload");
