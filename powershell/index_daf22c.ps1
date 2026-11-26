#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "23ea247c07da3a87011829a15eab4281974c90ba10d4d75ed78d14149a194e4a", "source_sha256": "daf22c296c801d3d533083361cc59fbdc22e5bfe528aa4bad1973b54cc5448a4", "target_language": "powershell"}
# index.css — portiert nach powershell
# Quelle: css, OpenClaw@main:src/index.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputFile
)

# Create the CSS content programmatically
$cssRules = @()

# Body rule
$bodyRule = @{
    selector = "body"
    properties = @{
        "margin" = "0"
        "font-family" = "-apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', 'Fira Sans', 'Droid Sans', 'Helvetica Neue', sans-serif"
        "-webkit-font-smoothing" = "antialiased"
        "-moz-osx-font-smoothing" = "grayscale"
    }
}
$cssRules += $bodyRule

# Code rule
$codeRule = @{
    selector = "code"
    properties = @{
        "font-family" = "source-code-pro, Menlo, Monaco, Consolas, 'Courier New', monospace"
    }
}
$cssRules += $codeRule

# Generate CSS output
$output = ""
foreach ($rule in $cssRules) {
    $output += "$($rule.selector) {`n"
    foreach ($prop in $rule.properties.GetEnumerator()) {
        $output += "  $($prop.Key): $($prop.Value);`n"
    }
    $output += "}`n`n"
}

# Write to file
$output | Out-File -FilePath $OutputFile -Encoding UTF8
