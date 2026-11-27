#!/usr/bin/env pwsh
# abstraction-provenance: {"artifact_sha256": "9ad5af51b3b751a1f1f4267fe12898d40d9534c63105d1b0d7d2d1787c1e4515", "source_sha256": "c1bffd970108bca04ccb5b3a9aee8861acc4c11c8c4c461ea0c573b20c5e2f21", "target_language": "powershell"}
# index_4051ed.css — portiert nach powershell
# Quelle: css, Projects@abstractions:css/index_4051ed.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
    Generates the index_4051ed.css file with specified output path.
.DESCRIPTION
    This script generates a CSS file based on structured definitions,
    replicating the content of the original index_4051ed.css file.
.PARAMETER OutputPath
    The path where the generated CSS file will be saved.
.EXAMPLE
    .\Generate-CSS.ps1 -OutputPath "C:\temp\index_4051ed.css"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Define CSS rules as an array of hashtables
$cssRules = @(
    @{
        selector = ":root"
        properties = @{
            "--bg" = "#f6f7f9"
            "--card" = "#fff"
            "--line" = "#e3e6ea"
            "--text" = "#16191d"
            "--muted" = "#6b7280"
            "--accent" = "#2481cc"
            "--accent-soft" = "#e8f2fb"
            "--discord" = "#5865f2"
            "--discord-soft" = "#eceefe"
            "--ok" = "#15803d"
            "--warn" = "#b45309"
            "--err" = "#b91c1c"
            "color-scheme" = "light"
        }
    },
    @{
        selector = "*"
        properties = @{
            "box-sizing" = "border-box"
        }
    },
    @{
        selector = "body"
        properties = @{
            "margin" = "0"
            "background" = "var(--bg)"
            "color" = "var(--text)"
            "font" = "15px/1.5 -apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif"
        }
    },
    @{
        selector = "header"
        properties = @{
            "background" = "var(--card)"
            "border-bottom" = "1px solid var(--line)"
            "padding" = "14px 20px"
            "display" = "flex"
            "align-items" = "center"
            "gap" = "14px"
            "flex-wrap" = "wrap"
            "position" = "sticky"
            "top" = "0"
            "z-index" = "5"
        }
    },
    @{
        selector = "header h1"
        properties = @{
            "font-size" = "17px"
            "margin" = "0"
            "font-weight" = "650"
        }
    },
    @{
        selector = ".pill"
        properties = @{
            "font-size" = "11px"
            "padding" = "2px 8px"
            "border-radius" = "99px"
            "background" = "var(--accent-soft)"
            "color" = "var(--accent)"
            "font-weight" = "600"
            "white-space" = "nowrap"
        }
    },
    @{
        selector = ".pill.off"
        properties = @{
            "background" = "#f1f2f4"
            "color" = "var(--muted)"
        }
    },
    @{
        selector = ".pill.dc"
        properties = @{
            "background" = "var(--discord-soft)"
            "color" = "var(--discord)"
        }
    },
    @{
        selector = "nav"
        properties = @{
            "display" = "flex"
            "gap" = "4px"
            "padding" = "0 20px"
            "background" = "var(--card)"
            "border-bottom" = "1px solid var(--line)"
        }
    },
    @{
        selector = "nav button"
        properties = @{
            "border" = "0"
            "background" = "none"
            "padding" = "11px 14px"
            "font" = "inherit"
            "font-weight" = "500"
            "color" = "var(--muted)"
            "cursor" = "pointer"
            "border-bottom" = "2px solid transparent"
        }
    },
    @{
        selector = "nav button.active"
        properties = @{
            "color" = "var(--accent)"
            "border-bottom-color" = "var(--accent)"
        }
    },
    @{
        selector = "main"
        properties = @{
            "padding" = "20px"
            "max-width" = "1080px"
            "margin" = "0 auto"
        }
    },
    @{
        selector = ".panel"
        properties = @{
            "display" = "none"
        }
    },
    @{
        selector = ".panel.active"
        properties = @{
            "display" = "block"
        }
    },
    @{
        selector = ".row"
        properties = @{
            "display" = "flex"
            "gap" = "8px"
            "flex-wrap" = "wrap"
            "align-items" = "center"
            "margin-bottom" = "14px"
        }
    },
    @{
        selector = "input,select"
        properties = @{
            "padding" = "9px 11px"
            "border" = "1px solid var(--line)"
            "border-radius" = "8px"
            "font" = "inherit"
            "background" = "var(--card)"
            "min-width" = "180px"
        }
    },
    @{
        selector = "input:focus,select:focus"
        properties = @{
            "outline" = "2px solid var(--accent-soft)"
            "border-color" = "var(--accent)"
        }
    },
    @{
        selector = "button.go"
        properties = @{
            "background" = "var(--accent)"
            "color" = "#fff"
            "border" = "0"
            "border-radius" = "8px"
            "padding" = "9px 16px"
            "font" = "inherit"
            "font-weight" = "600"
            "cursor" = "pointer"
        }
    },
    @{
        selector = "button.go.sec"
        properties = @{
            "background" = "var(--card)"
            "color" = "var(--text)"
            "border" = "1px solid var(--line)"
        }
    },
    @{
        selector = "button.go.dc"
        properties = @{
            "background" = "var(--discord)"
        }
    },
    @{
        selector = "button.go:disabled"
        properties = @{
            "opacity" = ".5"
            "cursor" = "default"
        }
    },
    @{
        selector = ".card"
        properties = @{
            "background" = "var(--card)"
            "border" = "1px solid var(--line)"
            "border-radius" = "12px"
            "padding" = "14px 16px"
            "margin-bottom" = "10px"
        }
    },
    @{
        selector = ".card h3"
        properties = @{
            "margin" = "0 0 2px"
            "font-size" = "15px"
            "display" = "flex"
            "align-items" = "center"
            "gap" = "8px"
            "flex-wrap" = "wrap"
        }
    },
    @{
        selector = ".card .meta"
        properties = @{
            "color" = "var(--muted)"
            "font-size" = "13px"
        }
    },
    @{
        selector = ".card .desc"
        properties = @{
            "margin-top" = "7px"
            "font-size" = "13.5px"
            "white-space" = "pre-wrap"
        }
    },
    @{
        selector = ".avatar"
        properties = @{
            "width" = "34px"
            "height" = "34px"
            "border-radius" = "50%"
            "object-fit" = "cover"
            "background" = "#eceff3"
            "flex" = "none"
        }
    },
    @{
        selector = ".head"
        properties = @{
            "display" = "flex"
            "gap" = "11px"
            "align-items" = "flex-start"
        }
    },
    @{
        selector = ".score"
        properties = @{
            "font-variant-numeric" = "tabular-nums"
            "font-size" = "12px"
            "color" = "var(--muted)"
            "border" = "1px solid var(--line)"
            "border-radius" = "6px"
            "padding" = "1px 6px"
        }
    },
    @{
        selector = ".tag"
        properties = @{
            "font-size" = "11px"
            "padding" = "2px 7px"
            "border-radius" = "5px"
            "background" = "#f1f2f4"
            "color" = "var(--muted)"
            "font-weight" = "600"
        }
    },
    @{
        selector = ".tag.ok"
        properties = @{
            "background" = "#e7f6ec"
            "color" = "var(--ok)"
        }
    },
    @{
        selector = ".tag.no"
        properties = @{
            "background" = "#fdeceb"
            "color" = "var(--err)"
        }
    },
    @{
        selector = ".post"
        properties = @{
            "border-left" = "3px solid var(--accent-soft)"
            "padding" = "6px 0 6px 11px"
            "margin" = "9px 0"
            "font-size" = "13.5px"
        }
    },
    @{
        selector = ".post .when"
        properties = @{
            "color" = "var(--muted)"
            "font-size" = "12px"
        }
    },
    @{
        selector = ".post .txt"
        properties = @{
            "white-space" = "pre-wrap"
            "margin-top" = "2px"
        }
    },
    @{
        selector = "a"
        properties = @{
            "color" = "var(--accent)"
            "text-decoration" = "none"
        }
    },
    @{
        selector = "a:hover"
        properties = @{
            "text-decoration" = "underline"
        }
    },
    @{
        selector = ".empty"
        properties = @{
            "color" = "var(--muted)"
            "padding" = "22px"
            "text-align" = "center"
            "border" = "1px dashed var(--line)"
            "border-radius" = "12px"
        }
    },
    @{
        selector = ".err"
        properties = @{
            "background" = "#fdeceb"
            "border" = "1px solid #f5c6c2"
            "color" = "var(--err)"
            "padding" = "10px 13px"
            "border-radius" = "8px"
            "margin-bottom" = "12px"
            "font-size" = "13.5px"
        }
    },
    @{
        selector = ".spin"
        properties = @{
            "color" = "var(--muted)"
            "padding" = "16px 0"
        }
    },
    @{
        selector = "table"
        properties = @{
            "width" = "100%"
            "border-collapse" = "collapse"
            "font-size" = "13.5px"
        }
    },
    @{
        selector = "th,td"
        properties = @{
            "text-align" = "left"
            "padding" = "8px 10px"
            "border-bottom" = "1px solid var(--line)"
            "vertical-align" = "top"
        }
    },
    @{
        selector = "th"
        properties = @{
            "color" = "var(--muted)"
            "font-weight" = "600"
            "font-size" = "12px"
            "text-transform" = "uppercase"
            "letter-spacing" = ".03em"
        }
    },
    @{
        selector = "code"
        properties = @{
            "background" = "#f1f2f4"
            "padding" = "1px 5px"
            "border-radius" = "4px"
            "font-size" = "12.5px"
        }
    },
    @{
        selector = ".hint"
        properties = @{
            "color" = "var(--muted)"
            "font-size" = "13px"
            "margin" = "-4px 0 14px"
        }
    },
    @{
        selector = ".stream"
        properties = @{
            "max-height" = "460px"
            "overflow" = "auto"
            "border" = "1px solid var(--line)"
            "border-radius" = "10px"
            "padding" = "6px 12px"
            "margin-top" = "10px"
            "background" = "var(--card)"
        }
    },
    @{
        selector = ".post.fresh"
        properties = @{
            "border-left-color" = "var(--ok)"
            "background" = "#f3fbf5"
        }
    },
    @{
        selector = ".post.fresh .when::after"
        properties = @{
            "content" = "' NEU'"
            "color" = "var(--ok)"
            "font-weight" = "700"
        }
    },
    @{
        selector = ".dot"
        properties = @{
            "width" = "8px"
            "height" = "8px"
            "border-radius" = "50%"
            "background" = "var(--ok)"
            "display" = "inline-block"
            "margin-right" = "6px"
            "animation" = "pulse 2s infinite"
        }
    },
    @{
        selector = "@keyframes pulse"
        properties = @{
            "0%,100%" = "{opacity:1}"
            "50%" = "{opacity:.35}"
        }
    },
    @{
        selector = ".idle"
        properties = @{
            "background" = "var(--muted)!important"
            "animation" = "none"
        }
    },
    @{
        selector = ".tt-live"
        properties = @{
            "background" = "#fe2c55"
            "color" = "#fff"
            "font-weight" = "700"
            "font-size" = "11px"
            "padding" = "2px 9px"
            "border-radius" = "99px"
        }
    },
    @{
        selector = ".tt-off"
        properties = @{
            "background" = "#f1f2f4"
            "color" = "var(--muted)"
            "font-weight" = "700"
            "font-size" = "11px"
            "padding" = "2px 9px"
            "border-radius" = "99px"
        }
    },
    @{
        selector = ".tt-player"
        properties = @{
            "position" = "relative"
            "width" = "100%"
            "max-width" = "340px"
            "aspect-ratio" = "9/16"
            "background" = "#000"
            "border-radius" = "10px"
            "overflow" = "hidden"
            "margin-top" = "10px"
            "border" = "1px solid var(--line)"
        }
    },
    @{
        selector = ".tt-player iframe"
        properties = @{
            "position" = "absolute"
            "inset" = "0"
            "width" = "100%"
            "height" = "100%"
            "border" = "0"
        }
    },
    @{
        selector = ".ev"
        properties = @{
            "display" = "flex"
            "gap" = "10px"
            "padding" = "7px 0"
            "border-bottom" = "1px solid var(--line)"
            "font-size" = "13.5px"
        }
    },
    @{
        selector = ".ev:last-child"
        properties = @{
            "border-bottom" = "0"
        }
    },
    @{
        selector = ".ev .k"
        properties = @{
            "font-weight" = "650"
            "white-space" = "nowrap"
        }
    },
    @{
        selector = ".ev .k.start"
        properties = @{
            "color" = "#fe2c55"
        }
    },
    @{
        selector = ".ev .k.end"
        properties = @{
            "color" = "var(--muted)"
        }
    }
)

