<?php
// abstraction-provenance: {"artifact_sha256": "d46f1197e2a49c269d721e4ac9dee44056bdd5553faa6bac8eca80e64fda8eee", "source_sha256": "b339455e9e618c836ccf2e3732e4fec9897f079730d8814eadb716e2459df453", "target_language": "php"}
// frame.sh — portiert nach php
// Quelle: shell, OpenClaw@gateway1:skills/video-frames/scripts/frame.sh
// auch in: OpenClaw@gateway2:skills/video-frames/scripts/frame.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
function usage() {
    fwrite(STDERR, <<<EOF
Usage:
  frame.php <video-file> [--time HH:MM:SS] [--index N] --out /path/to/frame.jpg

Examples:
  frame.php video.mp4 --out /tmp/frame.jpg
  frame.php video.mp4 --time 00:00:10 --out /tmp/frame-10s.jpg
  frame.php video.mp4 --index 0 --out /tmp/frame0.png

EOF
    );
    exit(2);
}

function run($cmd) {
    $ret = 0;
    passthru($cmd, $ret);
    if ($ret !== 0) {
        exit($ret);
    }
}

if (!isset($argv[1]) || $argv[1] === '-h' || $argv[1] === '--help') {
    usage();
}

$in = $argv[1];
array_shift($argv);

$time = '';
$index = '';
$out = '';

$i = 1;
while ($i < count($argv)) {
    switch ($argv[$i]) {
        case '--time':
            $time = $argv[$i + 1] ?? '';
            $i += 2;
            break;
        case '--index':
            $index = $argv[$i + 1] ?? '';
            $i += 2;
            break;
        case '--out':
            $out = $argv[$i + 1] ?? '';
            $i += 2;
            break;
        default:
            fwrite(STDERR, "Unknown arg: {$argv[$i]}\n");
            usage();
    }
}

if (!file_exists($in)) {
    fwrite(STDERR, "File not found: $in\n");
    exit(1);
}

if ($out === '') {
    fwrite(STDERR, "Missing --out\n");
    usage();
}

$outDir = dirname($out);
if (!is_dir($outDir)) {
    mkdir($outDir, 0777, true);
}

if ($index !== '') {
    run("ffmpeg -hide_banner -loglevel error -y -i " . escapeshellarg($in) . " -vf \"select=eq(n\\,$index)\" -vframes 1 " . escapeshellarg($out));
} elseif ($time !== '') {
    run("ffmpeg -hide_banner -loglevel error -y -ss " . escapeshellarg($time) . " -i " . escapeshellarg($in) . " -frames:v 1 " . escapeshellarg($out));
} else {
    run("ffmpeg -hide_banner -loglevel error -y -i " . escapeshellarg($in) . " -vf \"select=eq(n\\,0)\" -vframes 1 " . escapeshellarg($out));
}

echo "$out\n";
