#!/usr/bin/env pwsh
# test_external_speech_filter.cjs — portiert nach powershell
# Quelle: javascript, Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/scripts/test_external_speech_filter.cjs
# Erzeugt: 2026-10-25 durch ABSTRACTIONS_MANAGER.py

# Führe Tests für die Funktion shouldFilterExternalSpeechTrigger aus der Datei content-core.js durch
# Die Funktion prüft, ob ein Text mit einem Punkt beginnt und externe Spracherkennung gefiltert werden soll

# Lade das Node.js Modul content-core.js über einen temporären Umweg
# In PowerShell können wir CommonJS Module nicht direkt laden, daher verwenden wir node zur Evaluierung
$scriptPath = Join-Path $PSScriptRoot "../browser-extension/content-core.js"
$functionCode = Get-Content -Path $scriptPath -Raw
# Extrahiere die Funktion shouldFilterExternalSpeechTrigger aus dem Modul
$extractedFunction = node -e @"
const module = { exports: {} };
(function() {
  $functionCode
})();
console.log(module.exports.shouldFilterExternalSpeechTrigger.toString());
"@

# Definiere Testfälle
$testCases = @()
foreach ($enabled in @($false, $true)) {
    foreach ($text in @('.Text', '. Text', '  .Text', "`t`n. Text", 'Normal', 'Ein Satz. Noch einer', '')) {
        $expected = $enabled -and $text.TrimStart().StartsWith('.')
        $testCase = @{
            description = "{enabled:$enabled,text:'$text'}"
            text = $text
            enabled = $enabled
            expected = $expected
        }
        $testCases += $testCase
    }
}

# Führe Tests durch
$passedTests = 0
$totalTests = $testCases.Count

foreach ($testCase in $testCases) {
    # Evaluiere die Funktion mit den aktuellen Parametern
    $result = node -e @"
const shouldFilterExternalSpeechTrigger = $extractedFunction;
console.log(shouldFilterExternalSpeechTrigger('$($testCase.text)', $($testCase.enabled)));
"@
    
    $actualResult = [bool]::Parse($result.Trim())
    $expectedResult = $testCase.expected
    
    if ($actualResult -eq $expectedResult) {
        Write-Host "✓ Test passed: $($testCase.description)" -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "✗ Test failed: $($testCase.description). Expected: $expectedResult, Got: $actualResult" -ForegroundColor Red
    }
}

Write-Host "`n$passedTests/$totalTests tests passed"

if ($passedTests -ne $totalTests) {
    exit 1
}
