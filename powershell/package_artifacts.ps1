#!/usr/bin/env pwsh
# package_artifacts.py — portiert nach powershell
# Quelle: python, Projects@TikTok-Live-Companion:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/package_artifacts.py
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/package_artifacts.py
# auch in: Projects@codex/0pe-177-peak-protection:plugin-source/scripts/package_artifacts.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputDir,

    [string]$AndroidApk,

    [string]$AndroidSource = "$PWD/../../mobile/android",

    [string]$IosSource = "$PWD/../../mobile/ios",

    [string]$NativeSharedSource = "$PWD/../../mobile/shared"
)

$ErrorActionPreference = "Stop"

# Define constants
$ROOT = Resolve-Path "$PSScriptRoot/../.."
$PROJECT_ROOT = Resolve-Path "$ROOT/.."
$EXCLUDED_PARTS = @("__pycache__", ".gradle", ".kotlin", ".cxx", "build", "DerivedData", "xcuserdata", "Pods")

function Add-Tree {
    param(
        [System.IO.Compression.ZipArchive]$Archive,
        [string]$Source,
        [string]$Prefix = ""
    )

    $sourcePath = Get-Item $Source
    $files = Get-ChildItem -Path $sourcePath -Recurse -File | Sort-Object FullName

    foreach ($file in $files) {
        $relativePath = Resolve-Path -Relative -Path $file.FullName -RelativeTo $sourcePath.FullName
        $relativePath = $relativePath.Substring(2) # Remove .\ prefix
        
        # Check if any excluded part is in the path
        $pathParts = $file.FullName.Split([System.IO.Path]::DirectorySeparatorChar)
        $hasExcludedPart = $false
        foreach ($part in $pathParts) {
            if ($EXCLUDED_PARTS -contains $part) {
                $hasExcludedPart = $true
                break
            }
        }
        
        if ($hasExcludedPart -or $file.Extension -eq ".pyc" -or $file.Extension -eq ".aar") {
            continue
        }

        $archivePath = if ($Prefix) { Join-Path $Prefix $relativePath } else { $relativePath }
        $archivePath = $archivePath -replace "\\", "/" # Use forward slashes for zip entries

        $entry = $Archive.CreateEntry($archivePath, [System.IO.Compression.CompressionLevel]::Optimal)
        $entry.LastWriteTime = [DateTime]::new(1980, 1, 1, 0, 0, 0)
        
        # Set executable permissions for gradlew
        if ($file.Name -eq "gradlew") {
            $entry.ExternalAttributes = 0x1FF -shl 16  # 0755 shifted to external attributes position
        } else {
            $entry.ExternalAttributes = 0x1A4 -shl 16  # 0644 shifted to external attributes position
        }

        $stream = $entry.Open()
        try {
            [System.IO.File]::ReadAllBytes($file.FullName) | Set-Content -AsByteStream -Path $stream
        } finally {
            $stream.Close()
        }
    }
}

# Create output directory
$null = New-Item -ItemType Directory -Path $OutputDir -Force

# Load manifest and get version
$manifest = Get-Content "$ROOT/browser-extension/manifest.json" | ConvertFrom-Json
$version = $manifest.version

# Define output paths
$extensionZip = Join-Path $OutputDir "tiktok-live-companion-extension-$version.zip"
$pluginZip = Join-Path $OutputDir "tiktok-live-companion-plugin-$version.zip"
$serviceZip = Join-Path $OutputDir "tiktok-live-companion-service-$version.zip"
$iosSourceZip = Join-Path $OutputDir "tiktok-live-companion-ios-$version-source.zip"
$androidSourceZip = Join-Path $OutputDir "tiktok-live-companion-android-$version-source.zip"
$androidApk = Join-Path $OutputDir "tiktok-live-companion-android-$version.apk"
$extensionDir = Join-Path $OutputDir "tiktok-live-companion-extension-$version"
$checksumFile = Join-Path $OutputDir "tiktok-live-companion-$version-SHA256.txt"

