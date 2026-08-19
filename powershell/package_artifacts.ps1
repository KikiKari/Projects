#!/usr/bin/env pwsh
# package_artifacts.py — portiert nach powershell
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputDir,
    
    [string]$AndroidApk,
    
    [string]$AndroidSource = "$PSScriptRoot/../../mobile/android",
    
    [string]$IosSource = "$PSScriptRoot/../../mobile/ios"
)

$ErrorActionPreference = "Stop"

# Resolve paths
$ROOT = Resolve-Path "$PSScriptRoot/../.."
$PROJECT_ROOT = Resolve-Path "$PSScriptRoot/../../.."
$EXCLUDED_PARTS = @("__pycache__", ".gradle", ".kotlin", "build", "DerivedData", "xcuserdata")

function Add-Tree {
    param(
        [System.IO.Compression.ZipArchive]$Archive,
        [string]$Source,
        [string]$Prefix = ""
    )
    
    $sourcePath = Resolve-Path $Source
    $files = Get-ChildItem -Path $sourcePath -Recurse -File | Sort-Object FullName
    
    foreach ($file in $files) {
        $relativePath = Resolve-Path -Relative -Path $file.FullName -RelativeTo $sourcePath
        
        # Check if any part of the path is in excluded parts
        $parts = $relativePath -split '[\\/]'
        $isExcluded = $false
        foreach ($part in $parts) {
            if ($EXCLUDED_PARTS -contains $part) {
                $isExcluded = $true
                break
            }
        }
        
        if ($isExcluded) {
            continue
        }
        
        # Check file extensions
        if ($file.Extension -eq ".pyc" -or $file.Extension -eq ".aar") {
            continue
        }
        
        $archivePath = if ($Prefix) { Join-Path $Prefix $relativePath } else { $relativePath }
        $archivePath = $archivePath -replace '\\', '/'
        
        # Create ZipEntry with fixed timestamp
        $entry = New-Object System.IO.Compression.ZipArchiveEntry($Archive, $archivePath)
        $entry.LastWriteTime = [DateTime]::new(1980, 1, 1, 0, 0, 0)
        
        # Write file content
        $content = [System.IO.File]::ReadAllBytes($file.FullName)
        $stream = $entry.Open()
        $stream.Write($content, 0, $content.Length)
        $stream.Close()
    }
}

# Load manifest and get version
$manifestPath = Join-Path $ROOT "browser-extension/manifest.json"
$manifest = Get-Content $manifestPath | ConvertFrom-Json
$version = $manifest.version

# Define output files
$outputDirPath = Resolve-Path $OutputDir
$extensionZip = Join-Path $outputDirPath "tiktok-live-companion-extension-$version.zip"
$pluginZip = Join-Path $outputDirPath "tiktok-live-companion-plugin-$version.zip"
$serviceZip = Join-Path $outputDirPath "tiktok-live-companion-service-$version.zip"
$iosSourceZip = Join-Path $outputDirPath "tiktok-live-companion-ios-$version-source.zip"
$androidSourceZip = Join-Path $outputDirPath "tiktok-live-companion-android-$version-source.zip"
$androidApk = Join-Path $outputDirPath "tiktok-live-companion-android-$version.apk"
$extensionDir = Join-Path $outputDirPath "tiktok-live-companion-extension-$version"
$checksumFile = Join-Path $outputDirPath "tiktok-live-companion-$version-SHA256.txt"

# Validate extension directory location
$resolvedExtensionDir = Resolve-Path $extensionDir -ErrorAction SilentlyContinue
if ($resolvedExtensionDir -and (Split-Path $resolvedExtensionDir -Parent) -ne $outputDirPath) {
    throw "Refusing to package outside the requested output directory"
}

# Clean and copy extension directory
if (Test-Path $extensionDir) {
    Remove-Item $extensionDir -Recurse -Force
}

Copy-Item -Path "$ROOT/browser-extension" -Destination $extensionDir -Recurse
Copy-Item -Path "$ROOT/companion-service" -Destination "$extensionDir/companion-service" -Recurse

