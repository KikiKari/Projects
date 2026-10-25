#!/usr/bin/env pwsh
# test_native_peak_limiter.cjs — portiert nach powershell
# Quelle: javascript, Projects@codex/0pe-177-peak-protection:plugin-source/scripts/test_native_peak_limiter.cjs
# auch in: Projects@vercel/install-and-configure-vercel-w-98sxlo:plugin-source/scripts/test_native_peak_limiter.cjs
# Erzeugt: 2026-10-25 durch ABSTRACTIONS_MANAGER.py

# Import necessary .NET classes for assertions and process management
Add-Type -AssemblyName System.Runtime
Add-Type -AssemblyName System.Diagnostics

# Function to mimic Node.js assert.strict behavior
function Assert-Ok($condition, $message) {
    if (-not $condition) {
        throw "AssertionError: $message"
    }
}

function Assert-Equal($actual, $expected, $message) {
    if ($actual -ne $expected) {
        throw "AssertionError: Expected '$expected', but got '$actual'. $message"
    }
}

# Load the content-core.js file as a scriptblock and execute it to get createPeakLimiter function
$scriptPath = Join-Path $PSScriptRoot "../browser-extension/content-core.js"
$scriptContent = Get-Content -Path $scriptPath -Raw
$scriptBlock = [ScriptBlock]::Create($scriptContent)
$contentCore = & $scriptBlock

# Get executable path from command line arguments
$executable = $args[0]
Assert-Ok ($executable) "Pass compiled mobile/shared/native/limiter_trace.c executable"

# Initialize test case counter
$cases = 0

# Define test parameters similar to JavaScript loops
$rates = @(44100, 48000, 96000)
$channelCounts = @(1, 2, 6)
$configurations = @(
    @{ Enabled = $false; Strength = 100 },
    @{ Enabled = $true;  Strength = 25 },
    @{ Enabled = $true;  Strength = 75 },
    @{ Enabled = $true;  Strength = 100 }
)

foreach ($rate in $rates) {
    foreach ($channels in $channelCounts) {
        foreach ($config in $configurations) {
            $enabled = $config.Enabled
            $strength = $config.Strength
            
            # Calculate number of frames based on sample rate
            $frames = [Math]::Round($rate * 0.25)
            
            # Create input data arrays with specific values at certain indices
            $input = @()
            for ($c = 0; $c -lt $channels; $c++) {
                $channelData = New-Object float32[] $frames
                for ($i = 0; $i -lt $frames; $i++) {
                    if ($i -eq 5 -or $i -eq 129) {
                        $channelData[$i] = if ($c % 2 -eq 1) { -0.95 } else { 0.95 }
                    } elseif ($i -eq 300) {
                        $channelData[$i] = [float]::NaN
                    } elseif ($i -eq 301) {
                        $channelData[$i] = [float]::PositiveInfinity
                    } else {
                        $freq = if ($i -lt 2000) { 8000 } else { 220 }
                        $amp = if ($i -lt 2000) { 0.9 } else { 0.01 }
                        $channelData[$i] = (($c + 1) / $channels) * [Math]::Sin($i * 2 * [Math]::PI * $freq / $rate) * $amp
                    }
                }
                $input += , $channelData
            }

            # Create peak limiter kernel using loaded content-core module
            $kernel = & $contentCore.createPeakLimiter($rate)
            
            # Calculate total count including delay samples
            $count = $frames + $kernel.delaySamples
            
            # Prepare binary buffer for input/output comparison
            $wireSize = $count * $channels * 4
            $wire = New-Object byte[] $wireSize
            
            # Fill buffer with input data converted to little-endian float bytes
            for ($i = 0; $i -lt $count; $i++) {
                for ($c = 0; $c -lt $channels; $c++) {
                    $value = if ($i -lt $input[$c].Length) { $input[$c][$i] } else { 0 }
                    $bytes = [BitConverter]::GetBytes([float]$value)
                    [Array]::Copy($bytes, 0, $wire, ($i * $channels + $c) * 4, 4)
                }
            }

            # Execute external program with specified arguments
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = $executable
            $psi.Arguments = "$rate $channels $(if ($enabled) { 1 } else { 0 }) $strength"
            $psi.UseShellExecute = $false
            $psi.RedirectStandardInput = $true
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            
            $process = [System.Diagnostics.Process]::Start($psi)
            $writer = $process.StandardInput.BaseStream
            $reader = $process.StandardOutput.BaseStream
            $errorReader = $process.StandardError.ReadToEnd()
            
            # Write input data to process stdin
            $writer.Write($wire, 0, $wire.Length)
            $writer.Close()
            
            # Wait for process completion and read output
            $process.WaitForExit()
            $outputBytes = New-Object byte[] $wireSize
            $read = $reader.Read($outputBytes, 0, $wireSize)
            $reader.Close()
            
            # Validate exit code and output length
            Assert-Equal $process.ExitCode 0 "Process exited with error: $errorReader"
            Assert-Equal $read $wireSize "Unexpected output size"

            # Compare results block by block
            $maxError = 0
            for ($start = 0; $start -lt $count; $start += 127) {
                $size = [Math]::Min(127, $count - $start)
                
                # Extract current block from input data
                $block = @()
                for ($c = 0; $c -lt $channels; $c++) {
                    $channelBlock = New-Object float32[] $size
                    for ($i = 0; $i -lt $size; $i++) {
                        $index = $start + $i
                        $channelBlock[$i] = if ($index -lt $input[$c].Length) { $input[$c][$index] } else { 0 }
                    }
                    $block += , $channelBlock
                }
                
                # Process block through kernel
                $output = @()
                for ($c = 0; $c -lt $channels; $c++) {
                    $output += , (New-Object float32[] $size)
                }
                
                & $contentCore.process $block $output $enabled $strength
                
                # Compare each value against reference implementation
                for ($i = 0; $i -lt $size; $i++) {
                    for ($c = 0; $c -lt $channels; $c++) {
                        $offset = (($start + $i) * $channels + $c) * 4
                        $actualBytes = $outputBytes[$offset..($offset+3)]
                        $actualValue = [BitConverter]::ToSingle($actualBytes, 0)
                        
                        if ([float]::IsFinite($actualValue)) {
                            $diff = [Math]::Abs($actualValue - $output[$c][$i])
                            $maxError = [Math]::Max($maxError, $diff)
                        } else {
                            throw "Non-finite result detected"
                        }
                    }
                }
            }
            
            # Validate maximum deviation is within tolerance
            Assert-Ok ($maxError -le 1e-7) "${rate}/${channels}/${enabled}/${strength}: Max error was ${maxError}"
            
            $cases++
        }
    }
}

Write-Host "${cases} native/JavaScript PCM equivalence cases passed (error <= 1e-7)."
