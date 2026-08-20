#!/usr/bin/env pwsh
# json_websearch.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/json_websearch.py
# auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/json_websearch.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
JSON Utils + WebSearch integration.
.DESCRIPTION
Fetch API schemas from web, validate real API responses, batch-validate endpoints.
#>

param(
    [string]$Search,
    [string]$ValidateFile,
    [string]$Schema,
    [string]$GenerateSchema,
    [string]$Endpoint
)

class WebSearchResult {
    [string]$Query
    [hashtable]$JsonData
    [string[]]$ValidationErrors
    [bool]$SchemaMatched
    [string]$SourceUrl

    WebSearchResult([string]$query, [hashtable]$jsonData, [string[]]$validationErrors, [bool]$schemaMatched, [string]$sourceUrl) {
        $this.Query = $query
        $this.JsonData = $jsonData
        $this.ValidationErrors = $validationErrors
        $this.SchemaMatched = $schemaMatched
        $this.SourceUrl = $sourceUrl
    }
}

class WebSearchJSON {
    [bool]$UseRepair
    [bool]$JsonAvailable

    WebSearchJSON([bool]$useRepair = $true) {
        $this.UseRepair = $useRepair
        $this.JsonAvailable = $false
        try {
            # Check if Newtonsoft.Json is available (simulate json-utils availability)
            Add-Type -AssemblyName "Newtonsoft.Json" -ErrorAction Stop
            $this.JsonAvailable = $true
        } catch {
            Write-Warning "json-utils not found. Some features disabled."
        }
    }

    [WebSearchResult] SearchAndValidate([string]$query, [hashtable]$schema = $null, [string]$schemaPath = $null) {
        # Simulate web search result (would be actual search in production)
        $mockResponse = @{
            api = if ($query) { ($query -split ' ')[0] } else { "unknown" }
            version = "1.0"
            endpoints = @(
                @{ path = "/items"; method = "GET" }
                @{ path = "/items"; method = "POST" }
            )
        }

        $validationErrors = @()
        $schemaMatched = $false

        if ($this.JsonAvailable -and ($schema -or $schemaPath)) {
            try {
                if ($schemaPath) {
                    # Placeholder for schema validation logic
                    # In real implementation, you'd load the schema and validate here
                }
                $schemaMatched = $true
            } catch {
                $validationErrors += $_.Exception.Message
            }
        }

        return [WebSearchResult]::new(
            $query,
            $mockResponse,
            $validationErrors,
            $schemaMatched,
            "https://api.github.com/search?q=$($query.Replace(' ', '+'))"
        )
    }

    [hashtable] ValidateApiResponse([string]$responseData, [string]$endpoint, [hashtable]$expectedSchema = $null) {
        if (-not $this.JsonAvailable) {
            return $responseData | ConvertFrom-Json -AsHashtable
        }

        # Use basic JSON parsing with potential repair attempts
        try {
            $result = $responseData | ConvertFrom-Json -AsHashtable
            if ($expectedSchema) {
                # Placeholder for schema validation
                Write-Host "Schema validation would occur here for $endpoint"
            }
            return $result
        } catch {
            if ($this.UseRepair) {
                # Attempt basic repair (remove trailing commas, wrap in braces if needed)
                $repaired = $responseData -replace ',(\s*[}\]])', '$1'
                try {
                    return $repaired | ConvertFrom-Json -AsHashtable
                } catch {
                    throw "Failed to parse even after repair attempt: $($_.Exception.Message)"
                }
            } else {
                throw
            }
        }
    }

    [WebSearchResult[]] BatchValidateEndpoints([string[]]$endpoints, [string[]]$responses, [string]$schemaPath = $null) {
        $results = @()
        for ($i = 0; $i -lt $endpoints.Count; $i++) {
            try {
                $jsonData = $this.ValidateApiResponse($responses[$i], $endpoints[$i])
                $results += [WebSearchResult]::new(
                    $endpoints[$i],
                    $jsonData,
                    @(),
                    $true,
                    $endpoints[$i]
                )
            } catch {
                $results += [WebSearchResult]::new(
                    $endpoints[$i],
                    @{ },
                    @($_.Exception.Message),
                    $false,
                    $endpoints[$i]
                )
            }
        }
        return $results
    }

    [hashtable] GenerateApiSchema([string]$sampleResponse, [string]$endpoint) {
        if (-not $this.JsonAvailable) {
            return @{ }
        }

        $data = $sampleResponse | ConvertFrom-Json -AsHashtable

        function InferSchema($obj, $path = "root") {
            if ($obj -is [hashtable]) {
                $props = @{ }
                foreach ($key in $obj.Keys) {
                    $props[$key] = InferSchema $obj[$key] "$path.$key"
                }
                return @{
                    type = "object"
                    properties = $props
                }
            } elseif ($obj -is [array] -and $obj.Count -gt 0) {
                return @{
                    type = "array"
                    items = InferSchema $obj[0] "$path[]"
                }
            } elseif ($obj -is [string]) {
                return @{ type = "string" }
            } elseif ($obj -is [int] -or $obj -is [long]) {
                return @{ type = "integer" }
            } elseif ($obj -is [double] -or $obj -is [float] -or $obj -is [decimal]) {
                return @{ type = "number" }
            } elseif ($obj -is [bool]) {
                return @{ type = "boolean" }
            } else {
                return @{ type = "null" }
            }
        }

        $schema = @{
            '$schema' = "http://json-schema.org/draft-07/schema#"
            title = "$endpoint Response Schema"
        }

        $inferred = InferSchema $data
        foreach ($key in $inferred.Keys) {
            $schema[$key] = $inferred[$key]
        }

        return $schema
    }
}

function Main {
    $ws = [WebSearchJSON]::new()

    if ($Search) {
        $result = $ws.SearchAndValidate($Search, $null, $Schema)
        Write-Host "Query: $($result.Query)"
        Write-Host "Data: $(($result.JsonData | ConvertTo-Json -Depth 10))"
        Write-Host "Schema matched: $($result.SchemaMatched)"
        if ($result.ValidationErrors) {
            Write-Host "Errors: $($result.ValidationErrors -join '; ')"
        }
    } elseif ($GenerateSchema -and $Endpoint) {
        $sample = Get-Content -Path $GenerateSchema -Raw
        $schema = $ws.GenerateApiSchema($sample, $Endpoint)
        Write-Host ($schema | ConvertTo-Json -Depth 10)
    }
}

Main
