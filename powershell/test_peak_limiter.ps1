#!/usr/bin/env pwsh
# test_peak_limiter.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_peak_limiter.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

# Import necessary modules or define equivalent functions
# Since PowerShell doesn't have direct equivalents for node:test and node:assert/strict,
# we'll implement basic testing functionality manually.

# Define helper functions to mimic Node.js behavior
function Assert-True {
    param (
        [bool]$Condition,
        [string]$Message
    )
    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

function Assert-Equal {
    param (
        [object]$Expected,
        [object]$Actual,
        [string]$Message
    )
    if ($Expected -ne $Actual) {
        throw "Assertion failed: Expected '$Expected', but got '$Actual'. $Message"
    }
}

function New-Float32Array {
    param (
        [int]$Length,
        [scriptblock]$Generator
    )
    $array = [System.Array]::CreateInstance([float], $Length)
    if ($Generator) {
        for ($i = 0; $i -lt $Length; $i++) {
            $array[$i] = (& $Generator $i)
        }
    }
    return $array
}

# Mocking the required functions from content-core.js
# These need to be implemented based on actual logic in content-core.js
# For now, assuming they exist as global functions or can be sourced separately

# Placeholder for createPeakLimiter function
function Create-PeakLimiter {
    param (
        [int]$Rate
    )
    # This should return an object with process method and delaySamples property
    # Implement according to actual PeakLimiter logic
    @{
        delaySamples = [Math]::Floor($Rate * 0.005) # Example value
        process = {
            param (
                [array]$Input,
                [array]$Output,
                [bool]$Enabled,
                [int]$Strength
            )
            # Simplified processing logic placeholder
            foreach ($channel in $Input) {
                for ($i = 0; $i -lt $channel.Length; $i++) {
                    if ($Output[0].Length -gt $i) {
                        $Output[0][$i] = $channel[$i]
                    }
                }
            }
        }.GetNewClosure()
    }
}

# Placeholder for limiterStrengthToDbfs function
function Limiter-Strength-To-Dbfs {
    param (
        [int]$Strength
    )
    # Convert strength to dBFS using formula similar to original JS
    return -0.01 * $Strength * $Strength
}

# Define render function
function Render-Signal {
    param (
        [array]$Signal,
        [int]$Strength,
        [int]$Rate = 48000,
        [bool]$Enabled = $true
    )

    $kernel = Create-PeakLimiter -Rate $Rate
    $outputChannels = @()
    foreach ($channel in $Signal) {
        $newChannel = New-Object float[] ($channel.Length + $kernel.delaySamples)
        $outputChannels += ,$newChannel
    }

    for ($start = 0; $start -lt $outputChannels[0].Length; $start += 128) {
        $length = [Math]::Min(128, $outputChannels[0].Length - $start)
        $inputChannels = @()
        foreach ($channel in $Signal) {
            $tempChannel = New-Object float[] $length
            for ($i = 0; $i -lt $length; $i++) {
                $index = $start + $i
                if ($index -lt $channel.Length) {
                    $tempChannel[$i] = $channel[$index]
                } else {
                    $tempChannel[$i] = 0
                }
            }
            $inputChannels += ,$tempChannel
        }

        $outputSubarrays = @()
        foreach ($channel in $outputChannels) {
            $subArray = [array]$channel[$start..($start + $length - 1)]
            $outputSubarrays += ,$subArray
        }

        & $kernel.process $inputChannels $outputSubarrays $Enabled $Strength
    }

    return @{ output = $outputChannels; delay = $kernel.delaySamples }
}

# Define peak function
function Get-Peak {
    param (
        [array]$Channel
    )
    $maxValue = 0
    foreach ($value in $Channel) {
        if ([Math]::Abs($value) -gt $maxValue) {
            $maxValue = [Math]::Abs($value)
        }
    }
    return $maxValue
}

# Run tests
try {
    foreach ($rate in @(44100, 48000, 96000)) {
        Write-Host "Running test: isolated and high-frequency peaks are bounded at $rate Hz"

        $signal = New-Object float[] $rate
        $signal[1] = 1
        $signal[127] = -1
        for ($i = 1000; $i -lt 1100; $i++) {
            $signal[$i] = [Math]::Sin(2 * [Math]::PI * 8000 * $i / $rate)
        }

        $previous = 1
        foreach ($strength in @(25, 75, 100)) {
            $result = Render-Signal -Signal @($signal) -Strength $strength -Rate $rate
            $measured = Get-Peak -Channel $result.output[0]
            $ceiling = [Math]::Pow(10, (Limiter-Strength-To-Dbfs -Strength $strength) / 20)
            Assert-True -Condition ($measured -le $ceiling + 1e-7) -Message "$measured exceeds $ceiling"
            Assert-True -Condition ($measured -lt $previous) -Message "higher strength must attenuate more"
            Assert-True -Condition (($result.delay / $rate) -le 0.01) -Message ""
            $previous = $measured
        }
    }

    Write-Host "Running test: bypass preserves every sample with the documented delay"
    $signal = New-Float32Array -Length 10000 -Generator { param($i) [Math]::Sin($i * 0.7) * 0.8 }
    $result = Render-Signal -Signal @($signal) -Strength 100 -Rate 48000 -Enabled $false
    $delayedSignal = $result.output[0][($result.delay)..($result.output[0].Length - 1)]
    Assert-Equal -Expected ([string]$signal) -Actual ([string]$delayedSignal) -Message ""

    Write-Host "Running test: quiet speech-band signal is not permanently attenuated"
    $signal = New-Float32Array -Length 48000 -Generator { param($i) 0.01 * [Math]::Sin($i * 2 * [Math]::PI * 200 / 48000) }
    $result = Render-Signal -Signal @($signal) -Strength 100
    $delayedSignal = $result.output[0][($result.delay)..($result.output[0].Length - 1)]
    Assert-Equal -Expected ([string]$signal) -Actual ([string]$delayedSignal) -Message ""

    Write-Host "Running test: linked stereo gain preserves balance and limits either channel"
    $left = New-Object float[] 1000
    $left[127] = 0.5
    $right = New-Object float[] 1000
    $right[127] = 1
    $result = Render-Signal -Signal @($left, $right) -Strength 100
    $leftVal = $result.output[0][127 + $result.delay]
    $rightVal = $result.output[1][127 + $result.delay]
    Assert-Equal -Expected ($leftVal * 2) -Actual $rightVal -Message ""
    Assert-True -Condition ((Get-Peak -Channel $result.output[1]) -le [Math]::Pow(10, (-30 / 20)) + 1e-7) -Message ""

    Write-Host "Running test: gain recovers after a transient and invalid samples cannot poison the graph"
    $signal = New-Object float[] 48000
    $signal[10] = 1
    $signal[100] = [Double]::NaN
    $signal[200] = [Double]::PositiveInfinity
    for ($i = 24000; $i -lt $signal.Length; $i++) {
        $signal[$i] = 0.01
    }
    $result = Render-Signal -Signal @($signal) -Strength 100
    foreach ($val in $result.output[0]) {
        Assert-True -Condition ([Double]::IsFinite($val)) -Message "Non-finite number detected"
    }
    Assert-True -Condition ($result.output[0][40000] -gt 0.00999) -Message ""

    Write-Host "Running test: empty input drains delayed audio and then returns to silence"
    $kernel = Create-PeakLimiter -Rate 48000
    $block = ,([float[]](0.01) * 128)
    $out = New-Object float[] 128
    & $kernel.process $block @($out) $true 100
    for ($n = 0; $n -lt 4; $n++) {
        & $kernel.process @() @($out) $true 100
    }
    Assert-Equal -Expected (Get-Peak -Channel $out) -Actual 0 -Message ""

    Write-Host "All tests passed."
} catch {
    Write-Error $_.Exception.Message
}
