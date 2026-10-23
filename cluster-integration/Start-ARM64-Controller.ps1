$ErrorActionPreference = 'Stop'
$sshConfig = @{}
& ssh -G tlc-arm64 | ForEach-Object { $pair = $_ -split ' ', 2; if ($pair.Length -eq 2) { $sshConfig[$pair[0]] = $pair[1] } }
$env:TLC_ARM64_HOST = $sshConfig['hostname']
$env:TLC_ARM64_PORT = $sshConfig['port']
$env:TLC_ARM64_USER = $sshConfig['user']
$env:TLC_ARM64_HOST_KEY_ALIAS = $sshConfig['hostkeyalias']
if (!$env:TLC_ARM64_HOST_KEY_ALIAS -or $env:TLC_ARM64_HOST_KEY_ALIAS -eq 'none') { $env:TLC_ARM64_HOST_KEY_ALIAS = $env:TLC_ARM64_HOST }
$env:TLC_CDE_IMAGE = (& docker --context desktop-linux inspect tlc-cde-cde-1 --format '{{.Image}}')
if ($LASTEXITCODE -ne 0) { throw 'Existing CDE image could not be resolved' }
$env:TLC_ANDROID_WORKTREE = Join-Path (Split-Path $PSScriptRoot) 'android-implementation'
if (!(Test-Path -LiteralPath $env:TLC_ANDROID_WORKTREE)) {
    # When published at repository root, the existing checkout is the parent.
    $env:TLC_ANDROID_WORKTREE = Split-Path $PSScriptRoot
}
$env:TLC_ARM64_SUPPORT = $PSScriptRoot
$env:TLC_SSH_KEY = Join-Path $env:USERPROFILE '.ssh/id_ed25519'
$env:TLC_SSH_KNOWN_HOSTS = Join-Path $env:USERPROFILE '.ssh/known_hosts'
foreach ($p in @($env:TLC_ANDROID_WORKTREE, $env:TLC_ARM64_SUPPORT, $env:TLC_SSH_KEY, $env:TLC_SSH_KNOWN_HOSTS)) {
    if (!(Test-Path -LiteralPath $p)) { throw "Required path absent: $p" }
}
& docker --context desktop-linux compose -p tlc-cde -f (Join-Path $PSScriptRoot 'compose.arm64-controller.yml') up -d --no-deps --pull never arm64-build-control
if ($LASTEXITCODE -ne 0) { throw 'Controller creation failed' }
& docker --context desktop-linux compose -p tlc-cde -f (Join-Path $PSScriptRoot 'compose.arm64-controller.yml') exec -T arm64-build-control sh /opt/tlc/arm64-support/tlc-arm64-controller.sh status
if ($LASTEXITCODE -ne 0) { throw 'Native ARM64 connection verification failed' }
