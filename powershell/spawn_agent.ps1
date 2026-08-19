#!/usr/bin/env pwsh
# spawn_agent.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/sub-agents-utils/scripts/spawn_agent.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Sub-Agent spawner - Einfache CLI für sessions_spawn

.DESCRIPTION
Dieses Skript hilft beim Erstellen und Anzeigen von Konfigurationen zum Spawnen von Sub-Agents.
Es unterstützt verschiedene Ausgabeformate wie Tool-Aufrufe, Slash Commands oder reines JSON.

.PARAMETER Task
Die Aufgabenbeschreibung für den zu spawnenden Agenten (erforderlich).

.PARAMETER Label
Ein optionaler Label für den Agenten.

.PARAMETER Model
Das zu verwendende KI-Modell. Muss einer der verfügbaren Modelle entsprechen.

.PARAMETER Thinking
Das Denkniveau des Agenten (low, medium, high).

.PARAMETER Timeout
Timeout in Sekunden (Standard: 900).

.PARAMETER Thread
Aktiviert Thread-Binding.

.PARAMETER Mode
Der Ausführungsmodus (run oder session). Standard ist run.

.PARAMETER Output
Das Ausgabeformat (tool, slash, json). Standard ist tool.

.EXAMPLE
.\spawn_agent.ps1 -Task "Analyze logs"

.EXAMPLE
.\spawn_agent.ps1 -Task "Code review" -Model "openai/gpt-5.6-sol" -Timeout 1800

.EXAMPLE
.\spawn_agent.ps1 -Task "Batch process" -Label "batch-worker" -Thread
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$Task,
    
    [string]$Label,
    
    [ValidateScript({
        $models = Get-Models
        if ($_ -and $_ -notin $models) {
            throw "Modell '$_' ist nicht verfügbar. Verfügbare Modelle: $($models -join ', ')"
        }
        return $true
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

function Get-Models {
    $configPath = $env:OPENCLAW_CONFIG ?? "/home/openclaw/.openclaw/openclaw.json"
    
    try {
        $configContent = Get-Content -Path $configPath -Raw -Encoding UTF8
        $config = $configContent | ConvertFrom-Json
        
        $modelConfig = $config.agents.defaults.model
        $candidates = @($modelConfig.primary) + @($modelConfig.fallbacks)
        
        $models = @()
        foreach ($candidate in $candidates) {
            if ($candidate -is [string] -and $candidate -and -not $candidate.StartsWith("anthropic/")) {
                $models += $candidate
            }
        }
        
        # Entferne Duplikate unter Beibehaltung der Reihenfolge
        $uniqueModels = @()
        foreach ($m in $models) {
            if ($m -notin $uniqueModels) {
                $uniqueModels += $m
            }
        }
        
        if ($uniqueModels.Count -eq 0) {
            throw "Keine allgemein verfügbaren Modelle in $configPath"
        }
        
        return $uniqueModels
    }
    catch {
        Write-Error "Modellkonfiguration kann nicht geladen werden: $configPath`: $_"
        exit 1
    }
}

$MODELS = Get-Models

class SubAgentSpawner {
    static [hashtable] GetSpawnConfig([string]$Task, [string]$Label, [string]$Model, [string]$Thinking, [int]$Timeout, [bool]$Thread, [string]$Mode) {
        $config = @{
            task = $Task
        }
        
        if ($Label) {
            $config["label"] = $Label
        }
        
        if ($Model -and $Model -in $script:MODELS) {
            $config["model"] = $Model
        }
        
        if ($Thinking) {
            $config["thinking"] = $Thinking
        }
        
        if ($Timeout) {
            $config["runTimeoutSeconds"] = $Timeout
        }
        
        if ($Thread) {
            $config["thread"] = $true
            if ($Mode -eq "run") {
                $config["mode"] = "session" # thread requires session mode
            }
        }
        else {
            $config["mode"] = $Mode
        }
        
        return $config
    }
    
    static [void] PrintSpawnCommand([hashtable]$Config) {
        Write-Host ""
        Write-Host "🛠️  Tool-Aufruf:"
        Write-Host ("=" * 50)
        Write-Host "sessions_spawn("
        foreach ($key in $Config.Keys) {
            $value = $Config[$key]
            if ($value -is [string]) {
                Write-Host "    $key=`"$value`""
            }
            else {
                Write-Host "    $key=$value"
            }
        }
        Write-Host ")"
        Write-Host ("=" * 50)
    }
    
    static [void] PrintSlashCommand([hashtable]$Config) {
        $task = $Config["task"] ?? ""
        $label = $Config["label"] ?? "agent"
        $model = $Config["model"] ?? ""
        
        $cmd = "/subagents spawn $label `"$task`""
        if ($model) {
            $cmd += " --model $model"
        }
        if ($Config["thinking"]) {
            $cmd += " --thinking $($Config['thinking'])"
        }
        
        Write-Host ""
        Write-Host "💬 Slash Command:"
        Write-Host ("=" * 50)
        Write-Host $cmd
        Write-Host ("=" * 50)
    }
}

try {
    $spawner = [SubAgentSpawner]::new()
    $config = [SubAgentSpawner]::GetSpawnConfig($Task, $Label, $Model, $Thinking, $Timeout, $Thread.IsPresent, $Mode)
    
    Write-Host "✅ Sub-Agent Konfiguration:"
    $configJson = $config | ConvertTo-Json -Depth 10
    Write-Host $configJson
    
    switch ($Output) {
        "tool" {
            [SubAgentSpawner]::PrintSpawnCommand($config)
        }
        "slash" {
            [SubAgentSpawner]::PrintSlashCommand($config)
        }
        "json" {
            Write-Host ""
            Write-Host "📄 JSON:"
            Write-Host $configJson
            
            # Speichere als Datei
            $fileName = "subagent_$($config['label'] ?? 'spawn').json"
            $outputFile = Join-Path "/tmp" $fileName
            $config | ConvertTo-Json -Depth 10 | Out-File -FilePath $outputFile -Encoding UTF8
            Write-Host "💾 Gespeichert: $outputFile"
        }
    }
}
catch {
    Write-Error $_.Exception.Message
    exit 1
}
