#!/usr/bin/env pwsh
# scrape_to_markdown.py — portiert nach powershell
# Quelle: python, OpenClaw@gateway1:skills/web-markdown-scraper/scripts/scrape_to_markdown.py
# auch in: OpenClaw@gateway2:skills/web-markdown-scraper/scripts/scrape_to_markdown.py
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

param(
    [string[]]$Url = @(),
    [string]$UrlFile = "",
    [string]$Selector = "",
    [switch]$Js,
    [string]$WaitSelector = "",
    [switch]$PreserveLinks,
    [int]$BodyWidth = 0,
    [int]$Timeout = 30,
    [string]$OutputDir = "outputs",
    [string]$AutomatchDomain = ""
)

function ConvertTo-StringSafe($value) {
    if ($null -eq $value) {
        return ""
    }
    if ($value -is [byte[]]) {
        return [System.Text.Encoding]::UTF8.GetString($value)
    }
    return $value.ToString()
}

function Convert-ToSlug($text, $maxLength = 80) {
    $text = $text -replace '[^\w\s-]', ''
    $text = $text.Trim().ToLower()
    $text = $text -replace '[-\s]+', '-'
    if ($text.Length -gt $maxLength) {
        $text = $text.Substring(0, $maxLength)
    }
    $text = $text.Trim('-')
    if ([string]::IsNullOrEmpty($text)) {
        $text = "page"
    }
    return $text
}

function Extract-Html($obj) {
    if ($null -eq $obj) {
        return ""
    }
    
    $attrs = @("html", "raw_html", "content", "markup", "body", "inner_html")
    foreach ($attr in $attrs) {
        try {
            $value = $obj.$attr
            if ($null -ne $value -and $value.GetType().Name -eq "ScriptBlock") {
                $value = & $value
            }
            $text = ConvertTo-StringSafe $value
            if ($text -and $text.Contains("<") -and $text.Contains(">")) {
                return $text
            }
        } catch {
            # Continue to next attribute
        }
    }
    
    $text = ConvertTo-StringSafe $obj
    if ($text.Contains("<") -and $text.Contains(">")) {
        return $text
    }
    return ""
}

function Extract-Title($html) {
    if ([string]::IsNullOrEmpty($html)) {
        return ""
    }
    
    $match = [regex]::Match($html, '<title[^>]*>(.*?)</title>', 'IgnoreCase, Singleline')
    if (-not $match.Success) {
        return ""
    }
    
    $title = [regex]::Replace($match.Groups[1].Value, '<[^>]+>', ' ')
    $title = [regex]::Replace($title, '\s+', ' ').Trim()
    return $title
}

function Load-Fetcher([bool]$js) {
    $errors = @()
    
    if ($js) {
        $candidates = @(
            @{ Module = "scrapling.fetchers"; Class = "DynamicFetcher" },
            @{ Module = "scrapling.fetchers"; Class = "PlayWrightFetcher" },
            @{ Module = "scrapling.default"; Class = "PlayWrightFetcher" },
            @{ Module = "scrapling.defaults"; Class = "PlayWrightFetcher" }
        )
    } else {
        $candidates = @(
            @{ Module = "scrapling.fetchers"; Class = "Fetcher" },
            @{ Module = "scrapling.default"; Class = "Fetcher" },
            @{ Module = "scrapling.defaults"; Class = "Fetcher" }
        )
    }
    
    foreach ($candidate in $candidates) {
        try {
            $module = Import-Module $candidate.Module -PassThru -ErrorAction Stop
            $cls = $module.ExportedCommands[$candidate.Class]
            if ($cls) {
                return @{ Class = $cls; MethodName = "Get" }
            }
        } catch {
            $errors += "$($candidate.Module).$($candidate.Class): $($_.Exception.Message)"
        }
    }
    
    throw "No compatible Scrapling fetcher found: $($errors -join ' | ')"
}