# Create batch file
$batchContent = '@echo off`r`ncall "%~dp0companion-service\Sprachdienst-reparieren.cmd"`r`n'
Set-Content -Path "$extensionDir/Sprachdienst-reparieren.cmd" -Value $batchContent -Encoding UTF8

# Create package.json
$packageJson = @{
    name = "tiktok-live-companion-extension-package"
    private = $true
    version = $version
    scripts = @{
        setup = "npm --prefix companion-service run setup --"
        start = "npm --prefix companion-service start"
        test = "npm --prefix companion-service test"
    }
}
$packageJson | ConvertTo-Json -Depth 10 | Out-File -FilePath "$extensionDir/package.json" -Encoding UTF8

# Create extension zip
[System.IO.Compression.ZipFile]::Open($extensionZip, "Create") | ForEach-Object {
    Add-Tree -Archive $_ -Source $extensionDir
    $_.Dispose()
}

# Create plugin zip
[System.IO.Compression.ZipFile]::Open($pluginZip, "Create") | ForEach-Object {
    Add-Tree -Archive $_ -Source $ROOT -Prefix "tiktok-live-companion"
    $_.Dispose()
}

# Create service zip
[System.IO.Compression.ZipFile]::Open($serviceZip, "Create") | ForEach-Object {
    Add-Tree -Archive $_ -Source "$ROOT/companion-service"
    $_.Dispose()
}

# Resolve source directories
$iosSourcePath = Resolve-Path $IosSource
$androidSourcePath = Resolve-Path $AndroidSource

if (-not (Test-Path $iosSourcePath -PathType Container) -or -not (Test-Path $androidSourcePath -PathType Container)) {
    throw "--ios-source and --android-source must point to existing source directories"
}

# Create iOS source zip
[System.IO.Compression.ZipFile]::Open($iosSourceZip, "Create") | ForEach-Object {
    Add-Tree -Archive $_ -Source $iosSourcePath -Prefix "TikTokLiveCompanion-iOS"
    $_.Dispose()
}

# Create Android source zip
[System.IO.Compression.ZipFile]::Open($androidSourceZip, "Create") | ForEach-Object {
    Add-Tree -Archive $_ -Source $androidSourcePath -Prefix "TikTokLiveCompanion-Android"
    $_.Dispose()
}

# Handle Android APK
if ($AndroidApk) {
    $sourceApk = Resolve-Path $AndroidApk
    if (-not (Test-Path $sourceApk -PathType Leaf) -or [System.IO.Path]::GetExtension($sourceApk) -ne ".apk") {
        throw "--android-apk must point to an existing APK"
    }
    
    if ($sourceApk -ne (Resolve-Path $androidApk)) {
        Copy-Item -Path $sourceApk -Destination $androidApk
    }
}

# Calculate checksums
$artifacts = @($extensionZip, $pluginZip, $serviceZip, $iosSourceZip, $androidSourceZip)
if (Test-Path $androidApk) {
    $artifacts += $androidApk
}

$checksums = @()
foreach ($artifact in $artifacts) {
    $hash = Get-FileHash -Path $artifact -Algorithm SHA256
    $checksums += "{0}  {1}" -f $hash.Hash, (Split-Path $artifact -Leaf)
}
$checksums -join "`n" | Out-File -FilePath $checksumFile -Encoding UTF8

# Output result as JSON
$result = @{
    extension_dir = (Resolve-Path $extensionDir).Path
    extension_zip = (Resolve-Path $extensionZip).Path
    plugin_zip = (Resolve-Path $pluginZip).Path
    service_zip = (Resolve-Path $serviceZip).Path
    ios_source_zip = (Resolve-Path $iosSourceZip).Path
    android_source_zip = (Resolve-Path $androidSourceZip).Path
    android_apk = if (Test-Path $androidApk) { (Resolve-Path $androidApk).Path } else { $null }
    checksum_file = (Resolve-Path $checksumFile).Path
    version = $version
}

$result | ConvertTo-Json -Compress
