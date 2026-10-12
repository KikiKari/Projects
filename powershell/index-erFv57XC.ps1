#!/usr/bin/env pwsh
# index-erFv57XC.css — portiert nach powershell
# Quelle: css, Projects@Weather-Check:Weather-Check/assets/index-erFv57XC.css
# Erzeugt: 2026-10-12 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
    Generates the index-erFv57XC.css file with all its CSS rules and variables.
.DESCRIPTION
    This script programmatically creates the complete CSS structure from scratch,
    organizing it into logical sections as found in the original file.
.PARAMETER OutputPath
    The path where the generated CSS file will be saved.
.EXAMPLE
    .\Generate-CSS.ps1 -OutputPath "index-erFv57XC.css"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

# Create a new StringBuilder to build the CSS content
$css = New-Object System.Text.StringBuilder

# Add the @import rule
$null = $css.AppendLine('@import"url("https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap");')

# Root variables section
$null = $css.AppendLine(":root{")
$null = $css.AppendLine("--background: 214 35% 8%;")
$null = $css.AppendLine("--foreground: 210 20% 92%;")
$null = $css.AppendLine("--card: 214 30% 11%;")
$null = $css.AppendLine("--card-foreground: 210 20% 92%;")
$null = $css.AppendLine("--popover: 214 30% 11%;")
$null = $css.AppendLine("--popover-foreground: 210 20% 92%;")
$null = $css.AppendLine("--primary: 210 85% 55%;")
$null = $css.AppendLine("--primary-foreground: 214 35% 8%;")
$null = $css.AppendLine("--secondary: 214 25% 16%;")
$null = $css.AppendLine("--secondary-foreground: 210 20% 75%;")
$null = $css.AppendLine("--muted: 214 25% 14%;")
$null = $css.AppendLine("--muted-foreground: 210 15% 55%;")
$null = $css.AppendLine("--accent: 195 80% 50%;")
$null = $css.AppendLine("--accent-foreground: 214 35% 8%;")
$null = $css.AppendLine("--destructive: 0 75% 55%;")
$null = $css.AppendLine("--destructive-foreground: 210 20% 92%;")
$null = $css.AppendLine("--border: 214 25% 18%;")
$null = $css.AppendLine("--input: 214 25% 16%;")
$null = $css.AppendLine("--ring: 210 85% 55%;")
$null = $css.AppendLine("--radius: .75rem;")
$null = $css.AppendLine("--rain-blue: #3b9eff;")
$null = $css.AppendLine("--rain-dark: #0d1b2a;")
$null = $css.AppendLine("--radar-glow: rgba(59, 158, 255, .15);")
$null = $css.AppendLine("}")