function Fetch-Page($url, [bool]$js, $waitSelector, $timeout, $automatchDomain) {
    $fetcherInfo = Load-Fetcher -js $js
    $cls = $fetcherInfo.Class
    $methodName = $fetcherInfo.MethodName
    
    $kwargs = @{}
    if ($js) {
        $kwargs.headless = $true
        if ($waitSelector) {
            $kwargs.wait_selector = $waitSelector
        }
    } else {
        $kwargs.timeout = $timeout
    }
    
    if ($automatchDomain -and -not $js) {
        try {
            # This would need to be adapted based on actual PowerShell module structure
            # For now we'll skip this part as it's complex without knowing exact module structure
        } catch {
            # Ignore error
        }
    }
    
    try {
        $page = & $cls $url @kwargs
        return @{ Page = $page; Backend = "$($cls.ModuleName).$($cls.Name).$methodName" }
    } catch [System.Management.Automation.MethodInvocationException] {
        $page = & $cls $url
        return @{ Page = $page; Backend = "$($cls.ModuleName).$($cls.Name).$methodName" }
    }
}

function Pick-MainHtml($page, $preferredSelector) {
    $selectors = @()
    if ($preferredSelector) {
        $selectors += $preferredSelector
    }
    $selectors += @("article", "main", "[role='main']", ".post-content", ".entry-content", ".article-content", "body")
    
    # Check if page has css_first method (this is pseudo-code as PowerShell doesn't have direct equivalent)
    # We'll assume we can access properties directly
    foreach ($selector in $selectors) {
        try {
            # This is a simplified version - actual implementation would depend on how scrapling objects are structured in PowerShell
            if ($page.CssFirst) {
                $node = $page.CssFirst($selector)
                $html = Extract-Html $node
                if ($html -and $html.Length -ge 120) {
                    return @{ Html = $html; Selector = $selector }
                }
            }
        } catch {
            # Continue to next selector
        }
    }
    
    return @{ Html = (Extract-Html $page); Selector = $null }
}

