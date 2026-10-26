#!/usr/bin/env pwsh
# test_external_speech_filter.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_external_speech_filter.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_external_speech_filter.cjs
# Erzeugt: 2026-10-26 durch ABSTRACTIONS_MANAGER.py

# Import necessary modules or define functions if they don't exist
# Since PowerShell doesn't have direct equivalents to Node.js's assert module,
# we'll create simple assertion functions for our use case.

function Assert-Equal {
    param (
        [Parameter(Mandatory=$true)]
        $Expected,
        [Parameter(Mandatory=$true)]
        $Actual,
        [Parameter(Mandatory=$false)]
        [string]$Message = "Assertion failed"
    )
    if ($Expected -ne $Actual) {
        throw "$Message : Expected '$Expected', but got '$Actual'"
    }
}

# Mocking the required functions from content-core.js
# These need to be implemented according to their original behavior

function Test-ShouldFilterExternalSpeechTrigger {
    param (
        [string]$text,
        [bool]$enabled,
        [string]$prefixes = '.'
    )

    # Implement logic based on original JavaScript function
    if (-not $enabled) {
        return $false
    }

    $trimmedText = $text.TrimStart()
    foreach ($char in $prefixes.ToCharArray()) {
        if ($trimmedText.StartsWith($char)) {
            return $true
        }
    }
    return $false
}

function Normalize-ExternalSpeechTriggerCharacters {
    param (
        [string]$input
    )

    # If input is undefined/null/empty, return default character
    if ([string]::IsNullOrWhiteSpace($input)) {
        if ($null -eq $input) {
            return "."
        }
        return ""
    }

    # Define allowed characters (Unicode scalars up to U+1F644)
    $allowedChars = ".`,;-;:"
    # Add Unicode emojis from U+1F600 to U+1F644 (limited range for simplicity)
    for ($i = 0x1F600; $i -le 0x1F644; $i++) {
        $allowedChars += [char]::ConvertFromUtf32($i)
    }

    # Filter only allowed characters
    $result = ""
    foreach ($c in $input.ToCharArray()) {
        if ($allowedChars.Contains($c)) {
            $result += $c
        }
    }

    # Limit to first 5 unique characters (as per original implementation)
    $uniqueResult = ""
    $seen = @{}
    foreach ($c in $result.ToCharArray()) {
        if (-not $seen.ContainsKey($c)) {
            $seen[$c] = $true
            $uniqueResult += $c
            if ($uniqueResult.Length -ge 5) {
                break
            }
        }
    }

    return $uniqueResult
}

# Main test cases
foreach ($enabled in @($false, $true)) {
    foreach ($text in @(".Text", ". Text", "  .Text", "`t`n. Text", "Normal", "Ein Satz. Noch einer", "")) {
        $testCaseName = "{enabled:$enabled,text:'$text'}"
        try {
            $expected = $enabled -and $text.TrimStart().StartsWith('.')
            $actual = Test-ShouldFilterExternalSpeechTrigger -text $text -enabled $enabled
            Assert-Equal -Expected $expected -Actual $actual -Message "Test case $testCaseName failed"
            Write-Host "PASS: $testCaseName"
        } catch {
            Write-Error $_.Exception.Message
        }
    }
}

# Additional tests for specific scenarios
$additionalTests = @{
    "0PE-187: individual literal prefixes, commas and semicolons are not separators" = {
        foreach ($enabled in @($false, $true)) {
            foreach ($text in @(".Hallo", ",Hallo", "- Hallo", "  , Hallo")) {
                $actual = Test-ShouldFilterExternalSpeechTrigger -text $text -enabled $enabled -prefixes ".,-"
                $expected = $enabled
                Assert-Equal -Expected $expected -Actual $actual -Message "Individual prefix test with text '$text' failed"
            }

            foreach ($text in @("Hallo, zusammen.", "Normal-Text", "Hallo", ".")) {
                $actual = Test-ShouldFilterExternalSpeechTrigger -text $text -enabled $enabled -prefixes ",-"
                $expected = $false
                Assert-Equal -Expected $expected -Actual $actual -Message "Non-triggering text '$text' should not trigger"
            }

            $actual = Test-ShouldFilterExternalSpeechTrigger -text ";Hallo" -enabled $enabled -prefixes ";"
            $expected = $enabled
            Assert-Equal -Expected $expected -Actual $actual -Message "Semicolon prefix test failed"

            $actual = Test-ShouldFilterExternalSpeechTrigger -text "[Hallo" -enabled $enabled -prefixes "["
            $expected = $enabled
            Assert-Equal -Expected $expected -Actual $actual -Message "Bracket prefix test failed"

            $actual = Test-ShouldFilterExternalSpeechTrigger -text "Hallo" -enabled $enabled -prefixes "["
            $expected = $false
            Assert-Equal -Expected $expected -Actual $actual -Message "Non-bracket prefixed text should not trigger"
        }
    };
    
    "0PE-187: five Unicode scalar triggers, paste sanitization and explicit empty selection" = {
        $actual = Normalize-ExternalSpeechTriggerCharacters -input $null
        $expected = "."
        Assert-Equal -Expected $expected -Actual $actual -Message "Normalize null input failed"

        $actual = Normalize-ExternalSpeechTriggerCharacters -input ""
        $expected = ""
        Assert-Equal -Expected $expected -Actual $actual -Message "Normalize empty string failed"

        $actual = Normalize-ExternalSpeechTriggerCharacters -input ".,-;:!"
        $expected = ".,-;:"
        Assert-Equal -Expected $expected -Actual $actual -Message "Normalize special chars failed"

        $actual = Normalize-ExternalSpeechTriggerCharacters -input " a1 `"',.,- "
        $expected = ".,-"
        Assert-Equal -Expected $expected -Actual $actual -Message "Normalize mixed content failed"

        $actual = Normalize-ExternalSpeechTriggerCharacters -input "😀😁😂😃😄😅"
        $expected = "😀😁😂😃😄"
        Assert-Equal -Expected $expected -Actual $actual -Message "Normalize emoji sequence failed"

        $actual = Test-ShouldFilterExternalSpeechTrigger -text "😀Hallo" -enabled $true -prefixes "😀"
        $expected = $true
        Assert-Equal -Expected $expected -Actual $actual -Message "Emoji-triggered speech filtering failed"

        $actual = Test-ShouldFilterExternalSpeechTrigger -text ".Hallo" -enabled $true -prefixes ""
        $expected = $false
        Assert-Equal -Expected $expected -Actual $actual -Message "Empty prefixes should not trigger"

        $actual = Test-ShouldFilterExternalSpeechTrigger -text ".Hallo" -enabled $true -prefixes ","
        $expected = $false
        Assert-Equal -Expected $expected -Actual $actual -Message "Mismatched prefixes should not trigger"
    }
}

# Run additional test cases
foreach ($testName in $additionalTests.Keys) {
    try {
        & $additionalTests[$testName]
        Write-Host "PASS: $testName"
    } catch {
        Write-Error "FAIL: $testName - $($_.Exception.Message)"
    }
}
