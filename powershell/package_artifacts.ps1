#!/usr/bin/env pwsh
# package_artifacts.py — portiert nach powershell
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputDir,

    [string]$AndroidApk,

    [string]$AndroidSource = "$PROJECT_ROOT/mobile/android",

    [string]$IosSource = "$PROJECT_ROOT/mobile/ios"
)

$ErrorActionPreference = "Stop"

# Define constants
$ROOT = (Get-Item $PSScriptRoot).Parent.FullName
$PROJECT_ROOT = (Get-Item $ROOT).Parent.FullName
$EXCLUDED_PARTS = @("__pycache__", ".gradle", ".kotlin", "build", "DerivedData", "xcuserdata")

function Add-Tree {
    param(
        [System.IO.Compression.ZipArchive]$Archive,
        [string]$Source,
        [string]$Prefix = ""
    )

    $sourcePath = Get-Item $Source
    $files = Get-ChildItem -Path $sourcePath -Recurse -File | Sort-Object FullName

    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($sourcePath.FullName.Length + 1)
        
        # Check if any excluded part is in the path
        $pathParts = $relativePath -split '[\\/]'
        $hasExcludedPart = $false
        foreach ($part in $pathParts) {
            if ($EXCLUDED_PARTS -contains $part) {
                $hasExcludedPart = $true
                break
            }
        }
        
        # Skip if excluded or has excluded extension
        if ($hasExcludedPart -or $file.Extension -eq ".pyc" -or $file.Extension -eq ".aar") {
            continue
        }

        $archivePath = if ($Prefix) { Join-Path $Prefix $relativePath } else { $relativePath }
        $archivePath = $archivePath -replace '\\', '/'
        
        $entry = $Archive.CreateEntry($archivePath, [System.IO.Compression.CompressionLevel]::Optimal)
        $entry.LastWriteTime = [DateTime]::new(1980, 1, 1)
        
        $stream = $entry.Open()
        try {
            $fileStream = [System.IO.File]::OpenRead($file.FullName)
            try {
                $fileStream.CopyTo($stream)
            } finally {
                $fileStream.Close()
            }
        } finally {
            $stream.Close()
        }
    }
}

# Load manifest and get version
$manifestPath = Join-Path $ROOT "browser-extension" "manifest.json"
$manifest = Get-Content $manifestPath | ConvertFrom-Json
$version = $manifest.version

# Create output directory
$null = New-Item -ItemType Directory -Path $OutputDir -Force
$outputDirResolved = Resolve-Path $OutputDir

# Define artifact paths
$extensionZip = Join-Path $OutputDir "tiktok-live-companion-extension-$version.zip"
$pluginZip = Join-Path $OutputDir "tiktok-live-companion-plugin-$version.zip"
$serviceZip = Join-Path $OutputDir "tiktok-live-companion-service-$version.zip"
$iosSourceZip = Join-Path $OutputDir "tiktok-live-companion-ios-$version-source.zip"
$androidSourceZip = Join-Path $OutputDir "tiktok-live-companion-android-$version-source.zip"
$androidApk = Join-Path $OutputDir "tiktok-live-companion-android-$version.apk"
$extensionDir = Join-Path $OutputDir "tiktok-live-companion-extension-$version"
$checksumFile = Join-Path $OutputDir "tiktok-live-companion-$version-SHA256.txt"

# Validate extension directory location
$extensionDirResolved = Resolve-Path $extensionDir -ErrorAction SilentlyContinue
if ($extensionDirResolved -and (Split-Path $extensionDirResolved.Parent.Path -Leaf) -ne (Split-Path $outputDirResolved -Leaf)) {
    throw "Refusing to package outside the requested output directory"
}

# Clean up existing extension directory
if (Test-Path $extensionDir) {
    Remove-Item $extensionDir -Recurse -Force
}

# Copy browser-extension and companion-service
Copy-Item (Join-Path $ROOT "browser-extension") $extensionDir -Recurse
Copy-Item (Join-Path $ROOT "companion-service") (Join-Path $extensionDir "companion-service") -Recurse

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
} | ConvertTo-Json -Depth 10

Set-Content (Join-Path $extensionDir "package.json") $packageJson

# Create extension zip
$extensionZipArchive = [System.IO.Compression.ZipFile]::Open($extensionZip, "Create")
try {
    Add-Tree -Archive $extensionZipArchive -Source $extensionDir
} finally {
    $extensionZipArchive.Dispose()
}

# Create plugin zip
$pluginZipArchive = [System.IO.Compression.ZipFile]::Open($pluginZip, "Create")
try {
    Add-Tree -Archive $pluginZipArchive -Source $ROOT -Prefix "tiktok-live-companion"
} finally {
    $pluginZipArchive.Dispose()
}

# Create service zip
$serviceZipArchive = [System.IO.Compression.ZipFile]::Open($serviceZip, "Create")
try {
    Add-Tree -Archive $serviceZipArchive -Source (Join-Path $ROOT "companion-service")
} finally {
    $serviceZipArchive.Dispose()
}

# Resolve source directories
$iosSourceResolved = Resolve-Path $IosSource
$androidSourceResolved = Resolve-Path $AndroidSource

if (-not (Test-Path $iosSourceResolved -PathType Container) -or -not (Test-Path $androidSourceResolved -PathType Container)) {
    throw "--ios-source and --android-source must point to existing source directories"
}

# Create iOS source zip
$iosSourceZipArchive = [System.IO.Compression.ZipFile]::Open($iosSourceZip, "Create")
try {
    Add-Tree -Archive $iosSourceZipArchive -Source $iosSourceResolved -Prefix "TikTokLiveCompanion-iOS"
} finally {
    $iosSourceZipArchive.Dispose()
}

# Create Android source zip
$androidSourceZipArchive = [System.IO.Compression.ZipFile]::Open($androidSourceZip, "Create")
try {
    Add-Tree -Archive $androidSourceZipArchive -Source $androidSourceResolved -Prefix "TikTokLiveCompanion-Android"
} finally {
    $androidSourceZipArchive.Dispose()
}

# Copy Android APK if provided
if ($AndroidApk) {
    $sourceApkResolved = Resolve-Path $AndroidApk -ErrorAction SilentlyContinue
    if (-not $sourceApkResolved -or [System.IO.Path]::GetExtension($sourceApkResolved) -ne ".apk") {
        throw "--android-apk must point to an existing APK"
    }
    Copy-Item $sourceApkResolved $androidApk
}

# Calculate checksums
$artifacts = @($extensionZip, $pluginZip, $serviceZip, $iosSourceZip, $androidSourceZip)
if (Test-Path $androidApk) {
    $artifacts += $androidApk
}

$checksums = @()
foreach ($artifact in $artifacts) {
    $fileBytes = [System.IO.File]::ReadAllBytes($artifact)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($fileBytes)
    $hashString = -join ($hash | ForEach-Object { "{0:x2}" -f $_ })
    $artifactName = Split-Path $artifact -Leaf
    $checksums += "$hashString  $artifactName"
}

Set-Content $checksumFile ($checksums -join "`n") -Encoding UTF8

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
