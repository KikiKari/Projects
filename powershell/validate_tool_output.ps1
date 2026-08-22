#!/usr/bin/env pwsh
# validate_tool_output.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/validate_tool_output.py
# auch in: OpenClaw@gateway2:skills/json-utils/scripts/validate_tool_output.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Validiert Tool-Outputs gegen ein Pydantic-Schema.
Fuer OpenClaw Tool-Call-Validierung.
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$JsonInput,
    
    [Parameter(Mandatory=$true)]
    [string]$Schema,
    
    [switch]$File,
    
    [switch]$Repair = $true,
    
    [switch]$Strict
)

# Funktion zur Erstellung eines dynamischen Modells aus einem JSON-Schema
function Create-DynamicModel {
    param(
        [hashtable]$SchemaData
    )
    
    $typeDefinition = @{
        TypeName = 'DynamicToolOutput'
        Properties = @{}
    }
    
    $properties = $SchemaData.properties ?? @{}
    $requiredFields = $SchemaData.required ?? @()
    
    foreach ($fieldName in $properties.Keys) {
        $fieldInfo = $properties[$fieldName]
        $fieldType = [string] # Default
        
        $jsonType = $fieldInfo.type ?? "string"
        switch ($jsonType) {
            "integer" { $fieldType = [int] }
            "number" { $fieldType = [double] }
            "boolean" { $fieldType = [bool] }
            "array" { $fieldType = [array] }
            "object" { $fieldType = [hashtable] }
            default { $fieldType = [string] }
        }
        
        $defaultValue = $fieldInfo.default
        $isOptional = $fieldName -notin $requiredFields
        
        if ($isOptional) {
            # In PowerShell sind alle Properties optional per se
            # Aber wir koennen den Default-Wert entsprechend setzen
            if ($null -eq $defaultValue) {
                $defaultValue = $null
            }
        } else {
            if ($null -eq $defaultValue) {
                $defaultValue = [System.Management.Automation.Language.NullString]::Value
            }
        }
        
        $typeDefinition.Properties[$fieldName] = @{
            Type = $fieldType
            DefaultValue = $defaultValue
        }
    }
    
    return $typeDefinition
}

# Funktion zur Validierung und Reparatur von JSON
function ParseAndValidate {
    param(
        [string]$RawInput,
        [hashtable]$TypeDefinition,
        [bool]$Repair = $true,
        [bool]$Strict = $false
    )
    
    try {
        # Versuche das JSON zu parsen
        $data = $RawInput | ConvertFrom-Json -ErrorAction Stop
        
        # Erstelle ein neues Objekt basierend auf dem Typdefinition
        $resultObj = New-Object PSObject
        
        # Durchlaufe alle definierten Properties
        foreach ($propName in $TypeDefinition.Properties.Keys) {
            $propDef = $TypeDefinition.Properties[$propName]
            
            # Hole den Wert aus den Daten, falls vorhanden
            $value = $data.$propName
            
            # Wenn Repair aktiv ist und der Wert null ist, verwende den Default-Wert
            if ($Repair -and $null -eq $value -and $null -ne $propDef.DefaultValue) {
                $value = $propDef.DefaultValue
            }
            
            # Fuege die Property zum Ergebnisobjekt hinzu
            $resultObj | Add-Member -MemberType NoteProperty -Name $propName -Value $value
        }
        
        # Bei Strict-Mode pruefen wir, ob unerwartete Felder vorhanden sind
        if ($Strict) {
            $dataProps = $data | Get-Member -MemberType NoteProperty | ForEach-Object Name
            $unexpectedProps = $dataProps | Where-Object { $_ -notin $TypeDefinition.Properties.Keys }
            
            if ($unexpectedProps.Count -gt 0) {
                throw "Strict validation failed: Unexpected properties found: $($unexpectedProps -join ', ')"
            }
        }
        
        return $resultObj
    }
    catch [System.ArgumentException] {
        throw "JSON validation error: $($_.Exception.Message)"
    }
}

try {
    # Lade Schema
    $schemaContent = Get-Content -Path $Schema -Raw -ErrorVariable schemaError
    if ($schemaError) {
        Write-Error "Error loading schema: $schemaError"
        exit 1
    }
    
    $schemaData = $schemaContent | ConvertFrom-Json -AsHashtable
    
    # Lade Input
    $rawInput = ""
    if ($File) {
        $rawInput = Get-Content -Path $JsonInput -Raw -ErrorVariable inputError
        if ($inputError) {
            Write-Error "Error loading input: $inputError"
            exit 1
        }
    } else {
        $rawInput = $JsonInput
    }
    
    # Erstelle dynamisches Modell und validiere
    $modelDefinition = Create-DynamicModel -SchemaData $schemaData
    $result = ParseAndValidate -RawInput $rawInput -TypeDefinition $modelDefinition -Repair $Repair -Strict $Strict
    
    # Konvertiere das Ergebnis zurueck zu JSON
    $resultJson = $result | ConvertTo-Json -Depth 10
    Write-Output $resultJson
}
catch {
    Write-Error "Validation error: $($_.Exception.Message)"
    exit 1
}
