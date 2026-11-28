#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "bed79569e8ef20ee31e083c784fa6c97de4fa6d58db6085be07648fad8f7f3e2", "source_sha256": "9ed2bdeb80b99c649aeb5bf47416f21d76279e40bca0b04d2f75f7e1afd3a910", "target_language": "powershell"}
# index_81ff5e.css — portiert nach powershell
# Quelle: css, Projects@abstractions:css/index_81ff5e.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
    Generates the index_81ff5e.css file from structured data.
.DESCRIPTION
    This script programmatically creates the CSS content based on the original index_81ff5e.css,
    maintaining all styles and structure using PowerShell's object model.
.PARAMETER OutputPath
    The path where the generated CSS file will be saved.
.EXAMPLE
    .\generate-css.ps1 -OutputPath ./index_81ff5e.css
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$OutputPath
)

# Define CSS rules as objects
$cssRules = @()

# Root variables
$cssRules += @{
    selector = ':root'
    declarations = @{
        'color-scheme' = 'light'
        '--ink' = '#1b1c1f'
        '--muted' = '#6c6e75'
        '--faint' = '#9a9ca3'
        '--card' = '#fff'
        '--line' = '#e9eaee'
        '--accent' = '#5b5bd6'
        '--accent2' = '#7c5cff'
        '--ok' = '#22a06b'
        '--err' = '#e0533d'
        '--radius' = '16px'
        '--shadow' = '0 1px 2px rgba(20, 20, 40, 0.04), 0 6px 20px rgba(20, 20, 40, 0.06)'
    }
}

# Universal selector
$cssRules += @{
    selector = '*'
    declarations = @{
        'box-sizing' = 'border-box'
    }
}

# Body
$cssRules += @{
    selector = 'body'
    declarations = @{
        'margin' = '0'
        'font-family' = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif'
        'color' = 'var(--ink)'
        'min-height' = '100vh'
        'background' = 'radial-gradient(1100px 560px at 100% -10%, #e8ecff 0%, rgba(232, 236, 255, 0) 55%), linear-gradient(180deg, #eef1f6, #f7f7f8 42%)'
        'background-attachment' = 'fixed'
    }
}

# Wrap
$cssRules += @{
    selector = '.wrap'
    declarations = @{
        'max-width' = '820px'
        'margin' = '0 auto'
        'padding' = '24px 18px 70px'
    }
}

# Brand
$cssRules += @{
    selector = '.brand'
    declarations = @{
        'display' = 'flex'
        'align-items' = 'center'
        'gap' = '12px'
        'margin-bottom' = '4px'
    }
}

# Mark
$cssRules += @{
    selector = '.mark'
    declarations = @{
        'width' = '32px'
        'height' = '32px'
        'border-radius' = '9px'
        'background' = 'linear-gradient(135deg, var(--accent), var(--accent2))'
        'box-shadow' = '0 4px 12px rgba(91, 91, 214, 0.35)'
        'position' = 'relative'
        'flex' = '0 0 auto'
    }
}

# Mark after
$cssRules += @{
    selector = '.mark:after'
    declarations = @{
        'content' = '""'
        'position' = 'absolute'
        'inset' = '8px'
        'border-radius' = '4px'
        'border' = '2px solid rgba(255, 255, 255, 0.92)'
    }
}

# H1
$cssRules += @{
    selector = 'h1'
    declarations = @{
        'font-size' = '21px'
        'margin' = '0'
        'font-weight' = '700'
    }
}

# Sub
$cssRules += @{
    selector = '.sub'
    declarations = @{
        'color' = 'var(--muted)'
        'font-size' = '13px'
        'margin' = '2px 0 16px'
    }
}

# Card
$cssRules += @{
    selector = '.card'
    declarations = @{
        'background' = 'var(--card)'
        'border' = '1px solid var(--line)'
        'border-radius' = 'var(--radius)'
        'box-shadow' = 'var(--shadow)'
        'padding' = '16px'
        'margin-bottom' = '14px'
    }
}

# Card h2
$cssRules += @{
    selector = '.card h2'
    declarations = @{
        'font-size' = '14px'
        'margin' = '0 0 10px'
    }
}

# Label
$cssRules += @{
    selector = 'label.lab'
    declarations = @{
        'display' = 'block'
        'font-size' = '12px'
        'font-weight' = '600'
        'color' = 'var(--muted)'
        'margin' = '8px 0 3px'
    }
}

# Input & Textarea
$commonInputStyles = @{
    'width' = '100%'
    'font-size' = '13px'
    'padding' = '8px 10px'
    'border' = '1px solid var(--line)'
    'border-radius' = '9px'
    'font-family' = 'ui-monospace, Menlo, Consolas, monospace'
    'background' = '#fff'
}