# Base styles section
$null = $css.AppendLine("*,:before,:after{")
$null = $css.AppendLine("--tw-border-spacing-x: 0;")
$null = $css.AppendLine("--tw-border-spacing-y: 0;")
$null = $css.AppendLine("--tw-translate-x: 0;")
$null = $css.AppendLine("--tw-translate-y: 0;")
$null = $css.AppendLine("--tw-rotate: 0;")
$null = $css.AppendLine("--tw-skew-x: 0;")
$null = $css.AppendLine("--tw-skew-y: 0;")
$null = $css.AppendLine("--tw-scale-x: 1;")
$null = $css.AppendLine("--tw-scale-y: 1;")
$null = $css.AppendLine("--tw-pan-x: ;")
$null = $css.AppendLine("--tw-pan-y: ;")
$null = $css.AppendLine("--tw-pinch-zoom: ;")
$null = $css.AppendLine("--tw-scroll-snap-strictness: proximity;")
$null = $css.AppendLine("--tw-gradient-from-position: ;")
$null = $css.AppendLine("--tw-gradient-via-position: ;")
$null = $css.AppendLine("--tw-gradient-to-position: ;")
$null = $css.AppendLine("--tw-ordinal: ;")
$null = $css.AppendLine("--tw-slashed-zero: ;")
$null = $css.AppendLine("--tw-numeric-figure: ;")
$null = $css.AppendLine("--tw-numeric-spacing: ;")
$null = $css.AppendLine("--tw-numeric-fraction: ;")
$null = $css.AppendLine("--tw-ring-inset: ;")
$null = $css.AppendLine("--tw-ring-offset-width: 0px;")
$null = $css.AppendLine("--tw-ring-offset-color: #fff;")
$null = $css.AppendLine("--tw-ring-color: rgb(59 130 246 / .5);")
$null = $css.AppendLine("--tw-ring-offset-shadow: 0 0 #0000;")
$null = $css.AppendLine("--tw-ring-shadow: 0 0 #0000;")
$null = $css.AppendLine("--tw-shadow: 0 0 #0000;")
$null = $css.AppendLine("--tw-shadow-colored: 0 0 #0000;")
$null = $css.AppendLine("--tw-blur: ;")
$null = $css.AppendLine("--tw-brightness: ;")
$null = $css.AppendLine("--tw-contrast: ;")
$null = $css.AppendLine("--tw-grayscale: ;")
$null = $css.AppendLine("--tw-hue-rotate: ;")
$null = $css.AppendLine("--tw-invert: ;")
$null = $css.AppendLine("--tw-saturate: ;")
$null = $css.AppendLine("--tw-sepia: ;")
$null = $css.AppendLine("--tw-drop-shadow: ;")
$null = $css.AppendLine("--tw-backdrop-blur: ;")
$null = $css.AppendLine("--tw-backdrop-brightness: ;")
$null = $css.AppendLine("--tw-backdrop-contrast: ;")
$null = $css.AppendLine("--tw-backdrop-grayscale: ;")
$null = $css.AppendLine("--tw-backdrop-hue-rotate: ;")
$null = $css.AppendLine("--tw-backdrop-invert: ;")
$null = $css.AppendLine("--tw-backdrop-opacity: ;")
$null = $css.AppendLine("--tw-backdrop-saturate: ;")
$null = $css.AppendLine("--tw-backdrop-sepia: ;")
$null = $css.AppendLine("--tw-contain-size: ;")
$null = $css.AppendLine("--tw-contain-layout: ;")
$null = $css.AppendLine("--tw-contain-paint: ;")
$null = $css.AppendLine("--tw-contain-style: ;")
$null = $css.AppendLine("}")

