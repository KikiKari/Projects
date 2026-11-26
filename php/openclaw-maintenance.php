<?php
// abstraction-provenance: {"artifact_sha256": "3524bc79835c4bff97f3e734d544db2818f1150be5b281f4064ce2cdbd800ab9", "source_sha256": "2a9ca592fdc915cfb281aa77dde9f07ffd3de83ce5abb8d87c77d46668d75dd6", "target_language": "php"}
// openclaw-maintenance.sh — portiert nach php
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
// === 1. Service-/Config-Drift ===
echo "=== 1. Service-/Config-Drift ===\n";
passthru('openclaw doctor', $return_code);
if ($return_code !== 0) {
    exit($return_code);
}

// === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===
echo "\n=== 2. Plugin-Stage ===\n";
passthru('openclaw plugins registry --refresh', $return_code);
if ($return_code !== 0) {
    exit($return_code);
}

passthru('openclaw plugins update --all', $return_code);
if ($return_code !== 0) {
    exit($return_code);
}

// === 3. Tasks ===
echo "\n=== 3. Tasks ===\n";
passthru('openclaw tasks maintenance --apply', $return_code);
if ($return_code !== 0) {
    exit($return_code);
}

// === 4. Sessions – alle Agents auf einmal ===
echo "\n=== 4. Sessions ===\n";
passthru('openclaw sessions cleanup --enforce --all-agents', $return_code);
if ($return_code !== 0) {
    exit($return_code);
}

// === 5. Memory – status/index decken alle Agents ab ===
echo "\n=== 5. Memory Status/Index ===\n";
passthru('openclaw memory status --deep --fix', $return_code);
if ($return_code !== 0) {
    exit($return_code);
}

passthru('openclaw memory index --force', $return_code);
if ($return_code !== 0) {
    exit($return_code);
}

// === 6. Memory promote – MUSS pro Agent ===
echo "\n=== 6. Memory Promote ===\n";
$agents = ['main', 'knecht', 'docs', 'ops-hub', 'cron'];
foreach ($agents as $agent) {
    echo "Promoting agent: $agent\n";
    passthru("openclaw memory promote --apply --agent " . escapeshellarg($agent), $return_code);
    if ($return_code !== 0) {
        exit($return_code);
    }
}

// === 7. Secrets ===
echo "\n=== 7. Secrets ===\n";
passthru('openclaw secrets reload', $return_code);
if ($return_code !== 0) {
    exit($return_code);
}

echo "\nMaintenance completed successfully.\n";
?>
