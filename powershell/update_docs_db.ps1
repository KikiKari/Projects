#!/usr/bin/env pwsh
# update_docs_db.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:scripts/update_docs_db.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Scannt alle vorhandenen Dokumentationen und aktualisiert docs.db
#>

$WORKSPACE = "/home/openclaw/.openclaw/workspace"
$DB_PATH = Join-Path $WORKSPACE "db/docs.db"

function Scan-Documentations {
    <#
    .SYNOPSIS
    Scannt alle .md Dateien im Workspace
    #>
    $docs = @()
    
    # Hauptverzeichnis
    Get-ChildItem -Path $WORKSPACE -Filter "*.md" -File | ForEach-Object {
        if (-not $_.LinkType) {
            $docs += @{
                name = $_.Name
                path = '/'
                category = 'main'
                description = Get-Description $_.FullName
                type = 'doc'
                has_symlink = $false
                symlink_path = $null
                last_update = Get-MTime $_.FullName
            }
        }
    }
    
    # WebSearch Verzeichnis
    $websearchDir = Join-Path $WORKSPACE "websearch"
    if (Test-Path $websearchDir) {
        Get-ChildItem -Path $websearchDir -Filter "*.md" -File | ForEach-Object {
            $docs += @{
                name = $_.Name
                path = 'websearch/'
                category = 'websearch'
                description = Get-Description $_.FullName
                type = if ($_.Name -match 'GUIDE') { 'guide' } else { 'config' }
                has_symlink = $true
                symlink_path = "websearch/$($_.Name)"
                last_update = Get-MTime $_.FullName
            }
        }
    }
    
    # MCP Verzeichnis
    $mcpDir = Join-Path $WORKSPACE "mcp"
    if (Test-Path $mcpDir) {
        Get-ChildItem -Path $mcpDir -Filter "*.md" -File | ForEach-Object {
            $isSymlink = $_.LinkType -eq "SymbolicLink"
            $docs += @{
                name = $_.Name
                path = 'mcp/'
                category = 'mcp'
                description = Get-Description $_.FullName
                type = if ($isSymlink) { 'symlink' } else { 'guide' }
                has_symlink = $isSymlink
                symlink_path = if ($isSymlink) { $_.Target } else { $null }
                last_update = Get-MTime $_.FullName
            }
        }
    }
    
    # Docs-Unterverzeichnisse
    $docsDir = Join-Path $WORKSPACE "docs"
    if (Test-Path $docsDir) {
        Get-ChildItem -Path $docsDir -Directory | ForEach-Object {
            $subdir = $_
            Get-ChildItem -Path $subdir.FullName -Filter "*.md" -File | ForEach-Object {
                $docs += @{
                    name = $_.Name
                    path = "docs/$($subdir.Name)/"
                    category = $subdir.Name
                    description = Get-Description $_.FullName
                    type = 'doc'
                    has_symlink = $false
                    symlink_path = $null
                    last_update = Get-MTime $_.FullName
                }
            }
        }
    }
    
    # Cluster, Memory, Reports, Skills
    @('cluster', 'memory', 'reports', 'skills') | ForEach-Object {
        $category = $_
        $catDir = Join-Path $WORKSPACE $category
        if (Test-Path $catDir) {
            Get-ChildItem -Path $catDir -Filter "*.md" -File | ForEach-Object {
                $docs += @{
                    name = $_.Name
                    path = "$category/"
                    category = $category
                    description = Get-Description $_.FullName
                    type = 'doc'
                    has_symlink = $false
                    symlink_path = $null
                    last_update = Get-MTime $_.FullName
                }
            }
        }
    }
    
    return $docs
}

function Get-Description {
    param([string]$FilePath)
    
    <#
    .SYNOPSIS
    Extrahiert erste Zeile als Beschreibung
    #>
    try {
        $firstLine = Get-Content -Path $FilePath -TotalCount 1
        if ($firstLine.StartsWith('#')) {
            return $firstLine.TrimStart('#').Trim()
        }
        if ($firstLine.Length -gt 50) {
            return $firstLine.Substring(0, 50) + '...'
        }
        return $firstLine
    } catch {
        return 'Dokumentation'
    }
}

function Get-MTime {
    param([string]$FilePath)
    
    <#
    .SYNOPSIS
    Gibt letzte Änderung zurück
    #>
    try {
        $mtime = (Get-ItemProperty -Path $FilePath).LastWriteTime
        return $mtime.ToString('yyyy-MM-dd')
    } catch {
        return '2026-04-18'
    }
}