$resolvedExtensionDir = Resolve-Path $extensionDir
$outputDirResolved = Resolve-Path $OutputDir

if ($resolvedExtensionDir.Parent -ne $outputDirResolved) {
    throw "Refusing to package outside the requested output directory"
}

if (Test-Path $extensionDir) {
    Remove-Item -Recurse -Force $extensionDir
}

# Copy browser extension and companion service
Copy-Item -Recurse "$ROOT/browser-extension" $extensionDir
Copy-Item -Recurse "$ROOT/companion-service" "$extensionDir/companion-service"

# Create repair script
Set-Content "$extensionDir/Sprachdienst-reparieren.cmd" '@echo off
call "%~dp0companion-service\Sprachdienst-reparieren.cmd"' -Encoding UTF8

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
$packageJson | ConvertTo-Json -Depth 10 | Out-File "$extensionDir/package.json" -Encoding UTF8

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
    Add-Tree -Archive $serviceZipArchive -Source "$ROOT/companion-service"
} finally {
    $serviceZipArchive.Dispose()
}

# Validate source directories
$iosSourceResolved = Resolve-Path $IosSource
$androidSourceResolved = Resolve-Path $AndroidSource

if (-not (Test-Path -PathType Container $iosSourceResolved) -or 
    -not (Test-Path -PathType Container $androidSourceResolved)) {
    throw "--ios-source and --android-source must point to existing source directories"
}

$nativeSharedResolved = Resolve-Path $NativeSharedSource
if (-not (Test-Path "$nativeSharedResolved/native/tlc_peak_limiter.h" -PathType Leaf)) {
    throw "Shared native limiter source is required for both mobile source packages"
}

# Create iOS source zip
$iosSourceZipArchive = [System.IO.Compression.ZipFile]::Open($iosSourceZip, "Create")
try {
    Add-Tree -Archive $iosSourceZipArchive -Source $iosSourceResolved -Prefix "TikTokLiveCompanion-iOS"
    Add-Tree -Archive $iosSourceZipArchive -Source $nativeSharedResolved -Prefix "shared"
} finally {
    $iosSourceZipArchive.Dispose()
}

# Create Android source zip
$androidSourceZipArchive = [System.IO.Compression.ZipFile]::Open($androidSourceZip, "Create")
try {
    Add-Tree -Archive $androidSourceZipArchive -Source $androidSourceResolved -Prefix "TikTokLiveCompanion-Android"
    Add-Tree -Archive $androidSourceZipArchive -Source $nativeSharedResolved -Prefix "shared"
} finally {
    $androidSourceZipArchive.Dispose()
}

# Handle Android APK if provided
if ($AndroidApk) {
    $sourceApk = Resolve-Path $AndroidApk
    if (-not (Test-Path -PathType Leaf $sourceApk) -or 
        [System.IO.Path]::GetExtension($sourceApk).ToLower() -ne ".apk") {
        throw "--android-apk must point to an existing APK"
    }
    
    if ((Resolve-Path $sourceApk) -ne (Resolve-Path $androidApk)) {
        Copy-Item $sourceApk $androidApk
    }
}

# Calculate checksums
$artifacts = @($extensionZip, $pluginZip, $serviceZip, $iosSourceZip, $androidSourceZip)
if (Test-Path $androidApk) {
    $artifacts += $androidApk
}

$checksums = @()
foreach ($artifact in $artifacts) {
    $bytes = [System.IO.File]::ReadAllBytes($artifact)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha256.ComputeHash($bytes)
    $hexHash = [BitConverter]::ToString($hash) -replace "-", ""
    $fileName = Split-Path $artifact -Leaf
    $checksums += "$hexHash  $fileName"
}
$checksums -join "`n" | Out-File $checksumFile -Encoding UTF8
"`n" | Out-File $checksumFile -Append -Encoding UTF8

# Output result JSON
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

ConvertTo-Json $result -EnumsAsStrings | Write-Output