function Convert-HtmlToMarkdown($html, [bool]$preserveLinks, [int]$bodyWidth) {
    # Since html2text is a Python library, we'd need to either use it through Python interop or find a .NET alternative
    # For this conversion, I'll create a simple placeholder that just strips HTML tags
    # A real implementation would require a proper HTML-to-markdown converter
    
    $result = $html
    # Remove script and style elements
    $result = [regex]::Replace($result, '<script[^>]*>.*?</script>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    $result = [regex]::Replace($result, '<style[^>]*>.*?</style>', '', [System.Text.RegularExpressions.RegexOptions]::Singleline)
    # Replace block-level elements with newlines
    $result = [regex]::Replace($result, '</?(div|p|br|h[1-6]|li|tr|td)[^>]*>', "`n", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
    # Remove remaining HTML tags
    $result = [regex]::Replace($result, '<[^>]+>', '')
    # Normalize whitespace
    $result = [regex]::Replace($result, '\s+', ' ')
    $result = $result.Trim()
    
    # Limit body width if specified
    if ($bodyWidth -gt 0) {
        $lines = @()
        foreach ($line in ($result -split "`n")) {
            if ($line.Length -gt $bodyWidth) {
                $wrappedLines = @()
                $currentLine = ""
                foreach ($word in ($line -split "\s+")) {
                    if (($currentLine.Length + $word.Length + 1) -le $bodyWidth) {
                        if ($currentLine) {
                            $currentLine += " "
                        }
                        $currentLine += $word
                    } else {
                        if ($currentLine) {
                            $wrappedLines += $currentLine
                        }
                        $currentLine = $word
                    }
                }
                if ($currentLine) {
                    $wrappedLines += $currentLine
                }
                $lines += $wrappedLines
            } else {
                $lines += $line
            }
        }
        $result = $lines -join "`n"
    }
    
    return $result
}

function Load-Urls($urlArgs, $urlFile) {
    $urls = @()
    if ($urlArgs) {
        $urls += $urlArgs
    }
    
    if ($urlFile -and (Test-Path $urlFile)) {
        $content = Get-Content $urlFile -Encoding UTF8
        foreach ($line in $content) {
            $line = $line.Trim()
            if ($line -and -not $line.StartsWith("#")) {
                $urls += $line
            }
        }
    }
    
    $clean = @()
    $seen = @{}
    foreach ($u in $urls) {
        if (-not $seen.ContainsKey($u)) {
            $clean += $u
            $seen[$u] = $true
        }
    }
    
    return $clean
}

function Validate-Url($url) {
    try {
        $uri = [System.Uri]$url
        return $uri.Scheme -in @("http", "https") -and (-not [string]::IsNullOrEmpty($uri.Host))
    } catch {
        return $false
    }
}

function Main() {
    $urls = Load-Urls $Url $UrlFile
    if (-not $urls) {
        Write-Output (ConvertTo-Json @{ ok = $false; error = "No URLs provided" } -Depth 10)
        exit 1
    }
    
    foreach ($u in $urls) {
        if (-not (Validate-Url $u)) {
            Write-Output (ConvertTo-Json @{ ok = $false; error = "Invalid URL: $u" } -Depth 10)
            exit 1
        }
    }
    
    $outDir = New-Item -ItemType Directory -Path $OutputDir -Force
    
    $results = @()
    
    foreach ($url in $urls) {
        $item = @{
            url = $url
            ok = $false
            title = ""
            status = $null
            selector_used = $null
            backend = $null
            markdown = ""
            preview = ""
            output_markdown_file = $null
            error = $null
        }
        
        try {
            $fetchResult = Fetch-Page -url $url -js $Js -waitSelector $WaitSelector -timeout $Timeout -automatchDomain $AutomatchDomain
            $page = $fetchResult.Page
            $backend = $fetchResult.Backend
            
            $htmlResult = Pick-MainHtml -page $page -preferredSelector $Selector
            $html = $htmlResult.Html
            $selectorUsed = $htmlResult.Selector
            
            if (-not $html) {
                throw "No HTML content extracted from page"
            }
            
            $title = Extract-Title $html
            if (-not $title) {
                $uri = [System.Uri]$url
                $title = $uri.Host
            }
            
            $markdown = Convert-HtmlToMarkdown -html $html -preserveLinks $PreserveLinks -bodyWidth $BodyWidth
            
            $filename = "$(Convert-ToSlug("$(([System.Uri]$url).Host)-$title")).md"
            $mdPath = Join-Path $outDir.FullName $filename
            Set-Content -Path $mdPath -Value $markdown -Encoding UTF8
            
            # Try to get status from page object
            $status = $null
            if ($page.PSObject.Properties.Name -contains "status") {
                $status = $page.status
            } elseif ($page.PSObject.Properties.Name -contains "status_code") {
                $status = $page.status_code
            }
            
            $item.ok = $true
            $item.title = $title
            $item.status = $status
            $item.selector_used = $selectorUsed
            $item.backend = $backend
            $item.markdown = $markdown
            $item.preview = if ($markdown.Length -gt 1200) { $markdown.Substring(0, 1200) } else { $markdown }
            $item.output_markdown_file = $mdPath
        } catch {
            $item.error = $_.Exception.Message
        }
        
        $results += $item
    }
    
    $ok = ($results | Where-Object { $_.ok }).Count -gt 0
    $indexPath = Join-Path $outDir.FullName "index.json"
    
    $payload = @{
        ok = $ok
        count = $results.Count
        success_count = ($results | Where-Object { $_.ok }).Count
        failure_count = ($results | Where-Object { -not $_.ok }).Count
        output_index_file = $indexPath
        results = $results
    }
    
    Set-Content -Path $indexPath -Value (ConvertTo-Json $payload -Depth 10 -Encoding UTF8)
    Write-Output (ConvertTo-Json $payload -Depth 10)
}

Main
