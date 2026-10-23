param(
    [ValidateSet('work', 'maximum')][string]$Profile = 'work',
    [ValidateSet('local', 'amd64')][string]$Target = 'amd64'
)
$ErrorActionPreference = 'Stop'
$policy = Get-Content (Join-Path $PSScriptRoot 'resource-profiles.json') -Raw | ConvertFrom-Json
$values = $policy.profiles.$Profile
if ($values.cpus -gt 8 -or $values.memory_gib -gt 16 -or $values.swap_gib -ne 8 -or
    $values.memory_swap_gib -ne ($values.memory_gib + $values.swap_gib)) { throw 'Invalid profile' }
$context = if ($Target -eq 'local') { 'desktop-linux' } else { 'tlc-amd64' }
$containers = if ($Target -eq 'local') { @('tlc-cde-cde-1') } else { @('tlc-dev-site-1', 'buildx_buildkit_tlc-amd64-primary-native') }
& docker --context $context update --cpus $values.cpus --memory "$($values.memory_gib)g" --memory-swap "$($values.memory_swap_gib)g" @containers
if ($LASTEXITCODE -ne 0) { throw 'Resource update failed' }
# docker update persists HostConfig across restarts. Compose recreation uses the working defaults.
& docker --context $context inspect --format '{{.Name}} cpu={{.HostConfig.NanoCpus}} ram={{.HostConfig.Memory}} ramPlusSwap={{.HostConfig.MemorySwap}}' @containers
if ($LASTEXITCODE -ne 0) { throw 'Resource readback failed' }
