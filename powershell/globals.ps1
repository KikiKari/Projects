#!/usr/bin/env pwsh
# globals.css — portiert nach powershell
# Quelle: css, Onboarding@main:app/globals.css
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Funktion zum Erstellen eines CSS-Variablenblocks
function Create-CSSVariables {
    param([hashtable]$Variables)
    
    $content = ":root {`n"
    foreach ($key in $Variables.Keys) {
        $content += "  --$key`: $($Variables[$key]);`n"
    }
    $content += "}"
    return $content
}

# Funktion zum Erstellen eines @theme Blocks
function Create-CSSTheme {
    param([hashtable]$ThemeVars)
    
    $content = "@theme inline {`n"
    foreach ($key in $ThemeVars.Keys) {
        $content += "  --$key`: var(--$($ThemeVars[$key]));`n"
    }
    $content += "}"
    return $content
}

# Funktion zum Erstellen eines CSS-Selektors
function Create-CSSSelector {
    param(
        [string]$Selector,
        [hashtable]$Properties
    )
    
    $content = "$Selector {"
    foreach ($key in $Properties.Keys) {
        $content += " $($key): $($Properties[$key]);"
    }
    $content += " }"
    return $content
}

# Funktion zum Erstellen eines Keyframe-Animationsblocks
function Create-CSSKeyframes {
    param(
        [string]$Name,
        [hashtable[]]$Steps
    )
    
    $content = "@keyframes $Name {`n"
    foreach ($step in $Steps) {
        $content += "  $($step.Position) {`n"
        foreach ($prop in $step.Properties.GetEnumerator()) {
            $content += "    $($prop.Key): $($prop.Value);`n"
        }
        $content += "  }`n"
    }
    $content += "}"
    return $content
}

# Hauptvariablen definieren
$rootVariables = @{
    "bg" = "#faf8f4";
    "surface" = "#ffffff";
    "surface-2" = "#f1eee7";
    "ink" = "#1b1a17";
    "ink-2" = "#3c3a34";
    "muted" = "#6e6a61";
    "line" = "#e5e1d8";
    "line-strong" = "#d4cfc3";
    "accent" = "#a8542f";
    "accent-press" = "#8e4526";
    "accent-tint" = "#f1e5dd";
    "on-accent" = "#ffffff";
    "accent-2" = "#2e7d7b";
    "accent-2-press" = "#225e5b";
    "accent-3" = "#c77d2e";
    "footer-bg" = "#191815";
    "footer-fg" = "#efeae0";
    "footer-muted" = "#9a958a";
    "success" = "#2e7d5b";
    "danger" = "#9e3f32";
    "font-display" = '"Iowan Old Style", "Palatino Linotype", Georgia, "Times New Roman", serif';
    "font-sans" = '"Segoe UI", Inter, system-ui, -apple-system, sans-serif';
    "font-mono" = '"Cascadia Code", "SFMono-Regular", Consolas, ui-monospace, monospace';
    "space-1" = "0.25rem";
    "space-2" = "0.5rem";
    "space-3" = "0.75rem";
    "space-4" = "1rem";
    "space-5" = "1.25rem";
    "space-6" = "1.5rem";
    "space-8" = "2rem";
    "space-10" = "2.5rem";
    "space-12" = "3rem";
    "space-16" = "4rem";
    "space-20" = "5rem";
    "space-24" = "6rem";
    "space-30" = "7.5rem";
    "radius-sm" = "0.375rem";
    "radius-md" = "0.625rem";
    "radius-lg" = "1.125rem";
    "radius-pill" = "999px";
    "shadow-sm" = "0 1px 2px rgb(27 26 23 / 6%)";
    "shadow-md" = "0 10px 30px -16px rgb(27 26 23 / 22%)";
    "shadow-lg" = "0 34px 70px -34px rgb(27 26 23 / 32%)";
    "container" = "75rem";
    "motion-fast" = "180ms";
    "motion-base" = "350ms";
    "motion-slow" = "800ms";
    "ease-out" = "cubic-bezier(0.22, 0.61, 0.36, 1)";
}

