#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "3c63ccd83dab21a1d0767de93d28fe18730bb2371cd996d28596284d78aea837", "source_sha256": "502dcda47466a4ab74da59badbe4b12c4782ed031c43d5038f8bd8534373cd35", "target_language": "powershell"}
# model_usage.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/model-usage/scripts/model_usage.py
# auch in: OpenClaw@gateway2:skills/model-usage/scripts/model_usage.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Summarize CodexBar local cost usage by model.

.DESCRIPTION
Defaults to current model (most recent daily entry), or list all models.
#>

param(
    [Parameter()][ValidateSet("codex", "claude")][string]$Provider = "codex",
    [Parameter()][ValidateSet("current", "all")][string]$Mode = "current",
    [Parameter()][string]$Model,
    [Parameter()][string]$Input,
    [Parameter()][int]$Days,
    [Parameter()][ValidateSet("text", "json")][string]$Format = "text",
    [Parameter()][switch]$Pretty
)

function Write-ErrorLine {
    param([string]$Message)
    Write-Error $Message
}

function Invoke-CodexbarCost {
    param([string]$ProviderParam)
    $cmd = @("codexbar", "cost", "--format", "json", "--provider", $ProviderParam)
    try {
        $output = & $cmd | Out-String
        return $output
    }
    catch [System.Management.Automation.CommandNotFoundException] {
        throw "codexbar not found on PATH. Install CodexBar CLI first."
    }
    catch {
        throw "codexbar cost failed (exit $($_.Exception.Message))."
    }
}

function Load-Payload {
    param([string]$InputPath, [string]$ProviderLoad)
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
        $output = Invoke-CodexbarCost -ProviderParam $ProviderLoad
        $data = $output | ConvertFrom-Json
    }

    if ($data -is [System.Collections.IDictionary] -or $data.PSObject.TypeNames -contains "System.Management.Automation.PSCustomObject") {
        return $data
    }

    if ($data -is [System.Array] -or $data -is [System.Collections.IList]) {
        foreach ($entry in $data) {
            if ($entry -is [System.Collections.IDictionary] -and $entry.provider -eq $ProviderLoad) {
                return $entry
            }
        }
        throw "Provider '$ProviderLoad' not found in codexbar payload."
    }

    throw "Unsupported JSON input format."
}

