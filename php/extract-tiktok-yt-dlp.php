<?php
// abstraction-provenance: {"artifact_sha256": "73ee1995277a07dc5209674705787a0ef743b2d2cd3e92ee9352257a08e758de", "source_sha256": "b00f64d55d344bbcc351ae7ade12137f0d9293b556aa0881ede43bef5bcb778b", "target_language": "php"}
// extract-tiktok-yt-dlp.sh — portiert nach php
// Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
// Bounded fallback used by the enhanced extractor. Temporary files are cleaned
// on every exit and output is normalized again by tiktok-get-stream.js.
// Standalone overload exits 75 before yt-dlp starts.

function emit_json($success, $method, $username, $url, $format, $error, $timestamp, $status) {
    $keys = ["success", "method", "username", "url", "format", "error", "timestamp", "status"];
    $values = [$success, $method, $username, $url, $format, $error, $timestamp, $status];
    $payload = [];
    for ($i = 0; $i < count($keys); $i++) {
        if ($values[$i] !== "") {
            $payload[$keys[$i]] = $values[$i];
        }
    }
    if (isset($payload["success"])) {
        $payload["success"] = strtolower($payload["success"]) === "true";
    }
    echo json_encode($payload, JSON_UNESCAPED_UNICODE) . "\n";
}

function get_load_per_cpu() {
    $load = sys_getloadavg();
    $cpu_count = max(1, intval(shell_exec('nproc') ?: 1));
    return $load[0] / $cpu_count;
}

$username = $argv[1] ?? '';
if (str_starts_with($username, '@')) {
    $username = substr($username, 1);
}
$format = $argv[2] ?? 'best';
$json_flag = $argv[3] ?? '';
$timestamp = gmdate('Y-m-d\TH:i:s\Z');

$tmp_dir = tempnam(sys_get_temp_dir(), 'tiktok-yt-dlp.');
if (file_exists($tmp_dir)) {
    unlink($tmp_dir);
}
mkdir($tmp_dir);

register_shutdown_function(function() use ($tmp_dir) {
    if (is_dir($tmp_dir)) {
        array_map('unlink', glob("$tmp_dir/*"));
        rmdir($tmp_dir);
    }
});

if (!preg_match('/^[A-Za-z0-9._]{1,24}$/', $username)) {
    fwrite(STDERR, "Invalid TikTok username\n");
    exit(64);
}

$valid_formats = [
    'hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld',
    'hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld',
    'hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld',
    'hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld',
    'hls-sd/hls-ld/flv-sd/flv-ld',
    'hls-ld/flv-ld',
    'hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld'
];

if (!in_array($format, $valid_formats)) {
    fwrite(STDERR, "Invalid yt-dlp format\n");
    exit(64);
}

$load_per_cpu = get_load_per_cpu();
$max_load = getenv('TIKTOK_MAX_LOAD_PER_CPU') ?: '1.5';

if ($load_per_cpu > floatval($max_load)) {
    emit_json("false", "yt-dlp", $username, "", $format, "host overloaded", $timestamp, "overloaded");
    fwrite(STDERR, json_encode([
        "success" => false,
        "method" => "yt-dlp",
        "username" => $username,
        "url" => "",
        "format" => $format,
        "error" => "host overloaded",
        "timestamp" => $timestamp,
        "status" => "overloaded"
    ], JSON_UNESCAPED_UNICODE) . "\n");
    exit(75);
}

exec('command -v yt-dlp', $output, $return_var);
if ($return_var !== 0) {
    emit_json("false", "yt-dlp", $username, "", $format, "yt-dlp not installed", $timestamp, "dependency_missing");
    fwrite(STDERR, json_encode([
        "success" => false,
        "method" => "yt-dlp",
        "username" => $username,
        "url" => "",
        "format" => $format,
        "error" => "yt-dlp not installed",
        "timestamp" => $timestamp,
        "status" => "dependency_missing"
    ], JSON_UNESCAPED_UNICODE) . "\n");
    exit(2);
}

$live_url = "https://www.tiktok.com/@{$username}/live";
$stdout_file = "$tmp_dir/stdout.json";
$stderr_file = "$tmp_dir/stderr.log";

$cmd = "yt-dlp --no-warnings --dump-single-json --skip-download --format " . escapeshellarg($format) . " " . escapeshellarg($live_url) . " > " . escapeshellarg($stdout_file) . " 2> " . escapeshellarg($stderr_file);
$return_var = 0;
system($cmd, $return_var);

if ($return_var !== 0) {
    $stderr_content = file_get_contents($stderr_file);
    $status = "technical_error";
    $code = 2;
    if (preg_match('/not currently live|No live cdn found|not available|private video/i', $stderr_content)) {
        $status = "offline";
        $code = 1;
    }
    $error_message = substr($stderr_content, 0, 1000);
    emit_json("false", "yt-dlp", $username, "", $format, $error_message, $timestamp, $status);
    fwrite(STDERR, json_encode([
        "success" => false,
        "method" => "yt-dlp",
        "username" => $username,
        "url" => "",
        "format" => $format,
        "error" => $error_message,
        "timestamp" => $timestamp,
        "status" => $status
    ], JSON_UNESCAPED_UNICODE) . "\n");
    exit($code);
}

$url = "";
$json_content = file_get_contents($stdout_file);
if ($json_content !== false) {
    $data = json_decode($json_content, true);
    $candidates = [];

    if (isset($data['url']) && is_string($data['url'])) {
        $candidates[] = $data['url'];
    }

    if (isset($data['formats']) && is_array($data['formats'])) {
        foreach ($data['formats'] as $item) {
            if (isset($item['url']) && is_string($item['url'])) {
                $candidates[] = $item['url'];
            }
        }
    }

    foreach ($candidates as $value) {
        $low = strtolower($value);
        if (str_starts_with($value, "https://") && (strpos($low, ".m3u8") !== false || strpos($low, ".flv") !== false) && strpos($low, "only_audio=1") === false) {
            $url = $value;
            break;
        }
    }
}

if (empty($url)) {
    emit_json("false", "yt-dlp", $username, "", $format, "could not extract HTTPS video URL", $timestamp, "offline");
    fwrite(STDERR, json_encode([
        "success" => false,
        "method" => "yt-dlp",
        "username" => $username,
        "url" => "",
        "format" => $format,
        "error" => "could not extract HTTPS video URL",
        "timestamp" => $timestamp,
        "status" => "offline"
    ], JSON_UNESCAPED_UNICODE) . "\n");
    exit(1);
}

if ($json_flag === "--json") {
    emit_json("true", "yt-dlp", $username, $url, $format, "", $timestamp, "live");
} else {
    echo "$url\n";
}
?>
