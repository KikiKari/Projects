#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "86675b45b0ac372a4169048d569a2e706fa297f4bfdf431d1e24053c1e770d96", "source_sha256": "42646f32f72b1ca4e041673cd4a65a4b6611379252e110d53df9fb001a5ba6de", "target_language": "powershell"}
# git_source_inventory.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/git_source_inventory.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
Git tree inventory and batched selected-blob loading.
#>

function Write-Private {
    param(
        [string]$Path,
        [byte[]]$Data
    )
    
    $fileStream = [System.IO.File]::Open($Path, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)
    try {
        $fileStream.Write($Data, 0, $Data.Length)
    } finally {
        $fileStream.Close()
    }
}

function Get-Snapshot {
    param(
        [object]$Manager,
        [string]$RunId,
        [string]$RunAttempt,
        [string]$WorkflowSha
    )
    
    function Get-RepositoryIndex {
        param([hashtable]$Source)
        
        $name = $Source.repo.ToString()
        $mirror = Join-Path $Manager.QUELLEN_DIR "$name.git"
        
        function Invoke-Git {
            param([string[]]$Args)
            
            $processInfo = New-Object System.Diagnostics.ProcessStartInfo
            $processInfo.FileName = "git"
            $processInfo.Arguments = @("-C", $mirror) + $Args
            $processInfo.UseShellExecute = $false
            $processInfo.RedirectStandardOutput = $true
            $processInfo.RedirectStandardError = $true
            $processInfo.CreateNoWindow = $true
            
            $process = New-Object System.Diagnostics.Process
            $process.StartInfo = $processInfo
            $process.Start() | Out-Null
            
            $output = $process.StandardOutput.ReadToEnd()
            $errorOutput = $process.StandardError.ReadToEnd()
            
            $process.WaitForExit(1800000) # 30 minutes timeout
            
            if ($process.ExitCode -ne 0) {
                throw "Git command failed: $errorOutput"
            }
            
            return [System.Text.Encoding]::UTF8.GetBytes($output)
        }
        
        $refsOutput = Invoke-Git @("for-each-ref", "--format=`%(refname:strip=2)%00`%(objectname)", "refs/heads")
        $refs = [System.Text.Encoding]::UTF8.GetString($refsOutput).Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries)
        $selected = @()
        
        foreach ($line in $refs) {
            $parts = $line.Split("`0", 2)
            if ($parts.Count -eq 2) {
                $branchBytes = [System.Text.Encoding]::UTF8.GetBytes($parts[0])
                $branch = [System.Text.Encoding]::UTF8.GetString($branchBytes)
                $commit = $parts[1].Trim()
                
                if ($Source.branches -eq "alle" -or $Source.branches.Contains($branch)) {
                    $selected += @($branch, $commit)
                }
            }
        }
        
        function Get-BranchIndex {
            param([array]$Item)
            
            $branch = $Item[0]
            $commit = $Item[1]
            $paths = @()
            
            $treeOutput = Invoke-Git @("ls-tree", "-r", "-z", "--full-tree", $commit)
            $entries = [System.Text.Encoding]::UTF8.GetString($treeOutput).Split("`0", [System.StringSplitOptions]::RemoveEmptyEntries)
            
            foreach ($entry in $entries) {
                if ($entry) {
                    $metaAndPath = $entry.Split("`t", 2)
                    if ($metaAndPath.Count -eq 2) {
                        $meta = $metaAndPath[0]
                        $pathText = $metaAndPath[1]
                        
                        $metaParts = $meta.Split(" ")
                        if ($metaParts.Count -ge 2 -and $metaParts[1] -eq "blob") {
                            $extension = [System.IO.Path]::GetExtension($pathText).ToLower()
                            if ($Manager.QUELLSPRACHEN.ContainsKey($extension)) {
                                $paths += $pathText
                            }
                        }
                    }
                }
            }
            
            return @{branch=$branch; data=@{commit=$commit; paths=$paths}}
        }
        
        $branches = @{}
        $jobs = @()
        
        foreach ($item in $selected) {
            $job = Start-Job -ScriptBlock ${function:Get-BranchIndex} -ArgumentList @(,$item)
            $jobs += $job
        }
        
        foreach ($job in $jobs) {
            $result = Receive-Job $job -Wait
            Remove-Job $job
            $branches[$result.branch] = $result.data
        }
        
        if (($branches.Count -eq 0) -or ($Source.branches -ne "alle" -and $branches.Keys -ne $Source.branches)) {
            throw "incomplete source branches"
        }
        
        return @{name=$name; branches=$branches}
    }
    
    $repositories = @{}
    $jobs = @()
    
    foreach ($source in $Manager.QUELLEN) {
        $job = Start-Job -ScriptBlock ${function:Get-RepositoryIndex} -ArgumentList $source
        $jobs += $job
    }
    
    foreach ($job in $jobs) {
        $result = Receive-Job $job -Wait
        Remove-Job $job
        $repositories[$result.name] = $result.branches
    }
    
    return @{
        version = 1
        run_id = $RunId
        run_attempt = $RunAttempt
        workflow_sha = $WorkflowSha
        repositories = $repositories
    }
}

