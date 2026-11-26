<?php
// abstraction-provenance: {"artifact_sha256": "300d17c557f94f6f5da3dbde7b82cfff7a8640c163717edc97a525d8607a0fca", "source_sha256": "4112b3dbe78c8a495b73f6feaebe05ada553911d2e25f6bd1e2e4d704a6ac1b6", "target_language": "php"}
// generate-elevenlabs.mjs — portiert nach php
// Quelle: javascript, Onboarding@main:scripts/generate-elevenlabs.mjs
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
$key = $_ENV['ELEVENLABS_API_KEY'] ?? null;
$voiceId = $_ENV['ELEVENLABS_VOICE_ID'] ?? "JBFqnCBsd6RMkjVDRZzb";

if (!$key) {
    throw new Exception("ELEVENLABS_API_KEY fehlt.");
}

$text = "Neun Projekte. Zwei Plattformen. Ein Ort, an dem Ideen verbunden und weiterentwickelt werden.";

$url = "https://api.elevenlabs.io/v1/text-to-speech/{$voiceId}?output_format=mp3_44100_128";

$data = json_encode([
    "text" => $text,
    "model_id" => "eleven_multilingual_v2",
    "voice_settings" => [
        "stability" => 0.58,
        "similarity_boost" => 0.72,
        "style" => 0.18,
        "use_speaker_boost" => true
    ]
]);

$context = stream_context_create([
    "http" => [
        "method" => "POST",
        "header" => [
            "xi-api-key: {$key}",
            "Content-Type: application/json"
        ],
        "content" => $data
    ]
]);

$response = file_get_contents($url, false, $context);

if ($response === false) {
    throw new Exception("ElevenLabs fehlgeschlagen: " . error_get_last()['message']);
}

$http_response_header_array = http_parse_headers(implode("\r\n", $http_response_header));
$response_info = [
    'status' => (int) explode(' ', $http_response_header[0])[1]
];

if ($response_info['status'] < 200 || $response_info['status'] >= 300) {
    throw new Exception("ElevenLabs fehlgeschlagen: {$response_info['status']}");
}

$baseDir = __DIR__;

$audioDir = $baseDir . "/../public/audio/";
if (!is_dir($audioDir)) {
    mkdir($audioDir, 0777, true);
}

file_put_contents($audioDir . "project-narration.mp3", $response);

$resultData = json_encode([
    "model" => "eleven_multilingual_v2",
    "voiceId" => $voiceId,
    "characters" => strlen($text),
    "text" => $text,
    "output" => "public/audio/project-narration.mp3"
], JSON_PRETTY_PRINT);

file_put_contents($baseDir . "/../media-production/elevenlabs-result.json", $resultData);

echo "ElevenLabs abgeschlossen: " . strlen($text) . " Zeichen.\n";

function http_parse_headers($raw_headers) {
    $headers = [];
    foreach (explode("\r\n", $raw_headers) as $header) {
        $parts = explode(':', $header, 2);
        if (count($parts) === 2) {
            $headers[trim($parts[0])] = trim($parts[1]);
        }
    }
    return $headers;
}
?>
