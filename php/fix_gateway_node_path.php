<?php
// abstraction-provenance: {"artifact_sha256": "dcd44efe4738b10f0ff24ceaf32edbf82f486526c93cfccdf79879aa4fb601fe", "source_sha256": "04518825207cd6ef771c2d840daf0a025f3144f4e384f1d13b46e016570f59df", "target_language": "php"}
// fix_gateway_node_path.sh — portiert nach php
// Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
// auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
// Backup der originalen Service-Datei
$timestamp = date('Ymd_His');
$backupFile = "/etc/systemd/system/openclaw-gateway.service.backup-{$timestamp}";
copy('/etc/systemd/system/openclaw-gateway.service', $backupFile);

// Korrektur des Node.js Pfads in der Service-Datei
// Annahme: Node.js ist unter /usr/bin/node verfügbar (wie von 'which node' gezeigt)
$file = '/etc/systemd/system/openclaw-gateway.service';
$content = file_get_contents($file);
$updatedContent = str_replace('/home/openclaw/.nvm/versions/node/v22.22.2/bin/node', '/usr/bin/node', $content);
file_put_contents($file, $updatedContent);

// Service neu laden und neu starten
exec('systemctl daemon-reload');
exec('systemctl restart openclaw-gateway');

// Status prüfen
exec('systemctl status openclaw-gateway --no-pager', $output, $returnCode);
foreach ($output as $line) {
    echo $line . PHP_EOL;
}

?>
