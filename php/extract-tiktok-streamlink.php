<?php
// abstraction-provenance: {"artifact_sha256": "621cefe1ea6fb646762feccf525869ddae8ea649c44ed004dc6153b90b943a44", "source_sha256": "fecaa7522aec9008996f5664c745893f7fb7a2a4a3134a9f2855acde7f79596c", "target_language": "php"}
// extract-tiktok-streamlink.sh — portiert nach php
// Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-streamlink.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
// Bounded fallback used by the enhanced extractor. Output is normalized again
// by tiktok-get-stream.js; standalone success must remain URL-only unless
// --json is requested. Exit 75 means preflight overload.

$username = $argv[1] ?? '';
$quality = $argv[2] ?? 'best';
$jsonFlag = $argv[3] ?? '';
$timestamp = gmdate('Y-m-d\TH:i:s\Z');

function emit_json(...$values) {
    $keys = ["success", "method", "username", "url", "quality", "author", "title", "error", "timestamp", "status"];
    $payload = [];
    foreach ($keys as $index => $key) {
        if (isset($values[$index]) && $values[$index] !== "") {
            $payload[$key] = $values[$index];
        }
    }
    if (isset($payload["success"])) {
        $payload["success"] = strtolower($payload["success"]) === "true";
    }
    fwrite(STDERR, json_encode($payload, JSON_UNESCAPED_UNICODE) . "\n");
}

if (!preg_match('/^[A-Za-z0-9._]{1,24}$/', $username)) {
    fwrite(STDERR, "Invalid TikTok username\n");
    exit(64);
}

$validQualities = ['best', 'worst', 'original', '1080p60', '720p60', '720p', '540p', '360p', 'auto'];
if (!in_array($quality, $validQualities)) {
    fwrite(STDERR, "Invalid stream quality\n");
    exit(64);
}

$loadPerCpu = sys_getloadavg()[0] / max(1, substr_count(shell_exec('nproc'), "\n") ?: 1);
$maxLoad = getenv('TIKTOK_MAX_LOAD_PER_CPU') ?: 1.5;
if ($loadPerCpu > $maxLoad) {
    emit_json("false", "streamlink", $username, "", $quality, "", "", "host overloaded", $timestamp, "overloaded");
    exit(75);
}

if (!shell_exec('which streamlink')) {
    emit_json("false", "streamlink", $username, "", $quality, "", "", "streamlink not installed", $timestamp, "dependency_missing");
    exit(2);
}

$liveUrl = "https://www.tiktok.com/@{$username}/live";

$selectors = [
    'original' => 'origin,uhd_60,hd_60,hd,sd,ld,best,worst',
    'auto' => 'best,origin,uhd_60,hd_60,hd,sd,ld,worst',
    '1080p60' => 'uhd_60,hd_60,hd,sd,ld,worst',
    '720p60' => 'hd_60,hd,sd,ld,worst',
    '720p' => 'hd,sd,ld,worst',
    '540p' => 'sd,ld,worst',
    '360p' => 'ld,worst'
];

$selector = $selectors[$quality] ?? $quality;

$output = shell_exec("streamlink --json " . escapeshellarg($liveUrl) . " " . escapeshellarg($selector) . " 2>/dev/null");
$exitCode = $output === null ? 1 : 0;

if ($exitCode !== 0 || empty($output)) {
    $url = shell_exec("streamlink --stream-url " . escapeshellarg($liveUrl) . " " . escapeshellarg($selector) . " 2>/dev/null");
    if ($url === null || empty($url)) {
        emit_json("false", "streamlink", $username, "", $quality, "", "", "streamlink failed or no stream found", $timestamp, "offline");
        exit(1);
    }
    if ($jsonFlag === "--json") {
        emit_json("true", "streamlink", $username, trim($url), $quality, "", "", "", $timestamp, "live");
    } else {
        echo trim($url) . "\n";
    }
    exit(0);
}

$parsedData = json_decode($output, true);
if (json_last_error() !== JSON_ERROR_NONE) {
    emit_json("false", "streamlink", $username, "", $quality, "", "", "invalid streamlink JSON", $timestamp, "technical_error");
    exit(2);
}

$url = $parsedData['url'] ?? '';
$streams = $parsedData['streams'] ?? [];
if (!$url && is_array($streams)) {
    $searchKeys = array_merge(['best', 'worst'], array_keys($streams));
    foreach ($searchKeys as $key) {
        if (isset($streams[$key]['url'])) {
            $url = $streams[$key]['url'];
            break;
        }
    }
}
$metadata = $parsedData['metadata'] ?? [];
$author = $metadata['author'] ?? '';
$title = $metadata['title'] ?? '';

if (empty($url)) {
    emit_json("false", "streamlink", $username, "", $quality, $author, $title, "could not extract stream URL", $timestamp, "offline");
    exit(1);
}

if ($jsonFlag === "--json") {
    emit_json("true", "streamlink", $username, $url, $quality, $author, $title, "", $timestamp, "live");
} else {
    echo $url . "\n";
}
