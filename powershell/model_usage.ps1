#!/usr/bin/env pwsh
# model_usage.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/model-usage/scripts/model_usage.py
# auch in: OpenClaw@gateway2:skills/model-usage/scripts/model_usage.py
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Summarize CodexBar local cost usage by model.

.DESCRIPTION
Defaults to current model (most recent daily entry), or list all models.
#>

param(
    [Parameter()]
    [ValidateSet("codex", "claude")]
    [string]$Provider = "codex",

    [Parameter()]
    [ValidateSet("current", "all")]
    [string]$Mode = "current",

    [Parameter()]
    [string]$Model,

    [Parameter()]
    [string]$Input,

    [Parameter()]
    [int]$Days,

    [Parameter()]
    [ValidateSet("text", "json")]
    [string]$Format = "text",

    [Parameter()]
    [switch]$Pretty
)

function Write-ErrorLine {
    param([string]$Message)
    Write-Error $Message
}

function Invoke-CodexBarCost {
    param([string]$Provider)
    
    $cmd = @("codexbar", "cost", "--format", "json", "--provider", $Provider)
    try {
        $output = & $cmd 2>$null | Out-String
        return $output
    }
    catch [System.Management.Automation.CommandNotFoundException] {
        throw "codexbar not found on PATH. Install CodexBar CLI first."
    }
    catch {
        throw "codexbar cost failed (exit $LASTEXITCODE)."
    }
}

function Load-Payload {
    param(
        [string]$InputPath,
        [string]$Provider
    )
    
    if ($InputPath) {
        if ($InputPath -eq "-") {
            $raw = [Console]::In.ReadToEnd()
        }
        else {
            $raw = Get-Content -Path $InputPath -Raw -Encoding UTF8
        }
        $data = $raw | ConvertFrom-Json
    }
    else {
        $output = Invoke-CodexBarCost -Provider $Provider
        $data = $output | ConvertFrom-Json
    }

    if ($data -is [System.Collections.IDictionary] -or $data.PSObject.TypeNames -contains "System.Management.Automation.PSCustomObject") {
        return $data
    }

    if ($data -is [System.Array] -or $data -is [System.Collections.IEnumerable]) {
        foreach ($entry in $data) {
            if ($entry -is [System.Collections.IDictionary] -or $entry.PSObject.TypeNames -contains "System.Management.Automation.PSCustomObject") {
                if ($entry.provider -eq $Provider) {
                    return $entry
                }
            }
        }
        throw "Provider '$Provider' not found in codexbar payload."
    }

    throw "Unsupported JSON input format."
}

function Parse-DailyEntries {
    param([object]$Payload)
    
    $daily = $Payload.daily
    if (-not $daily) {
        return @()
    }
    if ($daily -isnot [System.Array] -and $daily -isnot [System.Collections.IEnumerable]) {
        return @()
    }
    
    $result = @()
    foreach ($entry in $daily) {
        if ($entry -is [System.Collections.IDictionary] -or $entry.PSObject.TypeNames -contains "System.Management.Automation.PSCustomObject") {
            $result += $entry
        }
    }
    return $result
}

function Parse-Date {
    param([string]$Value)
    
    try {
        return [DateTime]::ParseExact($Value, "yyyy-MM-dd", $null)
    }
    catch {
        return $null
    }
}

function Filter-ByDays {
    param(
        [array]$Entries,
        [int]$Days
    )
    
    if (-not $Days) {
        return $Entries
    }
    
    $cutoff = (Get-Date).Date.AddDays(-($Days - 1))
    $filtered = @()
    
    foreach ($entry in $Entries) {
        $day = $entry.date
        if ($day -isnot [string]) {
            continue
        }
        $parsed = Parse-Date -Value $day
        if ($parsed -and $parsed.Date -ge $cutoff) {
            $filtered += $entry
        }
    }
    return $filtered
}

