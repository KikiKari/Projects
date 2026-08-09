#!/usr/bin/env pwsh
# architecture3d.css — portiert nach powershell
# Quelle: css, Projects@TikTok-Live-Companion:site/src/architecture3d.css
# auch in: Projects@TikTok-Live-Companion-Android:site/src/architecture3d.css
# auch in: Projects@TikTok-Live-Companion-iOS:site/src/architecture3d.css
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
    Generates the architecture3d.css file from structured data.
.DESCRIPTION
    This script creates the CSS content for the 3D architecture page by defining
    each CSS rule as a hashtable and converting it to CSS format. The output is
    written to a file specified by the -OutputPath parameter.
.PARAMETER OutputPath
    The path to the output CSS file.
.EXAMPLE
    .\Generate-Architecture3DCSS.ps1 -OutputPath "architecture3d.css"
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Define CSS rules as an array of hashtables
$cssRules = @(
    @{
        selector = ":root"
        properties = @{
            "color-scheme" = "light"
        }
    },
    @{
        selector = ".architecture-3d-page"
        properties = @{
            "min-height" = "100vh"
            "overflow-x" = "hidden"
            "background" = "#fffdf9"
            "color" = "#14223c"
            "padding-bottom" = "48px"
        }
    },
    @{
        selector = ".architecture-3d-header"
        properties = @{
            "min-height" = "70px"
            "display" = "flex"
            "align-items" = "center"
            "justify-content" = "space-between"
            "gap" = "20px"
            "padding" = "12px max(22px, calc((100vw - 1240px)/2))"
            "border-bottom" = "1px solid #d9e2ec"
            "background" = "rgba(255,253,249,.96)"
        }
    },
    @{
        selector = ".architecture-3d-header a"
        properties = @{
            "color" = "#14223c"
            "text-decoration" = "none"
            "font-weight" = "800"
        }
    },
    @{
        selector = ".architecture-3d-header b"
        properties = @{
            "color" = "#e5384f"
        }
    },
    @{
        selector = ".architecture-3d-header nav"
        properties = @{
            "display" = "flex"
            "gap" = "20px"
        }
    },
    @{
        selector = ".architecture-3d-intro, .architecture-3d-workspace, .architecture-3d-legend, .architecture-3d-note"
        properties = @{
            "width" = "min(1240px, calc(100% - 36px))"
            "margin-inline" = "auto"
        }
    },
    @{
        selector = ".architecture-3d-intro"
        properties = @{
            "padding" = "54px 0 26px"
        }
    },
    @{
        selector = ".architecture-3d-intro h1"
        properties = @{
            "margin" = "5px 0 15px"
            "font-size" = "clamp(2.35rem, 5vw, 4.3rem)"
            "line-height" = "1.02"
            "letter-spacing" = "-.05em"
        }
    },
    @{
        selector = ".architecture-3d-intro > p:last-child"
        properties = @{
            "max-width" = "820px"
            "color" = "#526078"
            "font-size" = "1.05rem"
            "line-height" = "1.7"
        }
    },
    @{
        selector = ".architecture-3d-eyebrow"
        properties = @{
            "margin" = "0"
            "color" = "#0c8f9d"
            "font-size" = ".73rem"
            "font-weight" = "900"
            "letter-spacing" = ".14em"
        }
    },
    @{
        selector = ".architecture-3d-workspace"
        properties = @{
            "display" = "grid"
            "grid-template-columns" = "minmax(0, 1fr) 290px"
            "gap" = "18px"
        }
    },
    @{
        selector = ".architecture-3d-scene-shell"
        properties = @{
            "min-height" = "650px"
            "position" = "relative"
            "overflow" = "hidden"
            "border-radius" = "16px"
            "background" = "#0f1729"
            "box-shadow" = "0 20px 55px rgba(16,29,52,.22)"
        }
    },
    @{
        selector = ".architecture-3d-scene"
        properties = @{
            "position" = "absolute"
            "inset" = "0"
            "opacity" = "0"
            "transition" = "opacity .18s ease"
            "touch-action" = "pan-y"
        }
    },
    @{
        selector = ".architecture-3d-scene.is-ready"
        properties = @{
            "opacity" = "1"
        }
    },
    @{
        selector = ".architecture-3d-scene canvas"
        properties = @{
            "display" = "block"
            "width" = "100%"
            "height" = "100%"
        }
    },
    @{
        selector = ".architecture-3d-scene:focus-visible"
        properties = @{
            "outline" = "3px solid #25c5d2"
            "outline-offset" = "-5px"
        }
    },
    @{
        selector = ".architecture-3d-fallback"
        properties = @{
            "position" = "absolute"
            "inset" = "0"
            "width" = "100%"
            "height" = "100%"
            "object-fit" = "contain"
            "background" = "#0f1729"
        }
    },
    @{
        selector = ".architecture-3d-controls"
        properties = @{
            "position" = "absolute"
            "right" = "14px"
            "top" = "14px"
            "display" = "flex"
            "gap" = "8px"
            "z-index" = "4"
        }
    },
    @{
        selector = ".architecture-3d-controls button, .architecture-3d-step button"
        properties = @{
            "min-height" = "44px"
            "border" = "1px solid #60708a"
            "border-radius" = "9px"
            "background" = "rgba(15,23,41,.88)"
            "color" = "white"
            "padding" = "9px 13px"
            "font-weight" = "800"
            "cursor" = "pointer"
        }
    },
    @{
        selector = ".architecture-3d-inspector"
        properties = @{
            "align-self" = "stretch"
            "padding" = "24px"
            "border" = "1px solid #d4dee8"
            "border-radius" = "16px"
            "background" = "white"
        }
    },
    @{
        selector = ".architecture-3d-inspector h2"
        properties = @{
            "margin" = "9px 0"
            "font-size" = "1.45rem"
        }
    },
    @{
        selector = ".architecture-3d-inspector > p:not(.architecture-3d-eyebrow)"
        properties = @{
            "color" = "#526078"
            "min-height" = "48px"
        }
    },
    @{
        selector = ".architecture-3d-inspector dl"
        properties = @{
            "margin" = "25px 0"
        }
    },
    @{
        selector = ".architecture-3d-inspector dl div"
        properties = @{
            "padding" = "12px 0"
            "border-bottom" = "1px solid #e2e8f0"
        }
    },
    @{
        selector = ".architecture-3d-inspector dt"
        properties = @{
            "color" = "#758198"
            "font-size" = ".74rem"
            "text-transform" = "uppercase"
            "letter-spacing" = ".08em"
        }
    },
    @{
        selector = ".architecture-3d-inspector dd"
        properties = @{
            "margin" = "4px 0 0"
            "font-weight" = "800"
            "overflow-wrap" = "anywhere"
        }
    },
    @{
        selector = ".architecture-3d-step"
        properties = @{
            "display" = "grid"
            "grid-template-columns" = "1fr 1fr"
            "gap" = "8px"
        }
    },
    @{
        selector = ".architecture-3d-step button"
        properties = @{
            "background" = "#14223c"
        }
    },
    @{
        selector = ".architecture-3d-legend"
        properties = @{
            "display" = "flex"
            "flex-wrap" = "wrap"
            "gap" = "24px"
            "padding" = "23px 0 10px"
        }
    },
    @{
        selector = ".architecture-3d-legend span"
        properties = @{
            "display" = "inline-flex"
            "align-items" = "center"
            "gap" = "9px"
            "font-size" = ".85rem"
            "font-weight" = "750"
        }
    },
    @{
        selector = ".architecture-3d-legend i"
        properties = @{
            "width" = "30px"
            "height" = "4px"
            "display" = "inline-block"
            "background" = "#25c5d2"
        }
    },
    @{
        selector = ".architecture-3d-legend i.audio"
        properties = @{
            "background" = "#ff557a"
        }
    },
    @{
        selector = ".architecture-3d-legend i.token"
        properties = @{
            "background" = "repeating-linear-gradient(90deg,#e9a12d 0 7px,transparent 7px 11px)"
        }
    },
    @{
        selector = ".architecture-3d-note"
        properties = @{
            "color" = "#66758a"
            "font-size" = ".82rem"
        }
    },
    @{
        selector = "@media (max-width: 820px)"
        rules = @(
            @{
                selector = ".architecture-3d-workspace"
                properties = @{
                    "grid-template-columns" = "1fr"
                }
            },
            @{
                selector = ".architecture-3d-scene-shell"
                properties = @{
                    "min-height" = "520px"
                }
            },
            @{
                selector = ".architecture-3d-inspector"
                properties = @{
                    "order" = "2"
                }
            }
        )
    },
    @{
        selector = "@media (max-width: 520px)"
        rules = @(
            @{
                selector = ".architecture-3d-header"
                properties = @{
                    "padding-inline" = "16px"
                    "gap" = "8px"
                    "font-size" = ".82rem"
                }
            },
            @{
                selector = ".architecture-3d-header nav"
                properties = @{
                    "gap" = "10px"
                }
            },
            @{
                selector = ".architecture-3d-intro"
                properties = @{
                    "padding-top" = "35px"
                }
            },
            @{
                selector = ".architecture-3d-intro h1"
                properties = @{
                    "font-size" = "clamp(2rem, 10vw, 2.75rem)"
                    "overflow-wrap" = "anywhere"
                }
            },
            @{
                selector = ".architecture-3d-intro > p:last-child"
                properties = @{
                    "overflow-wrap" = "anywhere"
                }
            },
            @{
                selector = ".architecture-3d-scene-shell"
                properties = @{
                    "min-height" = "460px"
                }
            },
            @{
                selector = ".architecture-3d-controls"
                properties = @{
                    "left" = "10px"
                    "right" = "10px"
                    "justify-content" = "space-between"
                }
            },
            @{
                selector = ".architecture-3d-controls button"
                properties = @{
                    "min-width" = "44px"
                    "padding-inline" = "8px"
                    "font-size" = ".77rem"
                }
            },
            @{
                selector = ".architecture-3d-legend"
                properties = @{
                    "display" = "grid"
                    "gap" = "12px"
                }
            }
        )
    },
    @{
        selector = "@media (prefers-reduced-motion: reduce)"
        rules = @(
            @{
                selector = ".architecture-3d-scene"
                properties = @{
                    "transition" = "none"
                }
            }
        )
    }
)

# Function to convert hashtable to CSS string
function Convert-ToCSS {
    param (
        [array]$rules
    )
    
    $css = ""
    foreach ($rule in $rules) {
        if ($rule.ContainsKey("rules")) {
            # Handle media queries
            $css += "$($rule.selector) {`n"
            foreach ($subRule in $rule.rules) {
                $css += "  $($subRule.selector) {`n"
                foreach ($prop in $subRule.properties.GetEnumerator()) {
                    $css += "    $($prop.Key): $($prop.Value);`n"
                }
                $css += "  }`n"
            }
            $css += "}`n`n"
        } else {
            # Handle regular rules
            $css += "$($rule.selector) {`n"
            foreach ($prop in $rule.properties.GetEnumerator()) {
                $css += "  $($prop.Key): $($prop.Value);`n"
            }
            $css += "}`n`n"
        }
    }
    return $css
}

# Generate CSS content
$cssContent = Convert-ToCSS -rules $cssRules

# Write to file
Set-Content -Path $OutputPath -Value $cssContent.Trim()

Write-Host "CSS file generated at: $OutputPath"
