function Get-TlcServicePort {
  param($Config)
  $value = if ($null -ne $Config.port) { [int]$Config.port } else { 43117 }
  if ($value -lt 1 -or $value -gt 65535) { throw "Ungueltiger lokaler Dienstport: $value" }
  return $value
}

function Test-TlcServiceHealth {
  param([int]$Port, [string]$PairingCode)
  try {
    $health = Invoke-RestMethod -Uri "http://127.0.0.1:$Port/v1/health" -Headers @{ Authorization = "Bearer $PairingCode" } -TimeoutSec 5
    return [bool]($health.ok -and $health.bootstrapPairing -and $health.canInstallSherpa)
  } catch { return $false }
}

function Get-TlcListenerPid {
  param([int]$Port)
  try {
    $listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction Stop |
      Where-Object { $_.LocalAddress -in @('127.0.0.1', '0.0.0.0', '::') } | Select-Object -First 1
    if ($listener) { return [int]$listener.OwningProcess }
  } catch {}
  $pattern = '^\s*TCP\s+(?:127\.0\.0\.1|0\.0\.0\.0|\[::\]):' + $Port + '\s+\S+\s+LISTENING\s+(\d+)\s*$'
  $line = netstat -ano -p tcp | Select-String -Pattern $pattern | Select-Object -First 1
  if ($line -and $line.Matches.Count) { return [int]$line.Matches[0].Groups[1].Value }
  return 0
}

function Start-TlcService {
  param([string]$ConfigPath, [string]$ServiceDirectory, [switch]$Restart)
  $current = Get-Content -Raw -LiteralPath $ConfigPath | ConvertFrom-Json
  $servicePort = Get-TlcServicePort $current
  $listenerPid = Get-TlcListenerPid $servicePort
  if ($listenerPid -gt 0) {
    if (-not (Test-TlcServiceHealth $servicePort $current.pairingCode)) {
      throw "Port $servicePort ist belegt; der Dienst bestaetigt die vorhandene Companion-Kopplung nicht. Es wurde kein fremder Prozess beendet."
    }
    if (-not $Restart) { return }
    $listenerProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $listenerPid"
    if (-not $listenerProcess -or $listenerProcess.Name -ine 'node.exe' -or
        $listenerProcess.CommandLine -notmatch '(?i)(?:^|[\\/\s"])server\.mjs(?:"|\s|$)') {
      throw "Der bestaetigte Companion auf Port $servicePort konnte keinem Node-Dienstprozess zugeordnet werden."
    }
    Stop-Process -Id $listenerPid -ErrorAction Stop
    for ($attempt = 0; $attempt -lt 50; $attempt++) {
      if ((Get-TlcListenerPid $servicePort) -eq 0) { break }
      Start-Sleep -Milliseconds 100
    }
    if ((Get-TlcListenerPid $servicePort) -gt 0) { throw "Port $servicePort ist nach dem Beenden noch belegt." }
  }
  $nodePath = (Get-Command node.exe -ErrorAction Stop).Source
  $serverPath = Join-Path $ServiceDirectory 'server.mjs'
  Start-Process -FilePath $nodePath -ArgumentList ('"' + $serverPath + '"') -WorkingDirectory $ServiceDirectory -WindowStyle Hidden | Out-Null
  for ($attempt = 0; $attempt -lt 30; $attempt++) {
    if (Test-TlcServiceHealth $servicePort $current.pairingCode) {
      Write-Host "Companion-Dienst erreichbar: http://127.0.0.1:$servicePort"
      return
    }
    Start-Sleep -Milliseconds 250
  }
  throw "Der Companion-Dienst auf Port $servicePort hat den Start nicht bestaetigt."
}
