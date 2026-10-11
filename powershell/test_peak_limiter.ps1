#!/usr/bin/env pwsh
# test_peak_limiter.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_peak_limiter.cjs
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_peak_limiter.cjs
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

# Import necessary modules
using namespace System.Collections.Generic
using namespace System.Linq

# Define helper functions to mimic Node.js behavior
function Assert-Equal {
    param($Expected, $Actual, $Message)
    if ($Expected -ne $Actual) {
        throw "Assertion failed: $Message - Expected: $Expected, Actual: $Actual"
    }
}

function Assert-True {
    param($Condition, $Message)
    if (-not $Condition) {
        throw "Assertion failed: $Message"
    }
}

function Max-Abs {
    param($Array)
    $max = 0
    foreach ($value in $Array) {
        $absValue = [Math]::Abs($value)
        if ($absValue -gt $max) {
            $max = $absValue
        }
    }
    return $max
}

# Mocking the required functions from content-core.js
# These would need to be properly implemented based on actual logic
class PeakLimiterKernel {
    [int]$delaySamples
    [double[]]$gainHistory
    [int]$sampleRate

    PeakLimiterKernel([int]$rate) {
        $this.sampleRate = $rate
        # Assuming delay is calculated based on sample rate
        $this.delaySamples = [Math]::Floor($rate * 0.005) # Example delay calculation
        $this.gainHistory = @()
    }

    [void] Process([float[][]]$input, [float[][]]$output, [bool]$enabled, [int]$strength) {
        # Simplified processing logic for testing purposes
        $ceiling = [Math]::Pow(10, (limiterStrengthToDbfs $strength) / 20)
        for ($c = 0; $c -lt $input.Length; $c++) {
            for ($i = 0; $i -lt $input[$c].Length; $i++) {
                $sample = $input[$c][$i]
                if ([float]::IsNaN($sample) -or [float]::IsInfinity($sample)) {
                    $sample = 0
                }
                if ($enabled) {
                    $absSample = [Math]::Abs($sample)
                    if ($absSample -gt $ceiling) {
                        $sample = $sample * ($ceiling / $absSample)
                    }
                }
                $output[$c][$i] = $sample
            }
        }
    }
}

function Create-PeakLimiter {
    param([int]$rate)
    return [PeakLimiterKernel]::new($rate)
}

function limiterStrengthToDbfs {
    param([int]$strength)
    return -($strength * 0.3) # Example conversion
}

function Render-Signal {
    param(
        [float[][]]$signal,
        [int]$strength,
        [int]$rate = 48000,
        [bool]$enabled = $true
    )
    
    $kernel = Create-PeakLimiter $rate
    $output = @()
    foreach ($channel in $signal) {
        $newChannel = New-Object float32[] ($channel.Length + $kernel.delaySamples)
        $output += ,$newChannel
    }
    
    for ($start = 0; $start -lt $output[0].Length; $start += 128) {
        $length = [Math]::Min(128, $output[0].Length - $start)
        $inputBlocks = @()
        foreach ($channel in $signal) {
            $block = New-Object float32[] $length
            for ($i = 0; $i -lt $length; $i++) {
                $index = $start + $i
                if ($index -lt $channel.Length) {
                    $block[$i] = $channel[$index]
                } else {
                    $block[$i] = 0
                }
            }
            $inputBlocks += ,$block
        }
        
        $outputBlocks = @()
        for ($c = 0; $c -lt $output.Length; $c++) {
            $outputBlocks += ,($output[$c][$start..($start + $length - 1)])
        }
        
        $kernel.Process($inputBlocks, $outputBlocks, $enabled, $strength)
    }
    
    return @{
        output = $output
        delay = $kernel.delaySamples
    }
}