$cssRules += @{
    selector = 'input'
    declarations = $commonInputStyles.Clone()
}

$cssRules += @{
    selector = 'textarea'
    declarations = ($commonInputStyles.Clone()) + @{
        'min-height' = '90px'
        'white-space' = 'pre'
        'overflow' = 'auto'
    }
}

# Row
$cssRules += @{
    selector = '.row'
    declarations = @{
        'display' = 'flex'
        'gap' = '8px'
        'flex-wrap' = 'wrap'
        'align-items' = 'center'
    }
}

# Button base
$cssRules += @{
    selector = '.btn'
    declarations = @{
        'font-size' = '13px'
        'font-weight' = '600'
        'padding' = '8px 14px'
        'border' = '1px solid var(--line)'
        'border-radius' = '10px'
        'background' = '#fff'
        'cursor' = 'pointer'
        'box-shadow' = 'var(--shadow)'
        'transition' = 'transform 0.1s'
    }
}

# Button hover
$cssRules += @{
    selector = '.btn:hover'
    declarations = @{
        'transform' = 'translateY(-1px)'
    }
}

# Primary button
$cssRules += @{
    selector = '.btn.primary'
    declarations = @{
        'background' = 'linear-gradient(135deg, var(--accent), var(--accent2))'
        'color' = '#fff'
        'border-color' = 'transparent'
    }
}

# Small button
$cssRules += @{
    selector = '.btn.sm'
    declarations = @{
        'padding' = '5px 9px'
        'font-size' = '12px'
    }
}

# Message
$cssRules += @{
    selector = '.msg'
    declarations = @{
        'font-size' = '12px'
        'margin-left' = '6px'
    }
}

# OK message
$cssRules += @{
    selector = '.msg.ok'
    declarations = @{
        'color' = 'var(--ok)'
    }
}

# Error message
$cssRules += @{
    selector = '.msg.err'
    declarations = @{
        'color' = 'var(--err)'
    }
}

# Provenance container
$cssRules += @{
    selector = '.prov'
    declarations = @{
        'border' = '1px solid var(--line)'
        'border-radius' = '12px'
        'padding' = '10px 12px'
        'margin-bottom' = '10px'
    }
}

# Provenance header
$cssRules += @{
    selector = '.prov h3'
    declarations = @{
        'margin' = '0 0 6px'
        'font-size' = '13.5px'
        'display' = 'flex'
        'align-items' = 'center'
        'gap' = '8px'
    }
}

# Key-value grid
$cssRules += @{
    selector = '.kv'
    declarations = @{
        'display' = 'grid'
        'grid-template-columns' = '180px 1fr auto'
        'gap' = '6px'
        'margin' = '4px 0'
        'align-items' = 'center'
    }
}

# KV input
$cssRules += @{
    selector = '.kv input'
    declarations = @{
        'font-size' = '12px'
        'padding' = '5px 7px'
    }
}

# Key label
$cssRules += @{
    selector = '.kv .k'
    declarations = @{
        'color' = 'var(--muted)'
        'font-weight' = '600'
    }
}

# Muted text
$cssRules += @{
    selector = '.muted'
    declarations = @{
        'color' = 'var(--faint)'
        'font-size' = '13px'
    }
}

# Hidden elements
$cssRules += @{
    selector = '.hide'
    declarations = @{
        'display' = 'none'
    }
}

# Footer
$cssRules += @{
    selector = '.foot'
    declarations = @{
        'color' = 'var(--faint)'
        'font-size' = '11.5px'
        'text-align' = 'center'
        'margin-top' = '18px'
        'line-height' = '1.5'
    }
}

# Links
$cssRules += @{
    selector = 'a'
    declarations = @{
        'color' = 'var(--accent)'
    }
}

# Generate CSS content
$cssContent = @"
/* abstraction-provenance: {"artifact_sha256": "6c7bf507504ec73409a080d09a27627c41cdd58e5cad63094e66d411e563bbf9", "source_sha256": "81ff5e370288082827f95b7b3dc2b94ce16d7710bcedcfd099f0ea81805a7d12", "target_language": "css"} */
/* index.html — portiert nach css */
/* Quelle: html, Projects@secret-vault-public:secret-vault-public/index.html */
/* Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py */

"@

foreach ($rule in $cssRules) {
    $cssContent += "$($rule.selector) {`n"
    
    foreach ($decl in $rule.declarations.GetEnumerator() | Sort-Object Key) {
        $cssContent += "  $($decl.Key): $($decl.Value);`n"
    }
    
    $cssContent += "}`n`n"
}

# Write to file
$cssContent | Out-File -FilePath $OutputPath -Encoding UTF8
