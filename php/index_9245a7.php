<?php
// abstraction-provenance: {"artifact_sha256": "b11cd289eeb1144c23be4abacc1f08e964b32b30fc7be96df5f8a43a062517c0", "source_sha256": "9245a78489adb3949ae2a56f5e0987a465142b9a8ee97bddaca453f5011daef8", "target_language": "php"}
// index.html — portiert nach php
// Quelle: html, Projects@Program-Derivation:public/index.html
// auch in: Projects@Vision-Check:public/index.html
// auch in: Projects@Weather-Check:public/index.html
// auch in: Projects@abstractions:public/index.html
// auch in: 5 weiteren Fundstellen
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
function generateIndexHtml($filename = 'index.html') {
    $html = <<<HTML
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="refresh" content="0; url=3d.html">
<title>Weiterleitung zur 3D-Ansicht</title>
<link rel="canonical" href="3d.html">
<script>location.replace('3d.html');</script>
</head>
<body>
<p><a href="3d.html">3D-Ansicht öffnen</a></p>
</body>
</html>
HTML;

    file_put_contents($filename, $html);
    return $html;
}

// Wenn das Skript direkt aufgerufen wird, generiere die Datei
if (basename(__FILE__) == basename($_SERVER['SCRIPT_NAME'])) {
    generateIndexHtml();
}
?>
