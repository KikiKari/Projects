<?php
// abstraction-provenance: {"artifact_sha256": "03474e3213a17c108b3fab23b76553991159b3381cc0d5348a7fec5c616ced1a", "source_sha256": "3fed8b6be2b9b8639b55bcaf18c09c0395ac005ab02c27f2dff26ca20b5d5825", "target_language": "php"}
// generate-wavespeed.mjs — portiert nach php
// Quelle: javascript, Onboarding@main:scripts/generate-wavespeed.mjs
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
$key = getenv('WAVESPEED_API_KEY');
if (!$key) throw new Exception("WAVESPEED_API_KEY fehlt.");

$jobs = json_decode(file_get_contents(__DIR__ . '/../media-production/wavespeed-jobs.json'), true);
$rawDir = __DIR__ . '/../media-production/raw/';
$publicDir = __DIR__ . '/../public/media/';
@mkdir($rawDir, 0777, true);
@mkdir($publicDir, 0777, true);

$resultUrl = __DIR__ . '/../media-production/wavespeed-results.json';
$log = file_exists($resultUrl) ? json_decode(file_get_contents($resultUrl), true) : [];

foreach ($jobs as $job) {
  $rawPath = $rawDir . $job['id'] . '.png';
  $targetPath = $publicDir . $job['output'] . '.png';
  $alreadyGenerated = file_exists($rawPath);
  
  if ($alreadyGenerated) {
    $found = false;
    foreach ($log as $entry) {
      if ($entry['id'] === $job['id']) {
        $found = true;
        break;
      }
    }
    if (!$found) {
      $log[] = [
        'id' => $job['id'],
        'requestId' => 'completed-before-resume',
        'model' => 'google/nano-banana-2/edit',
        'resolution' => '4k',
        'plannedCostUsd' => 0.14,
        'output' => basename($targetPath)
      ];
      file_put_contents($resultUrl, json_encode($log, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
    }
    echo "Übersprungen: {$job['id']} ist bereits vorhanden.\n";
    continue;
  }

  $images = [];
  foreach ($job['images'] as $image) {
    if (preg_match('/^https?:|^data:/', $image)) {
      $images[] = $image;
    } else {
      $bytes = file_get_contents(__DIR__ . '/../' . $image);
      $images[] = 'data:image/png;base64,' . base64_encode($bytes);
    }
  }

  $context = stream_context_create([
    'http' => [
      'method' => 'POST',
      'header' => [
        'Authorization: Bearer ' . $key,
        'Content-Type: application/json'
      ],
      'content' => json_encode([
        'prompt' => $job['prompt'],
        'images' => $images,
        'aspect_ratio' => $job['aspectRatio'],
        'resolution' => '4k',
        'output_format' => 'png',
        'enable_web_search' => false,
        'enable_image_search' => false,
        'enable_sync_mode' => false,
        'enable_base64_output' => false,
      ])
    ]
  ]);

  $response = file_get_contents('https://api.wavespeed.ai/api/v3/google/nano-banana-2/edit', false, $context);
  $http_response_header_array = $http_response_header;
  $status_line = $http_response_header_array[0];
  preg_match('/HTTP\/\d\.\d\s+(\d+)/', $status_line, $matches);
  $status_code = intval($matches[1] ?? 0);

  if ($status_code < 200 || $status_code >= 300) {
    throw new Exception("WaveSpeed submit fehlgeschlagen: $status_code $response");
  }

  $submitted = json_decode($response, true);
  $requestId = $submitted['data']['id'] ?? $submitted['id'];

  $result = null;
  for ($attempt = 0; $attempt < 90; $attempt++) {
    sleep(4);
    $pollContext = stream_context_create([
      'http' => [
        'header' => 'Authorization: Bearer ' . $key
      ]
    ]);
    $pollResponse = file_get_contents("https://api.wavespeed.ai/api/v3/predictions/$requestId/result", false, $pollContext);
    $result = json_decode($pollResponse, true);
    if ($result['data']['status'] === 'completed') break;
    if ($result['data']['status'] === 'failed') throw new Exception("WaveSpeed job fehlgeschlagen: {$job['id']}");
  }

  $url = $result['data']['outputs'][0] ?? null;
  if (!$url) throw new Exception("Kein Output für {$job['id']}");

  $imageData = file_get_contents($url);
  file_put_contents($rawPath, $imageData);
  file_put_Contents($targetPath, $imageData);

  $log[] = [
    'id' => $job['id'],
    'requestId' => $requestId,
    'model' => 'google/nano-banana-2/edit',
    'resolution' => '4k',
    'plannedCostUsd' => 0.14,
    'output' => basename($targetPath)
  ];

  file_put_contents($resultUrl, json_encode($log, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
  echo "Abgeschlossen: {$job['id']}\n";
}

file_put_contents($resultUrl, json_encode($log, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
echo "WaveSpeed abgeschlossen: " . count($log) . " Assets, geplante Basiskosten $" . number_format(count($log) * 0.14, 2) . ".\n";
