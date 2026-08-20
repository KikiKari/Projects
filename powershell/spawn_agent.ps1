#!/usr/bin/env pwsh
# spawn_agent.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway2:skills/sub-agents-utils/scripts/spawn_agent.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Sub-Agent spawner - Einfache CLI für sessions_spawn

.DESCRIPTION
Dieses Skript hilft beim Erstellen von Konfigurationen zum Starten von Sub-Agents.
Es generiert entweder ein Tool-Kommando, einen Slash-Befehl oder eine JSON-Konfiguration.

.PARAMETER Task
Die Aufgabenbeschreibung (erforderlich)

.PARAMETER Label
Ein optionaler Label für den Agenten

.PARAMETER Model
Das zu verwendende KI-Modell

.PARAMETER Thinking
Das Denkniveau (low, medium, high)

.PARAMETER Timeout
Timeout in Sekunden (Standard: 900)

.PARAMETER Thread
Aktiviert Thread-Binding

.PARAMETER Mode
Der Ausführungsmodus (run oder session, Standard: run)

.PARAMETER Output
Das Ausgabeformat (tool, slash, json, Standard: tool)

.EXAMPLE
.\spawn_agent.ps1 -Task "Analyze logs"

.EXAMPLE
.\spawn_agent.ps1 -Task "Code review" -Model "openrouter/anthropic/claude-haiku-4.5" -Timeout 1800

.EXAMPLE
.\spawn_agent.ps1 -Task "Batch process" -Label "batch-worker" -Thread
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Task,
    
    [string]$Label,
    
    [ValidateScript({
        $validModels = @("openrouter/anthropic/claude-haiku-4.5", "openrouter/google/gemini-pro", "openai/gpt-4")
        if ($validModels -contains $_) { return $true } else { throw "Ungültiges Modell: $_" }
    })]
    [string]$Model,
    
    [ValidateSet("low", "medium", "high")]
    [string]$Thinking,
    
    [int]$Timeout = 900,
    
    [switch]$Thread,
    
    [ValidateSet("run", "session")]
    [string]$Mode = "run",
    
    [ValidateSet("tool", "slash", "json")]
    [string]$Output = "tool"
)

# Workspace-Pfad definieren
$WORKSPACE = "/home/openclaw/.openclaw/workspace"

# Prüfen ob das Modul existiert
if (-not (Test-Path "$WORKSPACE/openclaw_models.ps1")) {
    Write-Error "Modellkonfiguration kann nicht geladen werden: openclaw_models.ps1 nicht gefunden"
    exit 1
}

# Modul laden
try {
    . "$WORKSPACE/openclaw_models.ps1"
    $MODELS = configured_models
} catch {
    Write-Error "Modellkonfiguration kann nicht geladen werden: $_"
    exit 1
}

# Validierung des Models
if ($Model -and $MODELS -notcontains $Model) {
    Write-Error "Ungültiges Modell: $Model"
    exit 1
}

function Get-SpawnConfig {
    param(
        [string]$Task,
        [string]$Label,
        [string]$Model,
        [string]$Thinking,
        [int]$Timeout,
        [bool]$Thread,
        [string]$Mode
    )
    
    $config = @{
        task = $Task
    }
    
    if ($Label) {
        $config.label = $Label
    }
    
    if ($Model -and $MODELS -contains $Model) {
        $config.model = $Model
    }
    
    if ($Thinking) {
        $config.thinking = $Thinking
    }
    
    if ($Timeout) {
        $config.runTimeoutSeconds = $Timeout
    }
    
    if ($Thread) {
        $config.thread = $true
        if ($Mode -eq "run") {
            $config.mode = "session"  # thread erfordert session mode
        }
    } else {
        $config.mode = $Mode
    }
    
    return $config
}

function Print-SpawnCommand {
    param([hashtable]$Config)
    
    Write-Host ""
    Write-Host "🛠️  Tool-Aufruf:"
    Write-Host ("=" * 50)
    Write-Host "sessions_spawn("
    
    foreach ($key in $Config.Keys) {
        $value = $Config[$key]
        if ($value -is [string]) {
            Write-Host "    $key=`"$value`""
        } else {
            Write-Host "    $key=$value"
        }
    }
    
    Write-Host ")"
    Write-Host ("=" * 50)
}

function Print-SlashCommand {
    param([hashtable]$Config)
    
    $task = if ($Config.ContainsKey("task")) { $Config["task"] } else { "" }
    $label = if ($Config.ContainsKey("label")) { $Config["label"] } else { "agent" }
    $model = if ($Config.ContainsKey("model")) { $Config["model"] } else { "" }
    
    $cmd = "/subagents spawn $label `"$task`""
    
    if ($model) {
        $cmd += " --model $model"
    }
    
    if ($Config.ContainsKey("thinking")) {
        $cmd += " --thinking $($Config['thinking'])"
    }
    
    Write-Host ""
    Write-Host "💬 Slash Command:"
    Write-Host ("=" * 50)
    Write-Host $cmd
    Write-Host ("=" * 50)
}

# Hauptausführung
$config = Get-SpawnConfig -Task $Task -Label $Label -Model $Model -Thinking $Thinking -Timeout $Timeout -Thread $Thread.IsPresent -Mode $Mode

Write-Host "✅ Sub-Agent Konfiguration:"
$configJson = $config | ConvertTo-Json -Depth 10
Write-Host $configJson

switch ($Output) {
    "tool" {
        Print-SpawnCommand -Config $config
    }
    "slash" {
        Print-SlashCommand -Config $config
    }
    "json" {
        Write-Host ""
        Write-Host "📄 JSON:"
        Write-Host $configJson
        
        # Speichern als Datei
        $fileName = if ($config.ContainsKey("label")) { "subagent_$($config['label']).json" } else { "subagent_spawn.json" }
        $outputFile = Join-Path "/tmp" $fileName
        
        $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding utf8
        Write-Host "💾 Gespeichert: $outputFile"
    }
}