function Parse-DailyEntries {
    param($Payload)
    $daily = $Payload.daily
    if (-not $daily) {
        return @()
    }
    if (-not ($daily -is [System.Array] -or $daily -is [System.Collections.IList])) {
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

function Parse-DateValue {
    param([string]$Value)
    try {
        return [DateTime]::ParseExact($Value, "yyyy-MM-dd", $null).Date
    }
    catch {
        return $null
    }
}

function Filter-ByDays {
    param([array]$Entries, [int]$DaysFilter)
    if (-not $DaysFilter) {
        return $Entries
    }
    $cutoff = (Get-Date).Date.AddDays(-($DaysFilter - 1))
    $filtered = @()
    foreach ($entry in $Entries) {
        $day = $entry.date
        if ($day -is [string]) {
            $parsed = Parse-DateValue -Value $day
            if ($parsed -and $parsed -ge $cutoff) {
                $filtered += $entry
            }
        }
    }
    return $filtered
}

function Aggregate-Costs {
    param([array]$Entries)
    $totals = @{}
    foreach ($entry in $Entries) {
        $breakdowns = $entry.modelBreakdowns
        if (-not $breakdowns) {
            continue
        }
        if (-not ($breakdowns -is [System.Array] -or $breakdowns -is [System.Collections.IList])) {
            continue
        }
        foreach ($item in $breakdowns) {
            if (-not ($item -is [System.Collections.IDictionary] -or $item.PSObject.TypeNames -contains "System.Management.Automation.PSCustomObject")) {
                continue
            }
            $model = $item.modelName
            $cost = $item.cost
            if ($model -is [string] -and ($cost -is [int] -or $cost -is [double] -or $cost -is [decimal])) {
                if (-not $totals.ContainsKey($model)) {
                    $totals[$model] = 0.0
                }
                $totals[$model] += [double]$cost
            }
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
    [array]::Reverse($sortedEntries)
    foreach ($entry in $sortedEntries) {
        $breakdowns = $entry.modelBreakdowns
        if ($breakdowns -is [System.Array] -and $breakdowns.Count -gt 0) {
            $scored = @()
            foreach ($item in $breakdowns) {
                if (-not ($item -is [System.Collections.IDictionary] -or $item.PSObject.TypeNames -contains "System.Management.Automation.PSCustomObject")) {
                    continue
                }
                $model = $item.modelName
                $cost = $item.cost
                if ($model -is [string] -and ($cost -is [int] -or $cost -is [double] -or $cost -is [decimal])) {
                    $scored += [PSCustomObject]@{
                        model = $model
                        cost  = [double]$cost
                    }
                }
            }
            if ($scored.Count -gt 0) {
                $scored = $scored | Sort-Object cost -Descending
                return $scored[0].model, $(if ($entry.date -is [string]) { $entry.date } else { $null })
            }
        }
        $modelsUsed = $entry.modelsUsed
        if ($modelsUsed -is [System.Array] -and $modelsUsed.Count -gt 0) {
            $last = $modelsUsed[-1]
            if ($last -is [string]) {
                return $last, $(if ($entry.date -is [string]) { $entry.date } else { $null })
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
    return "$('{0:N2}' -f $Value)"
}

function Get-LatestDayCost {
    param([array]$Entries, [string]$Model)
    if (-not $Entries) {
        return $null, $null
    }
    $sortedEntries = $Entries | Sort-Object { $_.date }
    [array]::Reverse($sortedEntries)
    foreach ($entry in $sortedEntries) {
        $breakdowns = $entry.modelBreakdowns
        if (-not ($breakdowns -is [System.Array] -or $breakdowns -is [System.Collections.IList])) {
            continue
        }
        foreach ($item in $breakdowns) {
            if (-not ($item -is [System.Collections.IDictionary] -or $item.PSObject.TypeNames -contains "System.Management.Automation.PSCustomObject")) {
                continue
            }
            if ($item.modelName -eq $Model) {
                $cost = if ($item.cost -is [int] -or $item.cost -is [double] -or $item.cost -is [decimal]) { [double]$item.cost } else { $null }
                $day = if ($entry.date -is [string]) { $entry.date } else { $null }
                return $day, $cost
            }
        }
    }
    return $null, $null
}

function Render-TextCurrent {
    param(
        [string]$ProviderRender,
        [string]$ModelRender,
        [string]$LatestDate,
        [Nullable[Double]]$TotalCost,
        [Nullable[Double]]$LatestCost,
        [string]$LatestCostDate,
        [int]$EntryCount
    )
    $lines = @(
        "Provider: $ProviderRender"
        "Current model: $ModelRender"
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
    param([string]$ProviderRender, [hashtable]$Totals)
    $lines = @(
        "Provider: $ProviderRender"
        "Models:"
    )
    $sorted = $Totals.GetEnumerator() | Sort-Object Value -Descending
    foreach ($pair in $sorted) {
        $lines += "- $($pair.Key): $(Format-USD -Value $pair.Value)"
    }
    return ($lines -join "`n")
}

function Build-JSONCurrent {
    param(
        [string]$ProviderBuild,
        [string]$ModelBuild,
        [string]$LatestDate,
        [Nullable[Double]]$TotalCost,
        [Nullable[Double]]$LatestCost,
        [string]$LatestCostDate,
        [int]$EntryCount
    )
    return @{
        provider          = $ProviderBuild
        mode              = "current"
        model             = $ModelBuild
        latestModelDate   = $LatestDate
        totalCostUSD      = $TotalCost
        latestDayCostUSD  = $LatestCost
        latestDayCostDate = $LatestCostDate
        dailyRowCount     = $EntryCount
    }
}

function Build-JSONAll {
    param([string]$ProviderBuild, [hashtable]$Totals)
    $modelsArray = @()
    $sorted = $Totals.GetEnumerator() | Sort-Object Value -Descending
    foreach ($pair in $sorted) {
        $modelsArray += @{
            model        = $pair.Key
            totalCostUSD = $pair.Value
        }
    }
    return @{
        provider = $ProviderBuild
        mode     = "all"
        models   = $modelsArray
    }
}

try {
    $payload = Load-Payload -InputPath $Input -ProviderLoad $Provider
}
catch {
    Write-ErrorLine -Message $_.Exception.Message
    exit 1
}

$entries = Parse-DailyEntries -Payload $payload
$entries = Filter-ByDays -Entries $entries -DaysFilter $Days

if ($Mode -eq "current") {
    $model = $Model
    $latestDate = $null
    if (-not $model) {
        $modelResult = Pick-CurrentModel -Entries $entries
        $model = $modelResult[0]
        $latestDate = $modelResult[1]
    }
    if (-not $model) {
        Write-ErrorLine -Message "No model data found in codexbar cost payload."
        exit 2
    }
    $totals = Aggregate-Costs -Entries $entries
    $totalCost = if ($totals.ContainsKey($model)) { $totals[$model] } else { $null }
    $latestCostResult = Get-LatestDayCost -Entries $entries -Model $model
    $latestCostDate = $latestCostResult[0]
    $latestCost = $latestCostResult[1]

    if ($Format -eq "json") {
        $payloadOut = Build-JSONCurrent -ProviderBuild $Provider -ModelBuild $model -LatestDate $latestDate -TotalCost $totalCost -LatestCost $latestCost -LatestCostDate $latestCostDate -EntryCount $entries.Count
        if ($Pretty) {
            $jsonOutput = $payloadOut | ConvertTo-Json -Depth 10 -EnumsAsStrings
        }
        else {
            $jsonOutput = $payloadOut | ConvertTo-Json -Depth 10 -EnumsAsStrings -Compress
        }
        Write-Output $jsonOutput
    }
    else {
        $textOutput = Render-TextCurrent -ProviderRender $Provider -ModelRender $model -LatestDate $latestDate -TotalCost $totalCost -LatestCost $latestCost -LatestCostDate $latestCostDate -EntryCount $entries.Count
        Write-Output $textOutput
    }
    exit 0
}

$totals = Aggregate-Costs -Entries $entries
if (-not $totals -or $totals.Count -eq 0) {
    Write-ErrorLine -Message "No model breakdowns found in codexbar cost payload."
    exit 2
}

if ($Format -eq "json") {
    $payloadOut = Build-JSONAll -ProviderBuild $Provider -Totals $totals
    if ($Pretty) {
        $jsonOutput = $payloadOut | ConvertTo-Json -Depth 10 -EnumsAsStrings
    }
    else {
        $jsonOutput = $payloadOut | ConvertTo-Json -Depth 10 -EnumsAsStrings -Compress
    }
    Write-Output $jsonOutput
}
else {
    $textOutput = Render-TextAll -ProviderRender $Provider -Totals $totals
    Write-Output $textOutput
}
exit 0
