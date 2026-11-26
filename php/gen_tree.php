<?php
// abstraction-provenance: {"artifact_sha256": "2edc8d1a7bbabcff8fe9b3b1119e85880e701bd78c9ccbccb17c4d847971a810", "source_sha256": "0a55a33f11db266892b50c887fd8d01783f387e3072c8c5b9ed86ca6788a8c52", "target_language": "php"}
// gen_tree.py — portiert nach php
// Quelle: python, OpenClaw@gateway2:scripts/gen_tree.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Replicates `tree -a -L 6` output for /workspace into important/openclaw-tree.txt
 * (used because the `tree` binary is unavailable in this sandbox).
 */

$ROOT = "/workspace";
$OUT = "/workspace/important/openclaw-tree.txt";
$MAX_DEPTH = 6;

function collect($path, $prefix = "", $depth = 1) {
    $lines = [];
    try {
        $entries = scandir($path);
        // Entferne . und .. aus der Liste
        $entries = array_diff($entries, ['.', '..']);
        sort($entries);
    } catch (Exception $e) {
        return $lines;
    }
    
    $total = count($entries);
    $i = 0;
    foreach ($entries as $name) {
        $is_last = ($i == $total - 1);
        $connector = $is_last ? "└── " : "├── ";
        $lines[] = $prefix . $connector . $name;
        $full = $path . "/" . $name;
        
        if ($depth < $GLOBALS['MAX_DEPTH'] && is_dir($full) && !is_link($full)) {
            $next_prefix = $prefix . ($is_last ? "    " : "│   ");
            $lines = array_merge($lines, collect($full, $next_prefix, $depth + 1));
        }
        $i++;
    }
    return $lines;
}

$body = collect($ROOT);
$header = 
    "# OpenClaw Workspace Tree\n" .
    "# Generiert: " . date('c') . "\n" .
    "# Befehl: tree -a -L 6 " . $ROOT . " (emuliert via gen_tree.php)\n" .
    "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n";

$content = $header . ".\n" . implode("\n", $body) . "\n";

file_put_contents($OUT, $content);

echo "written " . $OUT . ": " . (count($body) + 1) . " lines, " . strlen($content) . " bytes\n";
?>