# Theme-Variablen definieren
$themeVariables = @{
    "color-bg" = "bg";
    "color-surface" = "surface";
    "color-surface-2" = "surface-2";
    "color-ink" = "ink";
    "color-ink-2" = "ink-2";
    "color-muted" = "muted";
    "color-line" = "line";
    "color-line-strong" = "line-strong";
    "color-accent" = "accent";
    "color-accent-2" = "accent-2";
    "color-accent-3" = "accent-3";
    "font-display" = "font-display";
    "font-sans" = "font-sans";
    "font-mono" = "font-mono";
}

# CSS-Inhalt erstellen
$cssContent = @()

# Import-Anweisung hinzufügen
$cssContent += '@import "tailwindcss";'
$cssContent += ""

# Root-Variablen hinzufügen
$cssContent += Create-CSSVariables $rootVariables
$cssContent += ""

# Theme-Variablen hinzufügen
$cssContent += Create-CSSTheme $themeVariables
$cssContent += ""

# Allgemeine Selektoren hinzufügen
$cssContent += Create-CSSSelector "*" @{ "box-sizing" = "border-box" }
$cssContent += Create-CSSSelector "html" @{ "scroll-behavior" = "smooth" }
$cssContent += Create-CSSSelector "body" @{
    "margin" = "0";
    "background" = "var(--bg)";
    "color" = "var(--ink)";
    "font-family" = "var(--font-sans)";
    "line-height" = "1.5";
    "-webkit-font-smoothing" = "antialiased";
}
$cssContent += Create-CSSSelector "a" @{ "color" = "inherit" }
$cssContent += Create-CSSSelector "button, input, textarea" @{ "font" = "inherit" }
$cssContent += Create-CSSSelector "::selection" @{
    "background" = "var(--accent-tint)";
    "color" = "var(--ink)";
}
$cssContent += ""

# Klassenselektoren hinzufügen
$cssContent += Create-CSSSelector ".display" @{
    "font-family" = "var(--font-display)";
    "font-weight" = "400";
    "letter-spacing" = "-0.022em";
}
$cssContent += Create-CSSSelector ".eyebrow" @{
    "font-family" = "var(--font-mono)";
    "font-size" = "0.75rem";
    "letter-spacing" = "0.16em";
    "text-transform" = "uppercase";
}
$cssContent += Create-CSSSelector ".focus-ring:focus-visible" @{
    "outline" = "2px solid var(--accent)";
    "outline-offset" = "4px";
}
$cssContent += Create-CSSSelector ".content-auto" @{
    "content-visibility" = "auto";
    "contain-intrinsic-size" = "1px 800px";
}
$cssContent += ""

# Media Query für reduzierte Bewegung
$cssContent += "@media (prefers-reduced-motion: reduce) {"
$cssContent += "  html { scroll-behavior: auto; }"
$cssContent += "  *, *::before, *::after {"
$cssContent += "    animation-duration: 0.01ms !important;"
$cssContent += "    animation-iteration-count: 1 !important;"
$cssContent += "    scroll-behavior: auto !important;"
$cssContent += "    transition-duration: 0.01ms !important;"
$cssContent += "  }"
$cssContent += "}"
$cssContent += ""

# Spezifische Selektoren für Header-Ausblendung
$cssContent += "/* Header ausblenden solange PondExperience aktiv ist (data-hero-immersive) */"
$cssContent += 'body[data-hero-immersive="true"] > header,'
$cssContent += 'body[data-hero-immersive="true"] header[data-site-header] {'
$cssContent += "  opacity: 0;"
$cssContent += "  pointer-events: none;"
$cssContent += "  transition: opacity 0.4s ease-out;"
$cssContent += "}"
$cssContent += ""

# Keyframes für Wassertropfen-Animation
$cssContent += "/* Wassertropfen die frontal am Screen herunterlaufen (Splash-Overlay) */"
$dropfallSteps = @(
    @{
        Position = "0%";
        Properties = @{
            "transform" = "translateY(0)";
            "opacity" = "0";
        }
    },
    @{
        Position = "10%";
        Properties = @{
            "opacity" = "0.9";
        }
    },
    @{
        Position = "90%";
        Properties = @{
            "opacity" = "0.7";
        }
    },
    @{
        Position = "100%";
        Properties = @{
            "transform" = "translateY(110vh)";
            "opacity" = "0";
        }
    }
)
$cssContent += Create-CSSKeyframes "dropfall" $dropfallSteps

# Inhalt in Datei schreiben
$cssContent -join "`n" | Out-File -FilePath $OutputPath -Encoding UTF8