function Prepare-GitSources {
    param(
        [object]$Manager,
        [string]$Directory,
        [hashtable]$State,
        [string]$Priority,
        [int]$Count,
        [string]$RunId,
        [string]$RunAttempt,
        [string]$WorkflowSha
    )
    
    <#
    .SYNOPSIS
    Index pinned Git trees and materialize only selected source blobs.
    #>
    
    function Invoke-GitWithInput {
        param(
            [string]$Mirror,
            [string[]]$Args,
            [byte[]]$Data
        )
        
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = "git"
        $processInfo.Arguments = @("-C", $Mirror) + $Args
        $processInfo.UseShellExecute = $false
        $processInfo.RedirectStandardInput = $true
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.CreateNoWindow = $true
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        $process.Start() | Out-Null
        
        if ($Data) {
            $process.StandardInput.BaseStream.Write($Data, 0, $Data.Length)
            $process.StandardInput.Close()
        }
        
        $output = $process.StandardOutput.ReadToEnd()
        $errorOutput = $process.StandardError.ReadToEnd()
        
        $process.WaitForExit(1800000) # 30 minutes timeout
        
        if ($process.ExitCode -ne 0) {
            throw "Git command failed: $errorOutput"
        }
        
        return [System.Text.Encoding]::UTF8.GetBytes($output)
    }
    
    # Create QUELLEN_DIR if it doesn't exist
    if (!(Test-Path $Manager.QUELLEN_DIR)) {
        New-Item -ItemType Directory -Path $Manager.QUELLEN_DIR | Out-Null
    }
    
    function Update-Source {
        param([hashtable]$Source)
        
        $repo = $Source.repo.ToString()
        $mirror = Join-Path $Manager.QUELLEN_DIR "$repo.git"
        
        if (Test-Path $mirror) {
            $result = & git -C $mirror remote update --prune 2>&1
        } else {
            $url = "https://github.com/$($Manager.GITHUB_BENUTZER)/$repo.git"
            $result = & git clone --mirror --filter=blob:none $url $mirror 2>&1
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "$repo`: Quellspiegel nicht verfuegbar"
        }
    }
    
    # Update all sources in parallel
    $jobs = @()
    foreach ($source in $Manager.QUELLEN) {
        $job = Start-Job -ScriptBlock ${function:Update-Source} -ArgumentList $source
        $jobs += $job
    }
    
    foreach ($job in $jobs) {
        Receive-Job $job -Wait
        Remove-Job $job
    }
    
    $index = Get-Snapshot -Manager $Manager -RunId $RunId -RunAttempt $RunAttempt -WorkflowSha $WorkflowSha
    $sources = @()
    
    function List-Branch {
        param([array]$Item)
        
        $repo = $Item[0]
        $branch = $Item[1]
        $commit = $Item[2]
        $mirror = Join-Path $Manager.QUELLEN_DIR "$repo.git"
        $records = @()
        
        $treeOutput = Invoke-GitWithInput -Mirror $mirror -Args @("ls-tree", "-r", "-z", "--full-tree", $commit)
        $entries = [System.Text.Encoding]::UTF8.GetString($treeOutput).Split("`0", [System.StringSplitOptions]::RemoveEmptyEntries)
        
        foreach ($item in $entries) {
            if (!$item) { continue }
            
            $parts = $item.Split("`t", 2)
            if ($parts.Count -ne 2) { continue }
            
            $metadata = $parts[0]
            $rawPath = $parts[1]
            
            $metaParts = $metadata.Split(" ", 3)
            if ($metaParts.Count -ne 3) { continue }
            
            $mode = $metaParts[0]
            $kind = $metaParts[1]
            $oid = $metaParts[2]
            
            if ($kind -ne "blob" -or ($mode -ne "100644" -and $mode -ne "100755")) {
                continue
            }
            
            $path = $rawPath.Replace("\\", "/")
            $language = $Manager.QUELLSPRACHEN[[System.IO.Path]::GetExtension($path).ToLower()]
            
            if ($null -eq $language) { continue }
            
            $excludeMatch = $false
            foreach ($pattern in $Manager.AUSSCHLUSS) {
                if (("/$path").Contains($pattern)) {
                    $excludeMatch = $true
                    break
                }
            }
            
            if ($excludeMatch) { continue }
            
            if ($oid -notmatch "^[0-9a-f]{40}$") {
                throw "invalid Git blob identity"
            }
            
            $records += ,@($repo, $branch, $commit, $path, $language, $oid)
        }
        
        return $records
    }
    
    $branches = @()
    foreach ($repoDetails in $index.repositories.GetEnumerator()) {
        $repo = $repoDetails.Key
        foreach ($branchData in $repoDetails.Value.GetEnumerator()) {
            $branch = $branchData.Key
            $data = $branchData.Value
            $branches += ,@($repo, $branch, $data.commit)
        }
    }
    
    $jobs = @()
    foreach ($branchItem in $branches) {
        $job = Start-Job -ScriptBlock ${function:List-Branch} -ArgumentList @(,$branchItem)
        $jobs += $job
    }
    
    foreach ($job in $jobs) {
        $records = Receive-Job $job -Wait
        Remove-Job $job
        $sources += $records
    }
    
    $grouped = @{}
    foreach ($sourceItem in $sources) {
        $repo = $sourceItem[0]
        $branch = $sourceItem[1]
        $commit = $sourceItem[2]
        $path = $sourceItem[3]
        $language = $sourceItem[4]
        $oid = $sourceItem[5]
        
        $origin = "$repo@$branch`:$path"
        $item = $grouped[$oid]
        
        if ($null -eq $item) {
            $priorityValue = $Manager._prioritaet($path, $language)
            $item = @{
                blob = $oid
                repo = $repo
                commit = $commit
                path = $path
                sprache = $language
                herkunft = @()
                prioritaet = $priorityValue
            }
            $grouped[$oid] = $item
        }
        
        $item.herkunft += $origin
    }
    
    $rank = @{ high = 0; medium = 1; low = 2 }
    
    $candidates = $grouped.Values | Where-Object {
        $Priority -eq "alle" -or $_.prioritaet -eq $Priority
    } | Sort-Object @{Expression={ $rank[$_.prioritaet] }}, @{Expression={ [System.IO.Path]::GetFileName($_.path) }}
    
    $cursor = $null
    if ($State.ContainsKey("auswahl_blob_cursor") -and $State.auswahl_blob_cursor.ContainsKey($Priority)) {
        $cursor = $State.auswahl_blob_cursor[$Priority]
    }
    
    if ($cursor) {
        $pos = -1
        for ($i = 0; $i -lt $candidates.Count; $i++) {
            if ($candidates[$i].blob -eq $cursor) {
                $pos = $i
                break
            }
        }
        
        if ($pos -ne -1) {
            $candidates = $candidates[($pos + 1)..($candidates.Count - 1)] + $candidates[0..$pos]
        }
    }
    
    $selected = $candidates | Select-Object -First $Count
    $byRepo = @{}
    
    foreach ($item in $selected) {
        if (!$byRepo.ContainsKey($item.repo)) {
            $byRepo[$item.repo] = @()
        }
        $byRepo[$item.repo] += $item
    }
    
    function Read-Blobs {
        param([array]$Pair)
        
        $repo = $Pair[0]
        $items = $Pair[1]
        $mirror = Join-Path $Manager.QUELLEN_DIR "$repo.git"
        
        $requested = ""
        foreach ($item in $items) {
            $requested += "$($item.blob)`n"
        }
        $requestData = [System.Text.Encoding]::ASCII.GetBytes($requested)
        
        $checksOutput = Invoke-GitWithInput -Mirror $mirror -Args @("cat-file", "--batch-check=`%(objectname) `%(objecttype) `%(objectsize)") -Data $requestData
        $checks = [System.Text.Encoding]::UTF8.GetString($checksOutput).Split("`n", [System.StringSplitOptions]::RemoveEmptyEntries)
        
        if ($checks.Count -ne $items.Count) {
            throw "incomplete Git blob metadata"
        }
        
        $eligible = @()
        for ($i = 0; $i -lt $items.Count; $i++) {
            $item = $items[$i]
            $line = $checks[$i]
            $fields = $line.Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)
            
            if ($fields.Count -ne 3 -or $fields[0] -ne $item.blob -or $fields[1] -ne "blob") {
                throw "invalid Git blob metadata"
            }
            
            $size = [int]$fields[2]
            if ($size -le $Manager.MAX_BYTES) {
                $eligible += ,@($item, $size)
            }
        }
        
        if ($eligible.Count -eq 0) {
            return @()
        }
        
        $wanted = ""
        foreach ($pair in $eligible) {
            $item = $pair[0]
            $wanted += "$($item.blob)`n"
        }
        $wantedData = [System.Text.Encoding]::ASCII.GetBytes($wanted)
        
        $outputData = Invoke-GitWithInput -Mirror $mirror -Args @("cat-file", "--batch") -Data $wantedData
        $output = New-Object System.IO.MemoryStream(,$outputData)
        $reader = New-Object System.IO.BinaryReader($output)
        $result = @()
        
        foreach ($pair in $eligible) {
            $item = $pair[0]
            $size = $pair[1]
            
            $headerLine = ""
            $buffer = New-Object byte[] 1024
            $headerBytes = @()
            while ($true) {
                $b = $reader.ReadByte()
                if ($b -eq 10) { # newline
                    break
                }
                $headerBytes += $b
            }
            $headerLine = [System.Text.Encoding]::UTF8.GetString($headerBytes)
            
            $headerParts = $headerLine.TrimEnd().Split(" ")
            if ($headerParts.Count -ne 3 -or $headerParts[0] -ne $item.blob -or $headerParts[1] -ne "blob" -or [int]$headerParts[2] -ne $size) {
                throw "invalid Git blob response"
            }
            
            $raw = $reader.ReadBytes($size)
            $newlineCheck = $reader.ReadByte()
            if ($newlineCheck -ne 10) { # newline
                throw "incomplete Git blob response"
            }
            
            $result += ,@($item, $raw)
        }
        
        return $result
    }
    
    $loaded = @{}
    $jobs = @()
    
    foreach ($repoItems in $byRepo.GetEnumerator()) {
        $pair = @($repoItems.Key, $repoItems.Value)
        $job = Start-Job -ScriptBlock ${function:Read-Blobs} -ArgumentList @(,$pair)
        $jobs += $job
    }
    
    foreach ($job in $jobs) {
        $result = Receive-Job $job -Wait
        Remove-Job $job
        foreach ($itemRaw in $result) {
            $item = $itemRaw[0]
            $raw = $itemRaw[1]
            $loaded[$item.blob] = $raw
        }
    }
    
    $sourceDir = Join-Path $Directory "sources"
    if (!(Test-Path $sourceDir)) {
        New-Item -ItemType Directory -Path $sourceDir -Mode 700 | Out-Null
    }
    
    $inventory = @()
    foreach ($item in $selected) {
        $raw = $loaded[$item.blob]
        if ($null -eq $raw -or ![System.Text.Encoding]::UTF8.GetString($raw).Trim() -or $Manager.enthaelt_zugangsdaten($raw)) {
            continue
        }
        
        $sha256 = [System.Security.Cryptography.SHA256]::Create()
        $digestBytes = $sha256.ComputeHash($raw)
        $digest = [BitConverter]::ToString($digestBytes).Replace("-", "").ToLower()
        $sha256.Dispose()
        
        $target = Join-Path $sourceDir $digest
        if (!(Test-Path $target)) {
            Write-Private -Path $target -Data $raw
        }
        
        $sourcePath = [System.IO.Path]::GetFileName($item.path)
        $sourceStem = [System.IO.Path]::GetFileNameWithoutExtension($item.path)
        
        $inventory += @{
            hash = $digest.Substring(0, 16)
            name = $sourcePath
            stamm = $sourceStem
            sprache = $item.sprache
            bytes = $raw.Length
            pfad = $target
            herkunft = $item.herkunft
            prioritaet = $item.prioritaet
            css_only = $false
            source_blob = $item.blob
            source_repo = $item.repo
            source_commit = $item.commit
            source_path = $item.path
            source_sha256 = $digest
        }
    }
    
    $lastBlob = $null
    if ($selected.Count -gt 0) {
        $lastBlob = $selected[-1].blob
    }
    
    return $index, $inventory, $lastBlob
}