# Backdrop styles
$null = $css.AppendLine("::backdrop{")
$null = $css.AppendLine("--tw-border-spacing-x: 0;")
$null = $css.AppendLine("--tw-border-spacing-y: 0;")
$null = $css.AppendLine("--tw-translate-x: 0;")
$null = $css.AppendLine("--tw-translate-y: 0;")
$null = $css.AppendLine("--tw-rotate: 0;")
$null = $css.AppendLine("--tw-skew-x: 0;")
$null = $css.AppendLine("--tw-skew-y: 0;")
$null = $css.AppendLine("--tw-scale-x: 1;")
$null = $css.AppendLine("--tw-scale-y: 1;")
$null = $css.AppendLine("--tw-pan-x: ;")
$null = $css.AppendLine("--tw-pan-y: ;")
$null = $css.AppendLine("--tw-pinch-zoom: ;")
$null = $css.AppendLine("--tw-scroll-snap-strictness: proximity;")
$null = $css.AppendLine("--tw-gradient-from-position: ;")
$null = $css.AppendLine("--tw-gradient-via-position: ;")
$null = $css.AppendLine("--tw-gradient-to-position: ;")
$null = $css.AppendLine("--tw-ordinal: ;")
$null = $css.AppendLine("--tw-slashed-zero: ;")
$null = $css.AppendLine("--tw-numeric-figure: ;")
$null = $css.AppendLine("--tw-numeric-spacing: ;")
$null = $css.AppendLine("--tw-numeric-fraction: ;")
$null = $css.AppendLine("--tw-ring-inset: ;")
$null = $css.AppendLine("--tw-ring-offset-width: 0px;")
$null = $css.AppendLine("--tw-ring-offset-color: #fff;")
$null = $css.AppendLine("--tw-ring-color: rgb(59 130 246 / .5);")
$null = $css.AppendLine("--tw-ring-offset-shadow: 0 0 #0000;")
$null = $css.AppendLine("--tw-ring-shadow: 0 0 #0000;")
$null = $css.AppendLine("--tw-shadow: 0 0 #0000;")
$null = $css.AppendLine("--tw-shadow-colored: 0 0 #0000;")
$null = $css.AppendLine("--tw-blur: ;")
$null = $css.AppendLine("--tw-brightness: ;")
$null = $css.AppendLine("--tw-contrast: ;")
$null = $css.AppendLine("--tw-grayscale: ;")
$null = $css.AppendLine("--tw-hue-rotate: ;")
$null = $css.AppendLine("--tw-invert: ;")
$null = $css.AppendLine("--tw-saturate: ;")
$null = $css.AppendLine("--tw-sepia: ;")
$null = $css.AppendLine("--tw-drop-shadow: ;")
$null = $css.AppendLine("--tw-backdrop-blur: ;")
$null = $css.AppendLine("--tw-backdrop-brightness: ;")
$null = $css.AppendLine("--tw-backdrop-contrast: ;")
$null = $css.AppendLine("--tw-backdrop-grayscale: ;")
$null = $css.AppendLine("--tw-backdrop-hue-rotate: ;")
$null = $css.AppendLine("--tw-backdrop-invert: ;")
$null = $css.AppendLine("--tw-backdrop-opacity: ;")
$null = $css.AppendLine("--tw-backdrop-saturate: ;")
$null = $css.AppendLine("--tw-backdrop-sepia: ;")
$null = $css.AppendLine("--tw-contain-size: ;")
$null = $css.AppendLine("--tw-contain-layout: ;")
$null = $css.AppendLine("--tw-contain-paint: ;")
$null = $css.AppendLine("--tw-contain-style: ;")
$null = $css.AppendLine("}")

