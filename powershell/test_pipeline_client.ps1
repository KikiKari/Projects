#!/usr/bin/env pwsh
# test_pipeline_client.cjs — portiert nach powershell
# Quelle: javascript, Projects@TikTok-Live-Companion:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/scripts/test_pipeline_client.cjs
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/scripts/test_pipeline_client.cjs
# Erzeugt: 2026-10-23 durch ABSTRACTIONS_MANAGER.py

# PowerShell 7 Port of test_pipeline_client.cjs

using namespace System.Security.Cryptography
using namespace System.Text
using namespace System.Collections.Generic
using namespace System.Threading.Tasks

class StorageMock {
    [hashtable]$data
    
    StorageMock([hashtable]$initialData) {
        $this.data = $initialData
    }
    
    [hashtable] Get($keys) {
        $result = @{}
        if ($null -eq $keys) { return $result }
        
        if ($keys -isnot [array]) {
            $keys = @($keys)
        }
        
        foreach ($key in $keys) {
            if ($this.data.ContainsKey($key)) {
                $result[$key] = $this.data[$key]
            }
        }
        return $result
    }
    
    [void] Set([hashtable]$values) {
        foreach ($key in $values.Keys) {
            $this.data[$key] = $values[$key]
        }
    }
}

class DatabaseTransaction {
    [Dictionary[string, object]]$rows
    [System.Management.Automation.PSCustomObject]$oncomplete
    
    DatabaseTransaction([Dictionary[string, object]]$rowsRef) {
        $this.rows = $rowsRef
    }
    
    [object] objectStore() {
        return [PSCustomObject]@{
            put = [Func[object, object]] {
                param($row)
                $script:result = $null
                $script:task = [Task]::Run({
                    $this.rows[$row.eventId] = $row.PSObject.Copy()
                    $script:result = $true
                })
                return [PSCustomObject]@{
                    result = $script:result
                    onsuccess = $null
                    Wait = { $script:task.Wait() }
                }
            }.GetNewClosure()
            
            delete = [Func[object, object]] {
                param($id)
                $script:result = $null
                $script:task = [Task]::Run({
                    $this.rows.Remove($id)
                    $script:result = $true
                })
                return [PSCustomObject]@{
                    result = $script:result
                    onsuccess = $null
                    Wait = { $script:task.Wait() }
                }
            }.GetNewClosure()
            
            getAll = [Func[object]] {
                $script:result = $null
                $script:task = [Task]::Run({
                    $clonedRows = @()
                    foreach ($row in $this.rows.Values) {
                        $clonedRows += $row.PSObject.Copy()
                    }
                    $script:result = $clonedRows
                })
                return [PSCustomObject]@{
                    result = $script:result
                    onsuccess = $null
                    Wait = { $script:task.Wait() }
                }
            }.GetNewClosure()
        }
    }
}

class DatabaseMock {
    [Dictionary[string, object]]$rows
    
    DatabaseMock() {
        $this.rows = New-Object Dictionary[string, object]
    }
    
    [object] transaction() {
        return [DatabaseTransaction]::new($this.rows)
    }
}

class IndexedDBMock {
    [object] open() {
        $req = [PSCustomObject]@{
            result = [DatabaseMock]::new()
            onsuccess = $null
        }
        return $req
    }
}

function CreateClientContext() {
    # Create mock storage objects
    $local = @{ 'tlc-settings' = @{ universalCaptionApiKey = 'universal-secret'; pairingCode = 'pair-secret' } }
    $session = @{}
    $rows = New-Object Dictionary[string, object]
    $received = @()
    
    # Create global context objects
    $storageLocal = [StorageMock]::new($local)
    $storageSession = [StorageMock]::new($session)
    $indexedDB = [IndexedDBMock]::new()
    
    # Mock Chrome APIs
    $chrome = @{
        storage = @{
            local = $storageLocal
            session = $storageSession
        }
        runtime = @{ id = 'self' }
        alarms = @{
            create = {}
            onAlarm = @{ addListener = {} }
        }
    }
    
    # Mock fetch implementation
    $fetch = {
        param($url, $options)
        if ($url.EndsWith('/events')) {
            $body = $options.body | ConvertFrom-Json
            $received.Add($body)
        }
        return @{
            ok = $true
            json = { return @{ cursor = $received.Count } }
        }
    }
    
    # Create script context
    $context = @{
        crypto = [System.Security.Cryptography.RandomNumberGenerator]
        indexedDB = $indexedDB
        AbortSignal = [System.Threading.CancellationToken]
        console = [Console]
        chrome = $chrome
        fetch = $fetch
    }
    
    # Load pipeline client script
    $scriptPath = Join-Path $PSScriptRoot '..\browser-extension\pipeline-client.js'
    $scriptContent = Get-Content -Path $scriptPath -Raw -Encoding UTF8
    
    # Execute script in context (PowerShell doesn't have exact VM equivalent, so we'll inject dependencies)
    Invoke-Expression $scriptContent
    
    return @{
        api = $TLCPipelines
        local = $local
        session = $session
        received = $received
        rows = $rows
    }
}

# Test function
function Test-OneKeyTwoTabsReloadAndDelayedOldDocumentEventsStaySeparate {
    $c = CreateClientContext
    
    # Run test sequence
    $c.api.start(1, 'doc-a')
    $c.api.start(2, 'doc-b')
    $c.api.publish(1, 'chat', @{ text = 'first' }, 'pair-secret', 'chat', 'doc-a')
    $c.api.start(1, 'doc-c')
    $c.api.publish(1, 'chat', @{ text = 'late' }, 'late', 'chat', 'doc-a')
    $c.api.publish(1, 'chat', @{ text = 'current' }, 'current', 'chat')
    
    # Wait for operations to complete
    for ($i = 0; $i -lt 30; $i++) {
        Start-Sleep -Milliseconds 1
        $c.api.flush()
    }
    
    # Assertions
    if ($c.rows.Count -ne 0) {
        throw "Expected rows size to be 0, but got $($c.rows.Count)"
    }
    
    $chats = $c.received | Where-Object { $_.pipeline -eq 'chat' -and $_.availability -eq 'available' }
    $documentIds = $chats | ForEach-Object { $_.documentId }
    
    $expectedDocIds = @('doc-a', 'doc-a', 'doc-c')
    if (-not (Compare-Object $expectedDocIds $documentIds)) {
        throw "Document IDs don't match expected values"
    }
    
    if ($chats[0].raw -ne '[credential removed]') {
        throw "Expected raw credential to be removed"
    }
    
    if ($chats[0].credentialsRedacted -ne $true) {
        throw "Expected credentialsRedacted to be true"
    }
    
    $b = $c.received | Where-Object { $_.documentId -eq 'doc-b' }
    if ($chats[0].tabId -eq $b.tabId) {
        throw "Expected tab IDs to be different"
    }
    
    if ($chats[0].clientId -ne $b.clientId) {
        throw "Expected client IDs to be the same"
    }
    
    $eventIds = $c.received | ForEach-Object { $_.eventId }
    $uniqueEventIds = $eventIds | Sort-Object -Unique
    if ($uniqueEventIds.Count -ne $c.received.Count) {
        throw "Event IDs are not unique"
    }
    
    Write-Host "Test passed!"
}

# Run the test
Test-OneKeyTwoTabsReloadAndDelayedOldDocumentEventsStaySeparate