function Aggregate-Costs {
    param([System.Collections.IEnumerable]$Entries)
    
    $totals = @{}
    foreach ($entry in $Entries) {
        $breakdowns = $entry.modelBreakdowns
        if (-not $breakdowns) {
            continue
        }
        if ($breakdowns -isnot [System.Array] -and $breakdowns -isnot [System.Collections.IEnumerable]) {
            continue
        }
        foreach ($item in $breakdowns) {
            if ($item -isnot [System.Collections.IDictionary] -and $item.PSObject.TypeNames -notcontains "System.Management.Automation.PSCustomObject") {
                continue
            }
            $model = $item.modelName
            $cost = $item.cost
            if ($model -isnot [string]) {
                continue
            }
            if ($cost -isnot [int] -and $cost -isnot [double] -and $cost -isnot [float]) {
                continue
            }
            if (-not $totals.ContainsKey($model)) {
                $totals[$model] = 0.0
            }
            $totals[$model] += [double]$cost
        }
    }
    return $totals
}

function Pick-CurrentModel {
    param([array]$Entries)
    
    if (-not $Entries) {
        return $null, $null
    }
    
    $sortedEntries = $Entries | Sort-Object { $_.date }
    
    for ($i = $sortedEntries.Count - 1; $i -ge 0; $i--) {
        $entry = $sortedEntries[$i]
        $breakdowns = $entry.modelBreakdowns
        if ($breakdowns -is [System.Array] -and $breakdowns.Count -gt 0) {
            $scored = @()
            foreach ($item in $breakdowns) {
                if ($item -isnot [System.Collections.IDictionary] -and $item.PSObject.TypeNames -notcontains "System.Management.Automation.PSCustomObject") {
                    continue
                }
                $model = $item.modelName
                $cost = $item.cost
                if ($model -is [string] -and ($cost -is [int] -or $cost -is [double] -or $cost -is [float])) {
                    $scored += [PSCustomObject]@{
                        Model = $model
                        Cost = [double]$cost
                    }
                }
            }
            if ($scored) {
                $scored = $scored | Sort-Object Cost -Descending
                $dateValue = if ($entry.date -is [string]) { $entry.date } else { $null }
                return $scored[0].Model, $dateValue
            }
        }
        $modelsUsed = $entry.modelsUsed
        if ($modelsUsed -is [System.Array] -and $modelsUsed.Count -gt 0) {
            $last = $modelsUsed[-1]
            if ($last -is [string]) {
                $dateValue = if ($entry.date -is [string]) { $entry.date } else { $null }
                return $last, $dateValue
            }
        }
    }
    return $null, $null
}

function Format-USD {
    param([Nullable[Double]]$Value)
    
    if ($Value -eq $null) {
        return "—"
    }
    return "$" + "{0:N2}" -f $Value
}

function Get-LatestDayCost {
    param(
        [array]$Entries,
        [string]$Model
    )
    
    if (-not $Entries) {
        return $null, $null
    }
    
    $sortedEntries = $Entries | Sort-Object { $_.date }
    
    for ($i = $sortedEntries.Count - 1; $i -ge 0; $i--) {
        $entry = $sortedEntries[$i]
        $breakdowns = $entry.modelBreakdowns
        if ($breakdowns -isnot [System.Array] -and $breakdowns -isnot [System.Collections.IEnumerable]) {
            continue
        }
        foreach ($item in $breakdowns) {
            if ($item -isnot [System.Collections.IDictionary] -and $item.PSObject.TypeNames -notcontains "System.Management.Automation.PSCustomObject") {
                continue
            }
            if ($item.modelName -eq $Model) {
                $cost = if ($item.cost -is [int] -or $item.cost -is [double] -or $item.cost -is [float]) { [double]$item.cost } else { $null }
                $day = if ($entry.date -is [string]) { $entry.date } else { $null }
                return $day, $cost
            }
        }
    }
    return $null, $null
}

function Render-TextCurrent {
    param(
        [string]$Provider,
        [string]$Model,
        [string]$LatestDate,
        [Nullable[Double]]$TotalCost,
        [Nullable[Double]]$LatestCost,
        [string]$LatestCostDate,
        [int]$EntryCount
    )
    
    $lines = @(
        "Provider: $Provider"
        "Current model: $Model"
    )
    
    if ($LatestDate) {
        $lines += "Latest model date: $LatestDate"
    }
    
    $lines += "Total cost (rows): $(Format-USD -Value $TotalCost)"
    
    if ($LatestCostDate) {
        $lines += "Latest day cost: $(Format-USD -Value $LatestCost) ($LatestCostDate)"
    }
    
    $lines += "Daily rows: $EntryCount"
    
    return ($lines -join "`n")
}

