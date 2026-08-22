#!/usr/bin/env pwsh
# update_docs_db.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway2:scripts/update_docs_db.py
# Erzeugt: 2026-08-22 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Scan documentation files and refresh docs.db for the mounted workspace.
#>

param()

$ErrorActionPreference = "Stop"

# Determine workspace path
$workspacePath = $env:OPENCLAW_WORKSPACE
if (-not $workspacePath) {
    $scriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent
    $workspacePath = Split-Path $scriptDir -Parent
}
$workspace = [System.IO.Path]::GetFullPath($workspacePath)
$dbPath = Join-Path $workspace "docs.db"

function Get-DocFiles {
    Get-ChildItem -Path $workspace -Recurse -File -Include "*.md" | Where-Object {
        $relPath = $_.FullName.Substring($workspace.Length + 1) -replace '\\', '/'
        $parts = $relPath.Split('/')
        -not ($parts | Where-Object { @('node_modules', '.git', 'backups') -contains $_ })
    }
}

function Get-FileHashMD5($filePath) {
    $hasher = [System.Security.Cryptography.MD5]::Create()
    try {
        $stream = [System.IO.File]::OpenRead($filePath)
        try {
            $hashBytes = $hasher.ComputeHash($stream)
            return [BitConverter]::ToString($hashBytes).Replace('-', '').ToLowerInvariant()
        } finally {
            $stream.Close()
        }
    } finally {
        $hasher.Dispose()
    }
}

function Get-WordCount($filePath) {
    try {
        $content = [System.IO.File]::ReadAllText($filePath, [System.Text.Encoding]::UTF8)
        return ($content -split '\s+' | Where-Object { $_.Trim() }).Count
    } catch {
        return 0
    }
}

function Build-Rows {
    $indexed = [DateTimeOffset]::Now.ToUnixTimeSeconds()
    $rows = @()
    
    Get-DocFiles | ForEach-Object {
        $relativePath = $_.FullName.Substring($workspace.Length + 1) -replace '\\', '/'
        $rows += @{
            path = $relativePath
            content_hash = Get-FileHashMD5($_.FullName)
            last_indexed = $indexed
            word_count = Get-WordCount($_.FullName)
        }
    }
    
    return $rows
}

function Ensure-Schema($connection) {
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = @"
CREATE TABLE IF NOT EXISTS documents (
    path TEXT PRIMARY KEY,
    content_hash TEXT,
    last_indexed REAL,
    word_count INTEGER
)
"@
    $cmd.ExecuteNonQuery() | Out-Null
    
    $cmd = $connection.CreateCommand()
    $cmd.CommandText = @"
CREATE TABLE IF NOT EXISTS tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    path TEXT,
    tag TEXT
)
"@
    $cmd.ExecuteNonQuery() | Out-Null
}

function Update-Database($rows) {
    Add-Type -AssemblyName System.Data.SQLite
    $connectionString = "Data Source=$dbPath;Version=3;"
    $conn = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
    $conn.Open()
    
    try {
        Ensure-Schema($conn)
        
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = "DELETE FROM documents"
        $cmd.ExecuteNonQuery() | Out-Null
        
        foreach ($row in $rows) {
            $cmd = $conn.CreateCommand()
            $cmd.CommandText = "INSERT INTO documents (path, content_hash, last_indexed, word_count) VALUES (@path, @content_hash, @last_indexed, @word_count)"
            $cmd.Parameters.AddWithValue("@path", $row.path) | Out-Null
            $cmd.Parameters.AddWithValue("@content_hash", $row.content_hash) | Out-Null
            $cmd.Parameters.AddWithValue("@last_indexed", $row.last_indexed) | Out-Null
            $cmd.Parameters.AddWithValue("@word_count", $row.word_count) | Out-Null
            $cmd.ExecuteNonQuery() | Out-Null
        }
        
        $conn.Close()
    } catch {
        $conn.Close()
        throw
    }
}

function Export-Table($table) {
    Add-Type -AssemblyName System.Data.SQLite
    $connectionString = "Data Source=$dbPath;Version=3;"
    $conn = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
    $conn.Open()
    
    try {
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = "SELECT * FROM $table"
        $reader = $cmd.ExecuteReader()
        
        $data = @()
        $columns = @()
        for ($i = 0; $i -lt $reader.FieldCount; $i++) {
            $columns += $reader.GetName($i)
        }
        
        while ($reader.Read()) {
            $row = @{}
            foreach ($col in $columns) {
                $row[$col] = $reader[$col]
            }
            $data += $row
        }
        $reader.Close()
        
        $jsonPath = Join-Path $workspace "db_$table.json"
        $jsonData = $data | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText($jsonPath, $jsonData, [System.Text.Encoding]::UTF8)
        
        $csvPath = Join-Path $workspace "db_$table.csv"
        if ($data.Count -gt 0) {
            $header = ($columns -join ',')
            $lines = @($header)
            foreach ($item in $data) {
                $values = @()
                foreach ($col in $columns) {
                    $value = $item[$col]
                    if ($null -eq $value) { $value = "" }
                    if ($value.ToString().Contains(',') -or $value.ToString().Contains('"') -or $value.ToString().Contains("`n")) {
                        $value = '"' + $value.ToString().Replace('"', '""') + '"'
                    }
                    $values += $value
                }
                $lines += ($values -join ',')
            }
            [System.IO.File]::WriteAllLines($csvPath, $lines, [System.Text.Encoding]::UTF8)
        } else {
            [System.IO.File]::WriteAllLines($csvPath, @(""), [System.Text.Encoding]::UTF8)
        }
    } finally {
        $conn.Close()
    }
}

function Main {
    Write-Host ('=' * 60)
    Write-Host 'DOCS.DB UPDATER'
    Write-Host ('=' * 60)
    
    $rows = Build-Rows
    Write-Host "Gefunden: $($rows.Count) Dokumente"
    
    Update-Database($rows)
    Write-Host "✅ $($rows.Count) Dokumente in docs.db aktualisiert"
    
    Export-Table("documents")
    Export-Table("tags")
    Write-Host '✅ Exporte aktualisiert'
    
    Write-Host ""
    Write-Host ('=' * 60)
    Write-Host 'DOCS.DB AKTUALISIERT'
    Write-Host ('=' * 60)
}

Main
