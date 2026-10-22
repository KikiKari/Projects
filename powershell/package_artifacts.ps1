#!/usr/bin/env pwsh
# package_artifacts.py — portiert nach powershell
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputDir,

    [string]$AndroidApk,

    [string]$AndroidSource = "$PROJECT_ROOT/mobile/android",

    [string]$IosSource = "$PROJECT_ROOT/mobile/ios",

    [string]$NativeSharedSource = "$PROJECT_ROOT/mobile/shared"
)

$ErrorActionPreference = "Stop"

# Define constants
$ROOT = Split-Path $PSScriptRoot -Parent
$PROJECT_ROOT = Split-Path $ROOT -Parent
$EXCLUDED_PARTS = @("__pycache__", ".gradle", ".kotlin", ".cxx", "build", "DerivedData", "xcuserdata", "Pods")

function Add-Tree {
    param(
        [System.IO.Compression.ZipArchive]$Archive,
        [string]$Source,
        [string]$Prefix = ""
    )

    Get-ChildItem -Path $Source -Recurse | Where-Object {
        $_.PSIsContainer -eq $false -and 
        ($EXCLUDED_PARTS | Where-Object { $_ -in $_.FullName.Split([System.IO.Path]::DirectorySeparatorChar) }).Count -eq 0 -and
        $_.Extension -notin @(".pyc", ".aar")
    } | ForEach-Object {
        $relativePath = Resolve-Path $_.FullName -Relative
        $relativePath = $relativePath.Substring($Source.Length + 1)
        $archivePath = Join-Path $Prefix $relativePath -ResolveErrorAction SilentlyContinue
        $archivePath = $archivePath.Replace("\", "/")
        
        $entry = $Archive.CreateEntry($archivePath, [System.IO.Compression.CompressionLevel]::Optimal)
        $entry.LastWriteTime = [DateTime]::new(1980, 1, 1, 0, 0, 0)
        
        # Set permissions based on file name
        if ($_.Name -eq "gradlew") {
            $entry.ExternalAttributes = (0x100755 -shl 16) -bor $entry.ExternalAttributes
        } else {
            $entry.ExternalAttributes = (0x100644 -shl 16) -bor $entry.ExternalAttributes
        }
        
        $stream = $entry.Open()
        $content = [System.IO.File]::ReadAllBytes($_.FullName)
        $stream.Write($content, 0, $content.Length)
        $stream.Close()
    }
}

# Create output directory if it doesn't exist
if (!(Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}
$outputDir = Resolve-Path $OutputDir

# Read manifest and get version
$manifestContent = Get-Content "$ROOT/browser-extension/manifest.json" -Raw | ConvertFrom-Json
$version = $manifestContent.version

# Define artifact paths
$extensionZip = Join-Path $OutputDir "tiktok-live-companion-extension-$version.zip"
$pluginZip = Join-Path $OutputDir "tiktok-live-companion-plugin-$version.zip"
$serviceZip = Join-Path $OutputDir "tiktok-live-companion-service-$version.zip"
$iosSourceZip = Join-Path $OutputDir "tiktok-live-companion-ios-$version-source.zip"
$androidSourceZip = Join-Path $OutputDir "tiktok-live-companion-android-$version-source.zip"
$androidApk = Join-Path $OutputDir "tiktok-live-companion-android-$version.apk"
$extensionDir = Join-Path $OutputDir "tiktok-live-companion-extension-$version"
$checksumFile = Join-Path $OutputDir "tiktok-live-companion-$version-SHA256.txt"

$resolvedExtensionDir = Resolve-Path $extensionDir -ErrorAction SilentlyContinue
if ($resolvedExtensionDir -and (Split-Path $resolvedExtensionDir -Parent) -ne $outputDir) {
    throw "Refusing to package outside the requested output directory"
}

# Clean up previous extension directory
if (Test-Path $extensionDir) {
    Remove-Item $extensionDir -Recurse -Force
}

# Copy browser extension files
Copy-Item "$ROOT/browser-extension" $extensionDir -Recurse
Copy-Item "$ROOT/companion-service" "$extensionDir/companion-service" -Recurse

# Create Windows batch file
Set-Content "$extensionDir/Sprachdienst-reparieren.cmd" '@echo off
call "%~dp0companion-service\Sprachdienst-reparieren.cmd"' -Encoding UTF8

# Create package.json content
$packageJson = @{
    name = "tiktok-live-companion-extension-package"
    private = $true
    version = $version
    scripts = @{
        setup = "npm --prefix companion-service run setup --"
        start = "npm --prefix companion-service start"
        test = "npm --prefix companion-service test"
    }
} | ConvertTo-Json -Depth 10
Set-Content "$extensionDir/package.json" "$packageJson`n" -Encoding UTF8

# Create extension zip
[System.IO.Compression.ZipFile]::CreateFromDirectory($extensionDir, $extensionZip)

# Create plugin zip
$tempPluginDir = Join-Path $env:TEMP "temp-plugin-$([System.Guid]::NewGuid())"
New-Item -ItemType Directory -Path $tempPluginDir | Out-Null
try {
    Copy-Item "$ROOT/*" $tempPluginDir -Recurse -Exclude @("browser-extension", "companion-service")
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempPluginDir, $pluginZip)
} finally {
    Remove-Item $tempPluginDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Create service zip
[System.IO.Compression.ZipFile]::CreateFromDirectory("$ROOT/companion-service", $serviceZip)

# Validate source directories
$iosSource = Resolve-Path $IosSource
$androidSource = Resolve-Path $AndroidSource
if (!(Test-Path $iosSource -PathType Container) -or !(Test-Path $androidSource -PathType Container)) {
    throw "--ios-source and --android-source must point to existing source directories"
}

$nativeShared = Resolve-Path $NativeSharedSource
if (!(Test-Path "$nativeShared/native/tlc_peak_limiter.h" -PathType Leaf)) {
    throw "Shared native limiter source is required for both mobile source packages"
}

# Create iOS source zip
$tempIosDir = Join-Path $env:TEMP "temp-ios-$([System.Guid]::NewGuid())"
New-Item -ItemType Directory -Path $tempIosDir | Out-Null
try {
    Copy-Item $iosSource "$tempIosDir/TikTokLiveCompanion-iOS" -Recurse
    Copy-Item $nativeShared "$tempIosDir/shared" -Recurse
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempIosDir, $iosSourceZip)
} finally {
    Remove-Item $tempIosDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Create Android source zip
$tempAndroidDir = Join-Path $env:TEMP "temp-android-$([System.Guid]::NewGuid())"
New-Item -ItemType Directory -Path $tempAndroidDir | Out-Null
try {
    Copy-Item $androidSource "$tempAndroidDir/TikTokLiveCompanion-Android" -Recurse
    Copy-Item $nativeShared "$tempAndroidDir/shared" -Recurse
    [System.IO.Compression.ZipFile]::CreateFromDirectory($tempAndroidDir, $androidSourceZip)
} finally {
    Remove-Item $tempAndroidDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Handle Android APK if provided
if ($AndroidApk) {
    $sourceApk = Resolve-Path $AndroidApk
    if (!(Test-Path $sourceApk -PathType Leaf) -or [System.IO.Path]::GetExtension($sourceApk) -ne ".apk") {
        throw "--android-apk must point to an existing APK"
    }
    if ((Resolve-Path $sourceApk) -ne (Resolve-Path $androidApk)) {
        Copy-Item $sourceApk $androidApk
    }
}

# Calculate SHA256 checksums
$artifacts = @($extensionZip, $pluginZip, $serviceZip, $iosSourceZip, $androidSourceZip)
if (Test-Path $androidApk) {
    $artifacts += $androidApk
}

$checksums = @()
foreach ($artifact in $artifacts) {
    $hash = Get-FileHash $artifact -Algorithm SHA256
    $checksums += "{0}  {1}" -f $hash.Hash, (Split-Path $artifact -Leaf)
}
Set-Content $checksumFile ($checksums -join "`n") -Encoding UTF8

# Output result JSON
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

ConvertTo-Json $result -EnumsAsStrings