# Universal selector styles
$null = $css.AppendLine("*,:before,:after{box-sizing:border-box;border-width:0;border-style:solid;border-color:#e5e7eb}")
$null = $css.AppendLine(":before,:after{--tw-content: """"}")

# HTML and host styles
$null = $css.AppendLine("html,:host{line-height:1.5;-webkit-text-size-adjust:100%;-moz-tab-size:4;-o-tab-size:4;tab-size:4;font-family:var(--font-sans);font-feature-settings:normal;font-variation-settings:normal;-webkit-tap-highlight-color:transparent}")

# Body styles
$null = $css.AppendLine("body{margin:0;line-height:inherit}")

# HR styles
$null = $css.AppendLine("hr{height:0;color:inherit;border-top-width:1px}")

# ABBR styles
$null = $css.AppendLine("abbr:where([title]){-webkit-text-decoration:underline dotted;text-decoration:underline dotted}")

# Headings styles
$null = $css.AppendLine("h1,h2,h3,h4,h5,h6{font-size:inherit;font-weight:inherit}")

# Anchor styles
$null = $css.AppendLine("a{color:inherit;text-decoration:inherit}")

# Bold styles
$null = $css.AppendLine("b,strong{font-weight:bolder}")

# Code styles
$null = $css.AppendLine("code,kbd,samp,pre{font-family:var(--font-mono);font-feature-settings:normal;font-variation-settings:normal;font-size:1em}")

# Small styles
$null = $css.AppendLine("small{font-size:80%}")

# Sub and sup styles
$null = $css.AppendLine("sub,sup{font-size:75%;line-height:0;position:relative;vertical-align:baseline}")
$null = $css.AppendLine("sub{bottom:-.25em}")
$null = $css.AppendLine("sup{top:-.5em}")

# Table styles
$null = $css.AppendLine("table{text-indent:0;border-color:inherit;border-collapse:collapse}")

# Form elements styles
$null = $css.AppendLine("button,input,optgroup,select,textarea{font-family:inherit;font-feature-settings:inherit;font-variation-settings:inherit;font-size:100%;font-weight:inherit;line-height:inherit;letter-spacing:inherit;color:inherit;margin:0;padding:0}")
$null = $css.AppendLine("button,select{text-transform:none}")
$null = $css.AppendLine("button,input:where([type=button]),input:where([type=reset]),input:where([type=submit]){-webkit-appearance:button;background-color:transparent;background-image:none}")

# Focus ring styles
$null = $css.AppendLine(":-moz-focusring{outline:auto}")

# Invalid UI styles
$null = $css.AppendLine(":-moz-ui-invalid{box-shadow:none}")

# Progress styles
$null = $css.AppendLine("progress{vertical-align:baseline}")

# Spin button styles
$null = $css.AppendLine("::-webkit-inner-spin-button,::-webkit-outer-spin-button{height:auto}")

# Search styles
$null = $css.AppendLine("[type=search]{-webkit-appearance:textfield;outline-offset:-2px}")
$null = $css.AppendLine("::-webkit-search-decoration{-webkit-appearance:none}")
$null = $css.AppendLine("::-webkit-file-upload-button{-webkit-appearance:button;font:inherit}")

# Summary styles
$null = $css.AppendLine("summary{display:list-item}")

# Block elements styles
$null = $css.AppendLine("blockquote,dl,dd,h1,h2,h3,h4,h5,h6,hr,figure,p,pre{margin:0}")

# Fieldset styles
$null = $css.AppendLine("fieldset{margin:0;padding:0}")

# Legend styles
$null = $css.AppendLine("legend{padding:0}")

# List styles
$null = $css.AppendLine("ol,ul,menu{list-style:none;margin:0;padding:0}")

# Dialog styles
$null = $css.AppendLine("dialog{padding:0}")

# Textarea styles
$null = $css.AppendLine("textarea{resize:vertical}")

# Placeholder styles
$null = $css.AppendLine("input::-moz-placeholder,textarea::-moz-placeholder{opacity:1;color:#9ca3af}")
$null = $css.AppendLine("input::placeholder,textarea::placeholder{opacity:1;color:#9ca3af}")

# Button styles
$null = $css.AppendLine("button,[role=button]{cursor:pointer}")

# Disabled styles
$null = $css.AppendLine(":disabled{cursor:default}")

# Media elements styles
$null = $css.AppendLine("img,svg,video,canvas,audio,iframe,embed,object{display:block;vertical-align:middle}")
$null = $css.AppendLine("img,video{max-width:100%;height:auto}")

# Hidden styles
$null = $css.AppendLine("[hidden]:where(:not([hidden=until-found])){display:none}")

# Utility classes - Screen Reader Only
$null = $css.AppendLine(".sr-only{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0,0,0,0);white-space:nowrap;border-width:0}")

# Utility classes - Pointer Events
$null = $css.AppendLine(".pointer-events-none{pointer-events:none}")
$null = $css.AppendLine(".pointer-events-auto{pointer-events:auto}")

# Utility classes - Visibility
$null = $css.AppendLine(".visible{visibility:visible}")
$null = $css.AppendLine(".invisible{visibility:hidden}")

# Utility classes - Position
$null = $css.AppendLine(".fixed{position:fixed}")
$null = $css.AppendLine(".absolute{position:absolute}")
$null = $css.AppendLine(".relative{position:relative}")
$null = $css.AppendLine(".inset-0{inset:0}")
$null = $css.AppendLine(".inset-x-0{left:0;right:0}")
$null = $css.AppendLine(".inset-y-0{top:0;bottom:0}")
$null = $css.AppendLine(".-bottom-12{bottom:-3rem}")
$null = $css.AppendLine(".-left-12{left:-3rem}")
$null = $css.AppendLine(".-right-12{right:-3rem}")
$null = $css.AppendLine(".-top-12{top:-3rem}")
$null = $css.AppendLine(".bottom-0{bottom:0}")
$null = $css.AppendLine(".left-0{left:0}")
$null = $css.AppendLine(".left-1{left:.25rem}")
$null = $css.AppendLine(".left-1/2{left:50%}")
$null = $css.AppendLine(".left-2{left:.5rem}")
$null = $css.AppendLine(".left-4{left:1rem}")
$null = $css.AppendLine(".left-[50%]{left:50%}")
$null = $css.AppendLine(".right-0{right:0}")
$null = $css.AppendLine(".right-1{right:.25rem}")
$null = $css.AppendLine(".right-2{right:.5rem}")
$null = $css.AppendLine(".right-3{right:.75rem}")
$null = $css.AppendLine(".right-4{right:1rem}")
$null = $css.AppendLine(".top-0{top:0}")
$null = $css.AppendLine(".top-1.5{top:.375rem}")
$null = $css.AppendLine(".top-1/2{top:50%}")
$null = $css.AppendLine(".top-16{top:4rem}")
$null = $css.AppendLine(".top-2{top:.5rem}")
$null = $css.AppendLine(".top-20{top:5rem}")
$null = $css.AppendLine(".top-3.5{top:.875rem}")
$null = $css.AppendLine(".top-32{top:8rem}")
$null = $css.AppendLine(".top-4{top:1rem}")
$null = $css.AppendLine(".top-[1px]{top:1px}")
$null = $css.AppendLine(".top-[50%]{top:50%}")
$null = $css.AppendLine(".top-[60%]{top:60%}")
$null = $css.AppendLine(".top-full{top:100%}")

# Utility classes - Z-Index
$null = $css.AppendLine(".z-10{z-index:10}")
$null = $css.AppendLine(".z-20{z-index:20}")
$null = $css.AppendLine(".z-50{z-index:50}")
$null = $css.AppendLine(".z-[100]{z-index:100}")
$null = $css.AppendLine(".z-[1]{z-index:1}")

# Utility classes - Margin
$null = $css.AppendLine(".-mx-1{margin-left:-.25rem;margin-right:-.25rem}")
$null = $css.AppendLine(".mx-2{margin-left:.5rem;margin-right:.5rem}")
$null = $css.AppendLine(".mx-3.5{margin-left:.875rem;margin-right:.875rem}")
$null = $css.AppendLine(".mx-4{margin-left:1rem;margin-right:1rem}")
$null = $css.AppendLine(".mx-auto{margin-left:auto;margin-right:auto}")
$null = $css.AppendLine(".my-0.5{margin-top:.125rem;margin-bottom:.125rem}")
$null = $css.AppendLine(".my-1{margin-top:.25rem;margin-bottom:.25rem}")
$null = $css.AppendLine(".-ml-4{margin-left:-1rem}")
$null = $css.AppendLine(".-mt-4{margin-top:-1rem}")
$null = $css.AppendLine(".mb-1{margin-bottom:.25rem}")
$null = $css.AppendLine(".mb-2{margin-bottom:.5rem}")
$null = $css.AppendLine(".mb-3{margin-bottom:.75rem}")
$null = $css.AppendLine(".mb-4{margin-bottom:1rem}")
$null = $css.AppendLine(".mb-6{margin-bottom:1.5rem}")
$null = $css.AppendLine(".mb-8{margin-bottom:2rem}")
$null = $css.AppendLine(".ml-1{margin-left:.25rem}")
$null = $css.AppendLine(".ml-1.5{margin-left:.375rem}")
$null = $css.AppendLine(".ml-2{margin-left:.5rem}")
$null = $css.AppendLine(".ml-auto{margin-left:auto}")
$null = $css.AppendLine(".mr-2{margin-right:.5rem}")
$null = $css.AppendLine(".mt-0.5{margin-top:.125rem}")
$null = $css.AppendLine(".mt-1.5{margin-top:.375rem}")
$null = $css.AppendLine(".mt-2{margin-top:.5rem}")
$null = $css.AppendLine(".mt-24{margin-top:6rem}")
$null = $css.AppendLine(".mt-3{margin-top:.75rem}")
$null = $css.AppendLine(".mt-4{margin-top:1rem}")
$null = $css.AppendLine(".mt-auto{margin-top:auto}")

# Utility classes - Display
$null = $css.AppendLine(".block{display:block}")
$null = $css.AppendLine(".inline-block{display:inline-block}")
$null = $css.AppendLine(".flex{display:flex}")
$null = $css.AppendLine(".inline-flex{display:inline-flex}")
$null = $css.AppendLine(".table{display:table}")
$null = $css.AppendLine(".grid{display:grid}")
$null = $css.AppendLine(".hidden{display:none}")

# Utility classes - Aspect Ratio
$null = $css.AppendLine(".aspect-square{aspect-ratio:1 / 1}")
$null = $css.AppendLine(".aspect-video{aspect-ratio:16 / 9}")

# Utility classes - Sizing
$null = $css.AppendLine(".size-4{width:1rem;height:1rem}")
$null = $css.AppendLine(".h-1.5{height:.375rem}")
$null = $css.AppendLine(".h-10{height:2.5rem}")
$null = $css.AppendLine(".h-11{height:2.75rem}")
$null = $css.AppendLine(".h-12{height:3rem}")
$null = $css.AppendLine(".h-14{height:3.5rem}")
$null = $css.AppendLine(".h-16{height:4rem}")
$null = $css.AppendLine(".h-2{height:.5rem}")
$null = $css.AppendLine(".h-2.5{height:.625rem}")
$null = $css.AppendLine(".h-20{height:5rem}")
$null = $css.AppendLine(".h-3{height:.75rem}")
$null = $css.AppendLine(".h-3.5{height:.875rem}")
$null = $css.AppendLine(".h-32{height:8rem}")
$null = $css.AppendLine(".h-4{height:1rem}")
$null = $css.AppendLine(".h-5{height:1.25rem}")
$null = $css.AppendLine(".h-6{height:1.5rem}")
$null = $css.AppendLine(".h-7{height:1.75rem}")
$null = $css.AppendLine(".h-8{height:2rem}")
$null = $css.AppendLine(".h-9{height:2.25rem}")
$null = $css.AppendLine(".h-[1px]{height:1px}")
$null = $css.AppendLine(".h-[var(--radix-navigation-menu-viewport-height)]{height:var(--radix-navigation-menu-viewport-height)}")
$null = $css.AppendLine(".h-[var(--radix-select-trigger-height)]{height:var(--radix-select-trigger-height)}")
$null = $css.AppendLine(".h-auto{height:auto}")
$null = $css.AppendLine(".h-full{height:100%}")
$null = $css.AppendLine(".h-px{height:1px}")
$null = $css.AppendLine(".h-svh{height:100svh}")
$null = $css.AppendLine(".max-h-[--radix-context-menu-content-available-height]{max-height:var(--radix-context-menu-content-available-height)}")
$null = $css.AppendLine(".max-h-[--radix-select-content-available-height]{max-height:var(--radix-select-content-available-height)}")
$null = $css.AppendLine(".max-h-[300px]{max-height:300px}")
$null = $css.AppendLine(".max-h-[var(--radix-dropdown-menu-content-available-height)]{max-height:var(--radix-dropdown-menu-content-available-height)}")
$null = $css.AppendLine(".max-h-screen{max-height:100vh}")
$null = $css.AppendLine(".min-h-0{min-height:0px}")
$null = $css.AppendLine(".min-h-10{min-height:2.5rem}")
$null = $css.AppendLine(".min-h-8{min-height:2rem}")
$null = $css.AppendLine(".min-h-9{min-height:2.25rem}")
$null = $css.AppendLine(".min-h-[80px]{min-height:80px}")
$null = $css.AppendLine(".min-h-dvh{min-height:100dvh}")
$null = $css.AppendLine(".min-h-screen{min-height:100vh}")
$null = $css.AppendLine(".min-h-svh{min-height:100svh}")
$null = $css.AppendLine(".w-0{width:0px}")
$null = $css.AppendLine(".w-1{width:.25rem}")
$null = $css.AppendLine(".w-10{width:2.5rem}")
$null = $css.AppendLine(".w-11{width:2.75rem}")
$null = $css.AppendLine(".w-12{width:3rem}")
$null = $css.AppendLine(".w-14{width:3.5rem}")
$null = $css.AppendLine(".w-16{width:4rem}")
$null = $css.AppendLine(".w-2{width:.5rem}")
$null = $css.AppendLine(".w-2.5{width:.625rem}")
$null = $css.AppendLine(".w-20{width:5rem}")
$null = $css.AppendLine(".w-3{width:.75rem}")
$null = $css.AppendLine(".w-3.5{width:.875rem}")
$null = $css.AppendLine(".w-3/4{width:75%}")
$null = $css.AppendLine(".w-32{width:8rem}")
$null = $css.AppendLine(".w-4{width:1rem}")
$null = $css.AppendLine(".w-5{width:1.25rem}")
$null = $css.AppendLine(".w-64{width:16rem}")
$null = $css.AppendLine(".w-7{width:1.75rem}")
$null = $css.AppendLine(".w-72{width:18rem}")
$null = $css.AppendLine(".w-8{width:2rem}")
$null = $css.AppendLine(".w-9{width:2.25rem}")
$null = $css.AppendLine(".w-[100px]{width:100px}")
$null = $css.AppendLine(".w-[1px]{width:1px}")
$null = $css.AppendLine(".w-[var(--sidebar-width)]{width:var(--sidebar-width)}")
$null = $css.AppendLine(".w-auto{width:auto}")
$null = $css.AppendLine(".w-full{width:100%}")
$null = $css.AppendLine(".w-max{width:-moz-max-content;width:max-content}")
$null = $css.AppendLine(".w-px{width:1px}")
$null = $css.AppendLine(".min-w-0{min-width:0px}")
$null = $css.AppendLine(".min-w-10{min-width:2.5rem}")
$null = $css.AppendLine(".min-w-11{min-width:2.75rem}")
$null = $css.AppendLine(".min-w-5{min-width:1.25rem}")
$null = $css.AppendLine(".min-w-9{min-width:2.25rem}")
$null = $css.AppendLine(".min-w-[12rem]{min-width:12rem}")
$null = $css.AppendLine(".min-w-[8rem]{min-width:8rem}")
$null = $css.AppendLine(".min-w-[var(--radix-select-trigger-width)]{min-width:var(--radix-select-trigger-width)}")
$null = $css.AppendLine(".max-w-[var(--skeleton-width)]{max-width:var(--skeleton-width)}")
$null = $css.AppendLine(".max-w-lg{max-width:32rem}")
$null = $css.AppendLine(".max-w-max{max-width:-moz-max-content;max-width:max-content}")
$null = $css.AppendLine(".max-w-md{max-width:28rem}")
$null = $css.AppendLine(".max-w-sm{max-width:24rem}")

# Utility classes - Flexbox
$null = $css.AppendLine(".flex-1{flex:1 1 0%}")
$null = $css.AppendLine(".shrink-0{flex-shrink:0}")
$null = $css.AppendLine(".grow{flex-grow:1}")
$null = $css.AppendLine(".grow-0{flex-grow:0}")
$null = $css.AppendLine(".basis-full{flex-basis:100%}")

# Utility classes - Table
$null = $css.AppendLine(".caption-bottom{caption-side:bottom}")

# Utility classes - Border Collapse
$null = $css.AppendLine(".border-collapse{border-collapse:collapse}")

# Utility classes - Transform Origin
$null = $css.AppendLine(".origin-[--radix-context-menu-content-transform-origin]{transform-origin:var(--radix-context-menu-content-transform-origin)}")
$null = $css.AppendLine(".origin-[--radix-dropdown-menu-content-transform-origin]{transform-origin:var(--radix-dropdown-menu-content-transform-origin)}")
$null = $css.AppendLine(".origin-[--radix-hover-card-content-transform-origin]{transform-origin:var(--radix-hover-card-content-transform-origin)}")
$null = $css.AppendLine(".origin-[--radix-menubar-content-transform-origin]{transform-origin:var(--radix-menubar-content-transform-origin)}")
$null = $css.AppendLine(".origin-[--radix-popover-content-transform-origin]{transform-origin:var(--radix-popover-content-transform-origin)}")
$null = $css.AppendLine(".origin-[--radix-select-content-transform-origin]{transform-origin:var(--radix-select-content-transform-origin)}")
$null = $css.AppendLine(".origin-[--radix-tooltip-content-transform-origin]{transform-origin:var(--radix-tooltip-content-transform-origin)}")

# Utility classes - Transforms
$null = $css.AppendLine(".-translate-x-1/2{--tw-translate-x: -50%;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}")
$null = $css.AppendLine(".-translate-x-px{--tw-translate-x: -1px;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}")
$null = $css.AppendLine(".-translate-y-1/2{--tw-translate-y: -50%;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}")
$null = $css.AppendLine(".translate-x-[-50%]{--tw-translate-x: -50%;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}")
$null = $css.AppendLine(".translate-x-px{--tw-translate-x: 1px;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}")
$null = $css.AppendLine(".translate-y-[-50%]{--tw-translate-y: -50%;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}")
$null = $css.AppendLine(".rotate-45{--tw-rotate: 45deg;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}")
$null = $css.AppendLine(".rotate-90{--tw-rotate: 90deg;transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}")
$null = $css.AppendLine(".transform{transform:translate(var(--tw-translate-x),var(--tw-translate-y)) rotate(var(--tw-rotate)) skew(var(--tw-skew-x)) skewY(var(--tw-skew-y)) scaleX(var(--tw-scale-x)) scaleY(var(--tw-scale-y))}")

# Utility classes - Animations
$null = $css.AppendLine("@keyframes pulse{50%{opacity:.5}}")
$null = $css.AppendLine(".animate-pulse{animation:pulse 2s cubic-bezier(.4,0,.6,1) infinite}")
$null = $css.AppendLine("@keyframes spin{to{transform:rotate(360deg)}}")
$null = $css.AppendLine(".animate-spin{animation:spin 1s linear infinite}")

# Utility classes - Cursor
$null = $css.AppendLine(".cursor-default{cursor:default}")
$null = $css.AppendLine(".cursor-pointer{cursor:pointer}")

# Utility classes - Touch Action
$null = $css.AppendLine(".touch-none{touch-action:none}")

# Utility classes - User Select
$null = $css.AppendLine(".select-none{-webkit-user-select:none;-moz-user-select:none;user-select:none}")

# Utility classes - List Style
$null = $css.AppendLine(".list-none{list-style-type:none}")

# Utility classes - Grid Template Columns
$null = $css.AppendLine(".grid-cols-3{grid-template-columns:repeat(3,minmax(0,1fr))}")
$null = $css.AppendLine(".grid-cols-4{grid-template-columns:repeat(4,minmax(0,1fr))}")

# Utility classes - Flex Direction
$null = $css.AppendLine(".flex-row{flex-direction:row}")
$null = $css.AppendLine(".flex-col{flex-direction:column}")
$null = $css.AppendLine(".flex-col-reverse{flex-direction:column-reverse}")

# Utility classes - Flex Wrap
$null = $css.AppendLine(".flex-wrap{flex-wrap:wrap}")

# Utility classes - Align Items
$null = $css.AppendLine(".items-start{align-items:flex-start}")
$null = $css.AppendLine(".items-end{align-items:flex-end}")
$null = $css.AppendLine(".items-center{align-items:center}")
$null = $css.AppendLine(".items-stretch{align-items:stretch}")

# Utility classes - Justify Content
$null = $css.AppendLine(".justify-center{justify-content:center}")
$null = $css.AppendLine(".justify-between{justify-content:space-between}")

# Utility classes - Gap
$null = $css.AppendLine(".gap-1{gap:.25rem}")
$null = $css.AppendLine
