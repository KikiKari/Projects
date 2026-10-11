#!/usr/bin/env pwsh
# update_docs_db.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway2:scripts/update_docs_db.py
# Erzeugt: 2026-10-11 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Scan documentation files and refresh docs.db for the mounted workspace.
#>

$WORKSPACE = "/workspace"
$DB_PATH = "$WORKSPACE/db/docs.db"

function Get-DocFiles {
    $excludeDirs = @("node_modules", ".git", "backups")
    Get-ChildItem -Path $WORKSPACE -Recurse -File -Include *.md | Where-Object {
        $relPath = $_.FullName.Substring($WORKSPACE.Length).TrimStart("/\")
        $parts = $relPath -split "[/\\]"
        ($excludeDirs | Where-Object { $parts -contains $_ }).Count -eq 0
    }
}

function Get-FileHashMD5($filePath) {
    $hash = Get-FileHash -Path $filePath -Algorithm MD5
    return $hash.Hash.ToLower()
}

function Get-WordCount($filePath) {
    try {
        $content = Get-Content -Path $filePath -Raw -Encoding UTF8 -ErrorAction Stop
        return ($content -split "\s+" | Where-Object { $_.Trim() -ne "" }).Count
    } catch {
        return 0
    }
}

function Build-Rows {
    $indexed = Get-Date
    $rows = @()
    $files = Get-DocFiles
    foreach ($file in $files) {
        $relativePath = $file.FullName.Substring($WORKSPACE.Length).TrimStart("/\").Replace("\", "/")
        $rows += @{
            path = $relativePath
            content_hash = Get-FileHashMD5($file.FullName)
            last_indexed = $indexed
            word_count = Get-WordCount($file.FullName)
        }
    }
    return $rows
}

function Ensure-Schema($conn) {
    $cmd = $conn.CreateCommand()
    $cmd.CommandText = @"
CREATE TABLE IF NOT EXISTS documents (
    path TEXT PRIMARY KEY,
    content_hash TEXT,
    last_indexed REAL,
    word_count INTEGER
)
"@
    $cmd.ExecuteNonQuery() | Out-Null

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
    if (!(Test-Path (Split-Path $DB_PATH -Parent))) {
        New-Item -ItemType Directory -Path (Split-Path $DB_PATH -Parent) | Out-Null
    }

    $conn = New-Object System.Data.SQLite.SQLiteConnection("Data Source=$DB_PATH")
    $conn.Open()
    try {
        Ensure-Schema($conn)
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = "DELETE FROM documents"
        $cmd.ExecuteNonQuery() | Out-Null

        $insertCmd = $conn.CreateCommand()
        $insertCmd.CommandText = "INSERT INTO documents (path, content_hash, last_indexed, word_count) VALUES (@path, @content_hash, @last_indexed, @word_count)"
        $insertCmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("@path", [System.Data.SqlDbType]::Text)))
        $insertCmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("@content_hash", [System.Data.SqlDbType]::Text)))
        $insertCmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("@last_indexed", [System.Data.SqlDbType]::Real)))
        $insertCmd.Parameters.Add((New-Object System.Data.SQLite.SQLiteParameter("@word_count", [System.Data.SqlDbType]::Integer)))

        foreach ($row in $rows) {
            $insertCmd.Parameters["@path"].Value = $row.path
            $insertCmd.Parameters["@content_hash"].Value = $row.content_hash
            $insertCmd.Parameters["@last_indexed"].Value = $row.last_indexed
            $insertCmd.Parameters["@word_count"].Value = $row.word_count
            $insertCmd.ExecuteNonQuery() | Out-Null
        }
        $conn.Close()
    } catch {
        $conn.Close()
        throw
    }
}

function Export-Table($table) {
    $conn = New-Object System.Data.SQLite.SQLiteConnection("Data Source=$DB_PATH")
    $conn.Open()
    try {
        $cmd = $conn.CreateCommand()
        $cmd.CommandText = "SELECT * FROM $table"
        $adapter = New-Object System.Data.SQLite.SQLiteDataAdapter($cmd)
        $dataset = New-Object System.Data.DataSet
        $adapter.Fill($dataset) | Out-Null
        $data = $dataset.Tables[0]

        $jsonPath = "$WORKSPACE/db_$table.json"
        $csvPath = "$WORKSPACE/db_$table.csv"

        $jsonData = @()
        foreach ($row in $data.Rows) {
            $obj = @{}
            foreach ($col in $data.Columns) {
                $obj[$col.ColumnName] = $row[$col.ColumnName]
            }
            $jsonData += $obj
        }
        $jsonData | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath

        $data | Export-Csv -Path $csvPath -NoTypeInformation
    } finally {
        $conn.Close()
    }
}

function Main {
    Write-Host ("=" * 60)
    Write-Host "DOCS.DB UPDATER"
    Write-Host ("=" * 60)

    $rows = Build-Rows
    Write-Host "Gefunden: $($rows.Count) Dokumente"

    Update-Database($rows)
    Write-Host "✅ $($rows.Count) Dokumente in docs.db aktualisiert"

    Export-Table("documents")
    Export-Table("tags")
    Write-Host "✅ Exporte aktualisiert"

    Write-Host ""
    Write-Host ("=" * 60)
    Write-Host "DOCS.DB AKTUALISIERT"
    Write-Host ("=" * 60)
}

Main