function Update-Database {
    param([array]$Docs)
    
    <#
    .SYNOPSIS
    Aktualisiert docs.db mit allen gefundenen Dokumenten
    #>
    # SQLite connection
    Add-Type -AssemblyName System.Data.SQLite
    $connString = "Data Source=$DB_PATH;Version=3;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection($connString)
    $connection.Open()
    
    $command = $connection.CreateCommand()
    
    # Lösche alte Einträge (außer config)
    $command.CommandText = "DELETE FROM documents WHERE category != 'config'"
    $deleted = $command.ExecuteNonQuery()
    
    # Füge neue ein
    $inserted = 0
    foreach ($doc in $Docs) {
        $command.CommandText = @"
INSERT INTO documents 
(name, path, category, description, type, has_symlink, symlink_path, last_update)
VALUES (@name, @path, @category, @description, @type, @has_symlink, @symlink_path, @last_update)
"@
        $command.Parameters.Clear()
        $command.Parameters.AddWithValue("@name", $doc.name) | Out-Null
        $command.Parameters.AddWithValue("@path", $doc.path) | Out-Null
        $command.Parameters.AddWithValue("@category", $doc.category) | Out-Null
        $command.Parameters.AddWithValue("@description", $doc.description) | Out-Null
        $command.Parameters.AddWithValue("@type", $doc.type) | Out-Null
        $command.Parameters.AddWithValue("@has_symlink", $doc.has_symlink) | Out-Null
        $command.Parameters.AddWithValue("@symlink_path", $doc.symlink_path) | Out-Null
        $command.Parameters.AddWithValue("@last_update", $doc.last_update) | Out-Null
        
        $command.ExecuteNonQuery() | Out-Null
        $inserted++
    }
    
    $connection.Close()
    
    return $inserted
}

function Export-All {
    <#
    .SYNOPSIS
    Erstellt alle Exporte
    #>
    # SQLite connection
    Add-Type -AssemblyName System.Data.SQLite
    $connString = "Data Source=$DB_PATH;Version=3;"
    $connection = New-Object System.Data.SQLite.SQLiteConnection($connString)
    $connection.Open()
    
    # JSON & CSV Export
    @('documents', 'skills', 'symlinks') | ForEach-Object {
        $table = $_
        $command = $connection.CreateCommand()
        $command.CommandText = "SELECT * FROM $table"
        $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($command)
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataset) | Out-Null
        
        $rows = $dataset.Tables[0]
        
        # JSON Export
        $jsonData = @()
        foreach ($row in $rows) {
            $obj = @{}
            for ($i = 0; $i -lt $rows.Columns.Count; $i++) {
                $obj[$rows.Columns[$i].ColumnName] = $row[$i]
            }
            $jsonData += $obj
        }
        $jsonPath = Join-Path $WORKSPACE "db_$table.json"
        $jsonData | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath
        Write-Host "✅ $jsonPath"
        
        # CSV Export
        $csvPath = Join-Path $WORKSPACE "db_$table.csv"
        $headers = ($rows.Columns | ForEach-Object { $_.ColumnName }) -join ','
        $content = @($headers)
        foreach ($row in $rows) {
            $values = @()
            for ($i = 0; $i -lt $rows.Columns.Count; $i++) {
                $values += $row[$i]
            }
            $content += ($values -join ',')
        }
        $content | Set-Content -Path $csvPath
        Write-Host "✅ $csvPath"
    }
    
    $connection.Close()
}

function Main {
    Write-Host ("=" * 60)
    Write-Host "DOCS.DB UPDATER"
    Write-Host ("=" * 60)
    
    Write-Host "`n--- Scanne Dokumentationen ---"
    $docs = Scan-Documentations
    Write-Host "Gefunden: $($docs.Count) Dokumente"
    
    Write-Host "`n--- Aktualisiere docs.db ---"
    $inserted = Update-Database $docs
    Write-Host "✅ $inserted Dokumente in docs.db aktualisiert"
    
    Write-Host "`n--- Erstelle Exporte ---"
    Export-All
    
    Write-Host "`n" + ("=" * 60)
    Write-Host "DOCS.DB AKTUALISIERT"
    Write-Host ("=" * 60)
}

Main