# Test cases
try {
    foreach ($rate in @(44100, 48000, 96000)) {
        Write-Host "Testing isolated and high-frequency peaks at $rate Hz"
        
        $signal = New-Object float32[] $rate
        $signal[1] = 1
        $signal[127] = -1
        for ($i = 1000; $i -lt 1100; $i++) {
            $signal[$i] = [Math]::Sin(2 * [Math]::PI * 8000 * $i / $rate)
        }
        
        $previous = 1
        foreach ($strength in @(25, 75, 100)) {
            $result = Render-Signal -signal @($signal) -strength $strength -rate $rate
            $output = $result.output
            $delay = $result.delay
            
            $measured = Max-Abs $output[0]
            $ceiling = [Math]::Pow(10, (limiterStrengthToDbfs $strength) / 20)
            
            Assert-True ($measured -le $ceiling + 1e-7) "Measured value $measured exceeds ceiling $ceiling"
            Assert-True ($measured -lt $previous) "Higher strength must attenuate more"
            Assert-True ($delay / $rate -le 0.01) "Delay should be less than 1% of sample rate"
            $previous = $measured
        }
    }
    
    Write-Host "Testing bypass preserves every sample"
    $signal = New-Object float32[] 10000
    for ($i = 0; $i -lt 10000; $i++) {
        $signal[$i] = [Math]::Sin($i * 0.7) * 0.8
    }
    
    $result = Render-Signal -signal @($signal) -strength 100 -rate 48000 -enabled $false
    $output = $result.output
    $delay = $result.delay
    
    $slicedOutput = $output[0][($delay)..($output[0].Length - 1)]
    Assert-Equal $slicedOutput.Length $signal.Length "Output slice length mismatch"
    for ($i = 0; $i -lt $signal.Length; $i++) {
        Assert-Equal $signal[$i] $slicedOutput[$i] "Signal mismatch at index $i"
    }
    
    Write-Host "Testing quiet speech-band signal"
    $signal = New-Object float32[] 48000
    for ($i = 0; $i -lt 48000; $i++) {
        $signal[$i] = 0.01 * [Math]::Sin($i * 2 * [Math]::PI * 200 / 48000)
    }
    
    $result = Render-Signal -signal @($signal) -strength 100
    $output = $result.output
    $delay = $result.delay
    
    $slicedOutput = $output[0][($delay)..($output[0].Length - 1)]
    Assert-Equal $slicedOutput.Length $signal.Length "Output slice length mismatch"
    for ($i = 0; $i -lt $signal.Length; $i++) {
        Assert-Equal $signal[$i] $slicedOutput[$i] "Signal mismatch at index $i"
    }
    
    Write-Host "Testing linked stereo gain"
    $left = New-Object float32[] 1000
    $left[127] = 0.5
    $right = New-Object float32[] 1000
    $right[127] = 1
    
    $result = Render-Signal -signal @($left, $right) -strength 100
    $output = $result.output
    $delay = $result.delay
    
    $leftSample = $output[0][127 + $delay]
    $rightSample = $output[1][127 + $delay]
    Assert-Equal ($leftSample * 2) $rightSample "Stereo balance not preserved"
    
    $peakRight = Max-Abs $output[1]
    $limit = [Math]::Pow(10, -30 / 20) + 1e-7
    Assert-True ($peakRight -le $limit) "Right channel not limited properly"
    
    Write-Host "Testing gain recovery and invalid samples"
    $signal = New-Object float32[] 48000
    $signal[10] = 1
    $signal[100] = [float]::NaN
    $signal[200] = [float]::PositiveInfinity
    for ($i = 24000; $i -lt $signal.Length; $i++) {
        $signal[$i] = 0.01
    }
    
    $result = Render-Signal -signal @($signal) -strength 100
    $output = $result.output
    
    foreach ($sample in $output[0]) {
        Assert-True ([float]::IsFinite($sample)) "Invalid sample found in output"
    }
    
    $sampleAt40000 = $output[0][40000]
    Assert-True ($sampleAt40000 -gt 0.00999) "Gain did not recover properly"
    
    Write-Host "Testing empty input drains delayed audio"
    $kernel = Create-PeakLimiter 48000
    $block = New-Object float32[] 128
    for ($i = 0; $i -lt 128; $i++) {
        $block[$i] = 0.01
    }
    $out = New-Object float32[] 128
    
    $kernel.Process(@($block), @($out), $true, 100)
    for ($n = 0; $n -lt 4; $n++) {
        $kernel.Process(@(), @($out), $true, 100)
    }
    
    $peakOut = Max-Abs $out
    Assert-Equal $peakOut 0 "Output should be silence after draining"
    
    Write-Host "All tests passed!"
}
catch {
    Write-Error "Test failed: $_"
    exit 1
}