function Render-TextAll {
    param(
        [string]$Provider,
        [System.Collections.IDictionary]$Totals
    )
    
    $lines = @(
        "Provider: $Provider"
        "Models:"
    )
    
    $sortedItems = $Totals.GetEnumerator() | Sort-Object { $_.Value } -Descending
    
    foreach ($item in $sortedItems) {
        $lines += "- $($item.Key): $(Format-USD -Value $item.Value)"
    }
    
    return ($lines -join "`n")
}

function Build-JsonCurrent {
    param(
        [string]$Provider,
        [string]$Model,
        [string]$LatestDate,
        [Nullable[Double]]$TotalCost,
        [Nullable[Double]]$LatestCost,
        [string]$LatestCostDate,
        [int]$EntryCount
    )
    
    return @{
        provider = $Provider
        mode = "current"
        model = $Model
        latestModelDate = $LatestDate
        totalCostUSD = $TotalCost
        latestDayCostUSD = $LatestCost
        latestDayCostDate = $LatestCostDate
        dailyRowCount = $EntryCount
    }
}

function Build-JsonAll {
    param(
        [string]$Provider,
        [System.Collections.IDictionary]$Totals
    )
    
    $modelsArray = @()
    $sortedItems = $Totals.GetEnumerator() | Sort-Object { $_.Value } -Descending
    
    foreach ($item in $sortedItems) {
        $modelsArray += @{
            model = $item.Key
            totalCostUSD = $item.Value
        }
    }
    
    return @{
        provider = $Provider
        mode = "all"
        models = $modelsArray
    }
}

try {
    $payload = Load-Payload -InputPath $Input -Provider $Provider
}
catch {
    Write-ErrorLine -Message $_.Exception.Message
    exit 1
}

$entries = Parse-DailyEntries -Payload $payload
$entries = Filter-ByDays -Entries $entries -Days $Days

if ($Mode -eq "current") {
    $model = $Model
    $latestDate = $null
    if (-not $model) {
        $model, $latestDate = Pick-CurrentModel -Entries $entries
    }
    if (-not $model) {
        Write-ErrorLine -Message "No model data found in codexbar cost payload."
        exit 2
    }
    $totals = Aggregate-Costs -Entries $entries
    $totalCost = if ($totals.ContainsKey($model)) { $totals[$model] } else { $null }
    $latestCostDate, $latestCost = Get-LatestDayCost -Entries $entries -Model $model

    if ($Format -eq "json") {
        $payloadOut = Build-JsonCurrent -Provider $Provider -Model $model -LatestDate $latestDate -TotalCost $totalCost -LatestCost $latestCost -LatestCostDate $latestCostDate -EntryCount $entries.Count
        if ($Pretty) {
            $payloadOut | ConvertTo-Json -Depth 10 -EnumsAsStrings
        }
        else {
            $payloadOut | ConvertTo-Json -Depth 10 -EnumsAsStrings -Compress
        }
    }
    else {
        Render-TextCurrent -Provider $Provider -Model $model -LatestDate $latestDate -TotalCost $totalCost -LatestCost $latestCost -LatestCostDate $latestCostDate -EntryCount $entries.Count
    }
    exit 0
}

$totals = Aggregate-Costs -Entries $entries
if (-not $totals -or $totals.Count -eq 0) {
    Write-ErrorLine -Message "No model breakdowns found in codexbar cost payload."
    exit 2
}

if ($Format -eq "json") {
    $payloadOut = Build-JsonAll -Provider $Provider -Totals $totals
    if ($Pretty) {
        $payloadOut | ConvertTo-Json -Depth 10 -EnumsAsStrings
    }
    else {
        $payloadOut | ConvertTo-Json -Depth 10 -EnumsAsStrings -Compress
    }
}
else {
    Render-TextAll -Provider $Provider -Totals $totals
}
exit 0
