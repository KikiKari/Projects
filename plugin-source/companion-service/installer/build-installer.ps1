param(
  [string]$IsccPath = "",
  [string]$SignCommand = ""
)

$ErrorActionPreference = "Stop"
$version = "0.7.2"
$nodeVersion = "24.15.0"
$installerDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$serviceDir = Split-Path -Parent $installerDir
$stageDir = Join-Path $installerDir "stage"
$nodeZip = Join-Path $env:TEMP "node-v$nodeVersion-win-x64.zip"
$nodeUrl = "https://nodejs.org/dist/v$nodeVersion/node-v$nodeVersion-win-x64.zip"

if (Test-Path -LiteralPath $stageDir) {
  $resolvedStageDir = (Resolve-Path -LiteralPath $stageDir).Path
  $resolvedInstallerDir = (Resolve-Path -LiteralPath $installerDir).Path
  if (-not $resolvedStageDir.StartsWith($resolvedInstallerDir + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw "Staging-Verzeichnis liegt außerhalb des Installer-Verzeichnisses."
  }
  Remove-Item -LiteralPath $stageDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path (Join-Path $stageDir "service") | Out-Null

$checksums = (Invoke-WebRequest -Uri "https://nodejs.org/dist/v$nodeVersion/SHASUMS256.txt").Content
$expected = [regex]::Match($checksums, "(?m)^([0-9a-f]{64})  node-v$([regex]::Escape($nodeVersion))-win-x64\.zip$").Groups[1].Value
if (-not $expected) { throw "Die offizielle SHA-256-Prüfsumme der festgelegten Node-Laufzeit fehlt." }
$actual = if (Test-Path -LiteralPath $nodeZip) { (Get-FileHash -Algorithm SHA256 -LiteralPath $nodeZip).Hash.ToLowerInvariant() } else { "" }
if ($actual -ne $expected) {
  Invoke-WebRequest -Uri "$nodeUrl" -OutFile $nodeZip
  $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $nodeZip).Hash.ToLowerInvariant()
}
if ($actual -ne $expected) {
  throw "Die SHA-256-Prüfung der festgelegten Node-Laufzeit ist fehlgeschlagen."
}

$nodeExtract = Join-Path $stageDir "node-extract"
Expand-Archive -LiteralPath $nodeZip -DestinationPath $nodeExtract
$nodeSource = Join-Path $nodeExtract "node-v$nodeVersion-win-x64"
$nodeStage = Join-Path $stageDir "node"
New-Item -ItemType Directory -Force -Path $nodeStage | Out-Null
Copy-Item -LiteralPath (Join-Path $nodeSource "node.exe") -Destination $nodeStage
Copy-Item -LiteralPath (Join-Path $nodeSource "LICENSE") -Destination $nodeStage

$serviceFiles = @("server.mjs", "native-host.mjs", "synthesize.ps1", "package.json", "README.md")
foreach ($file in $serviceFiles) {
  Copy-Item -LiteralPath (Join-Path $serviceDir $file) -Destination (Join-Path $stageDir "service")
}

$launcherSourcePath = Join-Path $installerDir "native-host-launcher.cs"
$launcherOutputPath = Join-Path $stageDir "native-host-launcher.exe"
$compileCommand = "`$source = Get-Content -Raw -LiteralPath '$launcherSourcePath'; Add-Type -TypeDefinition `$source -OutputAssembly '$launcherOutputPath' -OutputType ConsoleApplication"
& powershell.exe -NoProfile -NonInteractive -Command $compileCommand
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $launcherOutputPath)) {
  throw "Der Native-Host-Launcher konnte nicht kompiliert werden."
}

if (-not $IsccPath) {
  $candidate = Get-Command ISCC.exe -ErrorAction SilentlyContinue
  if ($candidate) { $IsccPath = $candidate.Source }
}
if (-not $IsccPath -or -not (Test-Path -LiteralPath $IsccPath)) {
  throw "ISCC.exe wurde nicht gefunden. Inno Setup 6 installieren oder -IsccPath angeben."
}

$arguments = @((Join-Path $installerDir "tiktok-live-companion.iss"))
if ($SignCommand) {
  $arguments = @("/DSignedBuild", "/Stlcsign=$SignCommand") + $arguments
}
& $IsccPath @arguments
if ($LASTEXITCODE -ne 0) { throw "Inno Setup endete mit Code $LASTEXITCODE." }

$suffix = if ($SignCommand) { "" } else { "-unsigned-dev" }
$output = Join-Path $installerDir "output\tiktok-live-companion-setup-$version$suffix.exe"
if (-not (Test-Path -LiteralPath $output)) { throw "Installer wurde nicht erzeugt: $output" }
Write-Output $output