# Generate CSS content
$cssContent = ""
$cssContent += "/* abstraction-provenance: {`"artifact_sha256`": `"c0c2aa7750474bc55c705ff744495daa7aef344568dc1eadca3165b431837a79`", `"source_sha256`": `"4051edeb8cf3a53e4fdc417f40a86a4e9f16f24bcbc4b7334babe6d8f7500c24`", `"target_language`": `"css`"} */`n"
$cssContent += "/* index.html — portiert nach css */`n"
$cssContent += "/* Quelle: html, Projects@Telegram-Monitor:web/index.html */`n"
$cssContent += "/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */`n`n"

foreach ($rule in $cssRules) {
    if ($rule.selector -eq "@keyframes pulse") {
        $cssContent += "@keyframes pulse {`n"
        $cssContent += "  0%,100% {opacity:1}`n"
        $cssContent += "  50% {opacity:.35}`n"
        $cssContent += "}`n`n"
        continue
    }

    $cssContent += "$($rule.selector) {`n"
    
    foreach ($prop in $rule.properties.GetEnumerator()) {
        $cssContent += "  $($prop.Key): $($prop.Value);`n"
    }
    
    $cssContent += "}`n`n"
}

# Write to file
Set-Content -Path $OutputPath -Value $cssContent.TrimEnd()

Write-Host "CSS file generated at: $OutputPath"
