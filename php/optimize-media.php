<?php
// abstraction-provenance: {"artifact_sha256": "19fd4264f05811b124e38c5749de31776325ca8cbc9066e58c1a22a962e3df7c", "source_sha256": "01865e120d0e52b50fea21a5f976ac63af413e6829f861a5d31d7898bd4dbaf4", "target_language": "php"}
// optimize-media.mjs — portiert nach php
// Quelle: javascript, Onboarding@main:scripts/optimize-media.mjs
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
$directory = __DIR__ . "/../public/media/";

$files = scandir($directory);

foreach ($files as $file) {
    if (!str_ends_with($file, ".png")) continue;
    
    $source = $directory . $file;
    $stem = pathinfo($file, PATHINFO_FILENAME);
    
    // Erzeuge WebP
    $webpImage = imagecreatefrompng($source);
    imagewebp($webpImage, $directory . $stem . ".webp", 84);
    imagedestroy($webpImage);
    
    // Erzeuge AVIF (falls verfügbar)
    if (function_exists('imageavif')) {
        $avifImage = imagecreatefrompng($source);
        imageavif($avifImage, $directory . $stem . ".avif", 58);
        imagedestroy($avifImage);
    }
}

echo "WebP- und AVIF-Derivate erzeugt.\n";

?>
