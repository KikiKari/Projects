<?php
// abstraction-provenance: {"artifact_sha256": "d65ca313de506ce3660f9e82b7250c30a4041f1394950a28b3e11ecef1413fcb", "source_sha256": "5aa602a80e57cbc63f54485d4cd66e205c54bd9f32bc03434218ff9bd388b3ab", "target_language": "php"}
// collect_compare_bundle.sh — portiert nach php
// Quelle: shell, OpenClaw@gateway1:scripts/collect_compare_bundle.sh
// auch in: OpenClaw@gateway2:scripts/collect_compare_bundle.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
$ROOT = "/home/openclaw/.openclaw";
$OUT_DIR = $ROOT . "/workspace/vscode/compare";
$TRANSFER_DIR = $OUT_DIR . "/transfer";
$MD_FILE = $OUT_DIR . "/local-gateway-config.md";
$TREE_FILE = $OUT_DIR . "/tree.txt";
$BACKUP_FILE = "/home/openclaw/openclaw-backup.tar.gz";

date_default_timezone_set('UTC');
$NOW_UTC = gmdate('Y-m-d\TH:i:s\Z');
$NOW_LOCAL = date('Y-m-d H:i:s T');
$HOST = gethostname();

$OPENCLAW_JSON = $ROOT . "/openclaw.json";
$EXEC_APPROVALS_JSON = $ROOT . "/exec-approvals.json";
$GATEWAY_SYSTEMD_ENV = $ROOT . "/gateway.systemd.env";
$DOT_ENV = $ROOT . "/.env";
$CONFIG_DIR = $ROOT . "/.config";
$AGENTS_DIR = $ROOT . "/agents";

if (!file_exists($OUT_DIR)) {
    mkdir($OUT_DIR, 0777, true);
}
if (!file_exists($TRANSFER_DIR)) {
    mkdir($TRANSFER_DIR, 0777, true);
}

function append_file_verbatim($label, $path, $lang = "text") {
    global $MD_FILE;
    $content = "\n## " . $label . "\n\nPfad: `" . $path . "`\n\n```" . $lang . "\n";
    if (file_exists($path)) {
        $content .= file_get_contents($path);
    } else {
        $content .= "[FEHLT] " . $path;
    }
    $content .= "\n```\n";
    file_put_contents($MD_FILE, $content, FILE_APPEND);
}

function append_env_verbatim() {
    global $MD_FILE;
    $content = "\n## Umgebungsvariablen (env)\n\n```\ntext\n";
    foreach ($_ENV as $key => $value) {
        $content .= $key . "=" . $value . "\n";
    }
    $content .= "```\n";
    file_put_contents($MD_FILE, $content, FILE_APPEND);
}

function append_dir_files_verbatim($section, $dir) {
    global $MD_FILE;
    $content = "\n## " . $section . "\n\n";
    if (!is_dir($dir)) {
        $content .= "[FEHLT] " . $dir . "\n";
        file_put_contents($MD_FILE, $content, FILE_APPEND);
        return;
    }
    $content .= "Basisverzeichnis: `" . $dir . "`\n";
    file_put_contents($MD_FILE, $content, FILE_APPEND);

    $iterator = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($dir));
    $files = [];
    foreach ($iterator as $file) {
        if ($file->isFile()) {
            $files[] = $file->getPathname();
        }
    }
    sort($files);

    foreach ($files as $f) {
        $fileContent = "\n### Datei: `" . $f . "`\n\n```\ntext\n" . file_get_contents($f) . "\n```\n";
        file_put_contents($MD_FILE, $fileContent, FILE_APPEND);
    }
}

$initial_content = "# Lokaler Gateway-Konfigurationsstand\n\nGeneriert: " . $NOW_LOCAL . "\nUTC: " . $NOW_UTC . "\nHost: " . $HOST . "\n\nDiese Datei enthaelt den lokalen Stand mit unveraenderten Inhalten.\n";
file_put_contents($MD_FILE, $initial_content);

append_file_verbatim("openclaw.json", $OPENCLAW_JSON, "json");
append_file_verbatim("exec-approvals.json", $EXEC_APPROVALS_JSON, "json");
append_file_verbatim("gateway.systemd.env", $GATEWAY_SYSTEMD_ENV, "dotenv");
append_file_verbatim(".env", $DOT_ENV, "dotenv");
append_env_verbatim();
append_dir_files_verbatim(".config (alle Dateien rekursiv)", $CONFIG_DIR);
append_dir_files_verbatim("agents (alle Dateien rekursiv)", $AGENTS_DIR);

// Baumstruktur erzeugen
exec("tree -a -L 6 " . escapeshellarg($ROOT), $tree_output, $tree_result);
if ($tree_result === 0) {
    file_put_contents($TREE_FILE, implode("\n", $tree_output) . "\n");
} else {
    file_put_contents($TREE_FILE, "Fehler beim Ausführen von 'tree'.\n");
}

// Backup erstellen
exec("openclaw backup create --output " . escapeshellarg($BACKUP_FILE) . " --verify", $backup_output, $backup_result);
if ($backup_result === 0 && file_exists($BACKUP_FILE)) {
    copy($BACKUP_FILE, $OUT_DIR . "/" . basename($BACKUP_FILE));
} else {
    file_put_contents($MD_FILE, "\n[FEHLER] Backup konnte nicht erstellt werden.\n", FILE_APPEND);
}

echo "OK\n";
echo "Erzeugt:\n";
echo "- " . $MD_FILE . "\n";
echo "- " . $TREE_FILE . "\n";
echo "- " . $BACKUP_FILE . "\n";
echo "- " . $TRANSFER_DIR . " (leer)\n";
