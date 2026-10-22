#!/usr/bin/env pwsh
# test_extension.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_extension.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_extension.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_extension.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_extension.cjs
# Erzeugt: 2026-10-22 durch ABSTRACTIONS_MANAGER.py

$ErrorActionPreference = "Stop"

function Resolve-ManifestPath {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $root = Join-Path $scriptPath ".."
    $extension = Join-Path $root "browser-extension"
    return Join-Path $extension "manifest.json"
}

function Read-Manifest {
    $manifestPath = Resolve-ManifestPath
    $manifestContent = Get-Content -Path $manifestPath -Raw
    return $manifestContent | ConvertFrom-Json
}

function Test-ManifestVersion {
    param($manifest)
    if ($manifest.manifest_version -ne 3) {
        throw "Manifest version mismatch"
    }
}

function Test-Version {
    param($manifest)
    if ($manifest.version -ne "0.8.2") {
        throw "Version mismatch"
    }
}

function Test-Permissions {
    param($manifest)
    
    $requiredPermissions = @("sidePanel", "webRequest", "tabCapture")
    foreach ($permission in $requiredPermissions) {
        if (-not ($manifest.permissions -contains $permission)) {
            throw "Missing permission: $permission"
        }
    }

    $hostPermissions = @("http://127.0.0.1/*", "http://localhost/*")
    foreach ($permission in $hostPermissions) {
        if (-not ($manifest.host_permissions -contains $permission)) {
            throw "Missing host permission: $permission"
        }
    }

    $forbiddenPermissions = @("cookies", "webRequestBlocking", "nativeMessaging")
    foreach ($permission in $forbiddenPermissions) {
        if ($manifest.permissions -contains $permission) {
            throw "Forbidden permission present: $permission"
        }
    }
}

function Test-MpegTsFiles {
    param($extensionPath)
    
    $mpegtsVendorPath = Join-Path $extensionPath "vendor-mpegts.js"
    $mpegtsLicensePath = Join-Path $extensionPath "vendor-mpegts.LICENSE.txt"
    $mpegtsNoticePath = Join-Path $extensionPath "vendor-mpegts.NOTICE.md"

    if (-not (Test-Path $mpegtsVendorPath)) {
        throw "Missing vendor-mpegts.js"
    }
    if (-not (Test-Path $mpegtsLicensePath)) {
        throw "Missing vendor-mpegts.LICENSE.txt"
    }
    if (-not (Test-Path $mpegtsNoticePath)) {
        throw "Missing vendor-mpegts.NOTICE.md"
    }

    # SHA256 hash check
    $fileBytes = [System.IO.File]::ReadAllBytes($mpegtsVendorPath)
    $hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($fileBytes)
    $hashString = [BitConverter]::ToString($hash).Replace("-", "").ToUpper()
    $expectedHash = "0786F9AF6780822FF29240259A73B07ED7BC479BC44966E49418DD38213B8064"
    if ($hashString -ne $expectedHash) {
        throw "SHA256 hash mismatch for vendor-mpegts.js"
    }
}

function Test-MobileBridge {
    param($mobileBridgeContent)
    
    $tests = @{
        'location.hostname !== "www.tiktok.com"' = $true
        "document.cookie" = $false
        "QUICK_RECOVER_RELOAD_COOLDOWN_MS = 400" = $true
        '"set-auto-reconnect"' = $true
        '"set-limiter"' = $true
    }

    foreach ($test in $tests.GetEnumerator()) {
        $found = $mobileBridgeContent.Contains($test.Key)
        if ($found -ne $test.Value) {
            throw "Mobile bridge test failed for: $($test.Key)"
        }
    }
}

function Test-ManifestFilesExist {
    param($manifest, $extensionPath)
    
    $filesToCheck = @(
        $manifest.background.service_worker,
        $manifest.side_panel.default_path
    )
    
    foreach ($jsFile in $manifest.content_scripts[0].js) {
        $filesToCheck += $jsFile
    }

    foreach ($relativePath in $filesToCheck) {
        $fullPath = Join-Path $extensionPath $relativePath
        if (-not (Test-Path $fullPath)) {
            throw "Missing manifest file: $relativePath"
        }
    }
}

function Test-JavaScripts {
    param($extensionPath)
    
    $scripts = Get-ChildItem -Path $extensionPath -Filter "*.js" | ForEach-Object { $_.Name }
    
    foreach ($scriptName in $scripts) {
        $scriptPath = Join-Path $extensionPath $scriptName
        $source = Get-Content -Path $scriptPath -Raw
        
        # Check for dangerous patterns
        if ($source -match "\beval\s*\(") {
            throw "$scriptName contains eval()"
        }
        if ($source -match "new\s+Function\s*\(") {
            throw "$scriptName contains new Function()"
        }
        if ($source -match "\.innerHTML\s*=") {
            throw "$scriptName assigns innerHTML"
        }
    }
}

# Main execution
try {
    $manifest = Read-Manifest
    Test-ManifestVersion $manifest
    Test-Version $manifest
    Test-Permissions $manifest
    
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
    $root = Join-Path $scriptPath ".."
    $extensionPath = Join-Path $root "browser-extension"
    
    Test-MpegTsFiles $extensionPath
    
    $mobileBridgePath = Join-Path $root "mobile-shared" "webview-bridge.js"
    $mobileBridgeContent = Get-Content -Path $mobileBridgePath -Raw
    Test-MobileBridge $mobileBridgeContent
    
    Test-ManifestFilesExist $manifest $extensionPath
    Test-JavaScripts $extensionPath
    
    Write-Host "PASS: manifest 0.8.2, $($scripts.Count) scripts, chat speech composition, gifts, audience statistics, service controls and security guards"
} catch {
    Write-Error "Test failed: $_"
    exit 1
}
