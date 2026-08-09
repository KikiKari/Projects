#!/usr/bin/env pwsh
# package_artifacts.py — portiert nach powershell
# Quelle: python, Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputDir,

    [string]$AndroidApk
)

$ErrorActionPreference = "Stop"

# Define paths
$ScriptPath = $MyInvocation.MyCommand.Path
$ROOT = Split-Path (Split-Path $ScriptPath -Parent) -Parent
$PROJECT_ROOT = Split-Path $ROOT -Parent
$EXCLUDED_PARTS = @("__pycache__", ".gradle", ".kotlin", "build", "DerivedData", "xcuserdata")

function Add-Tree {
    param(
        [System.IO.Compression.ZipArchive]$Archive,
        [string]$Source,
        [string]$Prefix = ""
    )

    $sourcePath = Get-Item $Source
    $files = Get-ChildItem -Path $Source -Recurse -File | Sort-Object FullName

    foreach ($file in $files) {
        $relativePath = Resolve-Path -Path $file.FullName -RelativeBasePath $sourcePath.FullName
        $relativePath = $relativePath -replace '^\.\\', ''

        # Check if any part of the path is in EXCLUDED_PARTS
        $pathParts = $file.FullName.Split([System.IO.Path]::DirectorySeparatorChar)
        $isExcluded = $false
        foreach ($part in $pathParts) {
            if ($EXCLUDED_PARTS -contains $part) {
                $isExcluded = $true
                break
            }
        }

        if ($isExcluded) {
            continue
        }

        # Skip .pyc and .aar files
        if ($file.Extension -eq ".pyc" -or $file.Extension -eq ".aar") {
            continue
        }

        $entryName = if ($Prefix) { Join-Path $Prefix $relativePath } else { $relativePath }
        $entryName = $entryName -replace '\\', '/'
        $entry = $Archive.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::Optimal)
        $entryStream = $entry.Open()
        $fileStream = $file.OpenRead()
        $fileStream.CopyTo($entryStream)
        $fileStream.Close()
        $entryStream.Close()
    }
}

# Create output directory
$OutputDir = Resolve-Path $OutputDir
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

# Read manifest and get version
$manifestPath = Join-Path $ROOT "browser-extension" "manifest.json"
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$version = $manifest.version

# Define artifact paths
$extensionZip = Join-Path $OutputDir "tiktok-live-companion-extension-$version.zip"
$pluginZip = Join-Path $OutputDir "tiktok-live-companion-plugin-$version.zip"
$serviceZip = Join-Path $OutputDir "tiktok-live-companion-service-$version.zip"
$iosSourceZip = Join-Path $OutputDir "tiktok-live-companion-ios-$version-source.zip"
$androidSourceZip = Join-Path $OutputDir "tiktok-live-companion-android-$version-source.zip"
$androidApk = Join-Path $OutputDir "tiktok-live-companion-android-$version.apk"
$extensionDir = Join-Path $OutputDir "tiktok-live-companion-extension-$version"
$checksumFile = Join-Path $OutputDir "tiktok-live-companion-$version-SHA256.txt"

# Validate extension directory
$resolvedExtensionDir = Resolve-Path $extensionDir -ErrorAction SilentlyContinue
if ($resolvedExtensionDir -and (Split-Path $resolvedExtensionDir -Parent) -ne $OutputDir) {
    throw "Refusing to package outside the requested output directory"
}

# Remove existing extension directory
if (Test-Path $extensionDir) {
    Remove-Item $extensionDir -Recurse -Force
}

# Copy browser-extension to extension directory
Copy-Item -Path (Join-Path $ROOT "browser-extension") -Destination $extensionDir -Recurse

# Create extension zip
$extensionZipArchive = [System.IO.Compression.ZipFile]::Open($extensionZip, "Create")
Add-Tree -Archive $extensionZipArchive -Source (Join-Path $ROOT "browser-extension")
$extensionZipArchive.Dispose()

# Create plugin zip
$pluginZipArchive = [System.IO.Compression.ZipFile]::Open($pluginZip, "Create")
Add-Tree -Archive $pluginZipArchive -Source $ROOT -Prefix "tiktok-live-companion"
$pluginZipArchive.Dispose()

# Create service zip
$serviceZipArchive = [System.IO.Compression.ZipFile]::Open($serviceZip, "Create")
Add-Tree -Archive $serviceZipArchive -Source (Join-Path $ROOT "companion-service")
$serviceZipArchive.Dispose()

# Create iOS source zip
$iosSourcePath = Join-Path $PROJECT_ROOT "mobile" "ios"
if (Test-Path $iosSourcePath) {
    $iosSourceZipArchive = [System.IO.Compression.ZipFile]::Open($iosSourceZip, "Create")
    Add-Tree -Archive $iosSourceZipArchive -Source $iosSourcePath -Prefix "TikTokLiveCompanion-iOS"
    $iosSourceZipArchive.Dispose()
}

# Create Android source zip
$androidSourcePath = Join-Path $PROJECT_ROOT "mobile" "android"
if (Test-Path $androidSourcePath) {
    $androidSourceZipArchive = [System.IO.Compression.ZipFile]::Open($androidSourceZip, "Create")
    Add-Tree -Archive $androidSourceZipArchive -Source $androidSourcePath -Prefix "TikTokLiveCompanion-Android"
    $androidSourceZipArchive.Dispose()
}

# Copy Android APK if provided
if ($AndroidApk) {
    $sourceApk = Resolve-Path $AndroidApk -ErrorAction SilentlyContinue
    if (-not $sourceApk -or $sourceApk.Extension.ToLower() -ne ".apk") {
        throw "--android-apk must point to an existing APK"
    }
    Copy-Item -Path $sourceApk -Destination $androidApk
}

# Calculate checksums
$artifacts = @($extensionZip, $pluginZip, $serviceZip, $iosSourceZip, $androidSourceZip)
if (Test-Path $androidApk) {
    $artifacts += $androidApk
}

$checksums = @()
foreach ($artifact in $artifacts) {
    if (Test-Path $artifact) {
        $hash = Get-FileHash -Path $artifact -Algorithm SHA256
        $checksums += "$($hash.Hash)  $(Split-Path $artifact -Leaf)"
    }
}
Set-Content -Path $checksumFile -Value ($checksums -join "`n") -Encoding UTF8

# Prepare output JSON
$result = @{
    extension_dir = $extensionDir
    extension_zip = $extensionZip
    plugin_zip = $pluginZip
    service_zip = $serviceZip
    ios_source_zip = $iosSourceZip
    android_source_zip = $androidSourceZip
    android_apk = if (Test-Path $androidApk) { $androidApk } else { $null }
    checksum_file = $checksumFile
    version = $version
}

ConvertTo-Json $result -Compress
