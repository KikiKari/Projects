[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$indexUri = "https://get.videolan.org/vlc/last/win64/"
$temporaryDirectory = Join-Path ([System.IO.Path]::GetTempPath()) ("tlc-vlc-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $temporaryDirectory | Out-Null

try {
    $index = (Invoke-WebRequest -UseBasicParsing -Uri $indexUri).Content
    $matches = [regex]::Matches($index, 'href="(vlc-(\d+(?:\.\d+)+)-win64\.exe)"', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    $releases = foreach ($match in $matches) {
        $versionText = $match.Groups[2].Value
        if ($versionText -match '^[0-9]+(?:\.[0-9]+)+$') {
            [pscustomobject]@{ File = $match.Groups[1].Value; Version = [version]$versionText }
        }
    }
    $release = $releases | Sort-Object Version -Descending | Select-Object -First 1
    if (-not $release) { throw "Keine stabile VLC-Windows-Version im offiziellen VideoLAN-Verzeichnis gefunden." }

    $installerPath = Join-Path $temporaryDirectory $release.File
    $checksumPath = "$installerPath.sha256"
    Invoke-WebRequest -UseBasicParsing -Uri ($indexUri + $release.File) -OutFile $installerPath
    Invoke-WebRequest -UseBasicParsing -Uri ($indexUri + $release.File + ".sha256") -OutFile $checksumPath

    $expectedHash = ((Get-Content -Raw -LiteralPath $checksumPath) -split '\s+')[0].Trim().ToLowerInvariant()
    $actualHash = (Get-FileHash -LiteralPath $installerPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($expectedHash -notmatch '^[a-f0-9]{64}$' -or $actualHash -ne $expectedHash) { throw "Die offizielle VLC-SHA-256-Prüfung ist fehlgeschlagen." }

    $signature = Get-AuthenticodeSignature -LiteralPath $installerPath
    if ($signature.Status -ne [System.Management.Automation.SignatureStatus]::Valid -or $signature.SignerCertificate.Subject -notmatch 'VideoLAN') {
        throw "Die VideoLAN-Signatur des VLC-Installers ist ungültig."
    }

    $process = Start-Process -FilePath $installerPath -ArgumentList '/S' -Verb RunAs -Wait -PassThru
    if ($process.ExitCode -ne 0) { throw "VLC-Installation endete mit $($process.ExitCode)." }
}
finally {
    Remove-Item -LiteralPath $temporaryDirectory -Recurse -Force -ErrorAction SilentlyContinue
}
