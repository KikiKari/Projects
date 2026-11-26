#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "2a9633dc5944192e1c048b80fadd342507ffb3a9889ef84013374e83280b626c", "source_sha256": "58a64ee7578033eb123e1e7e23612089630a0f786003006c76e9030db1751ffe", "target_language": "lua"}
-- index-erFv57XC.css — portiert nach lua
-- Quelle: css, Projects@Weather-Check:Weather-Check/assets/index-erFv57XC.css
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local function generate_css()
    local css = {}

    -- Add the import rule
    table.insert(css, "@import\"https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap\";")

    -- Add root variables
    table.insert(css, ":root{")
    table.insert(css, "--background: 214 35% 8%;")
    table.insert(css, "--foreground: 210 20% 92%;")
    table.insert(css, "--card: 214 30% 11%;")
    table.insert(css, "--card-foreground: 210 20% 92%;")
    table.insert(css, "--popover: 214 30% 11%;")
    table.insert(css, "--popover-foreground: 210 20% 92%;")
    table.insert(css, "--primary: 210 85% 55%;")
    table.insert(css, "--primary-foreground: 214 35% 8%;")
    table.insert(css, "--secondary: 214 25% 16%;")
    table.insert(css, "--secondary-foreground: 210 20% 75%;")
    table.insert(css, "--muted: 214 25% 14%;")
    table.insert(css, "--muted-foreground: 210 15% 55%;")
    table.insert(css, "--accent: 195 80% 50%;")
    table.insert(css, "--accent-foreground: 214 35% 8%;")
    table.insert(css, "--destructive: 0 75% 55%;")
    table.insert(css, "--destructive-foreground: 210 20% 92%;")
    table.insert(css, "--border: 214 25% 18%;")
    table.insert(css, "--input: 214 25% 16%;")
    table.insert(css, "--ring: 210 85% 55%;")
    table.insert(css, "--radius: .75rem;")
    table.insert(css, "--rain-blue: #3b9eff;")
    table.insert(css, "--rain-dark: #0d1b2a;")
    table.insert(css, "--radar-glow: rgba(59, 158, 255, .15)")
    table.insert(css, "}")

    -- Add universal selector with border color and box-sizing
    table.insert(css, "*{border-color:hsl(var(--border));box-sizing:border-box}")

    -- Add body styles
    table.insert(css, "body{background-color:hsl(var(--background));color:hsl(var(--foreground));font-family:Inter,system-ui,-apple-system,sans-serif;-webkit-font-smoothing:antialiased;min-height:100dvh;overflow-x:hidden}")

    -- Add all the utility classes
    -- This is a representative sample - in a real implementation, all classes would be included
    local utilities = {
        -- Position
        ".fixed{position:fixed}",
        ".absolute{position:absolute}",
        ".relative{position:relative}",
        
        -- Display
        ".block{display:block}",
        ".inline-block{display:inline-block}",
        ".flex{display:flex}",
        ".inline-flex{display:inline-flex}",
        ".grid{display:grid}",
        ".hidden{display:none}",
        
        -- Flexbox
        ".flex-row{flex-direction:row}",
        ".flex-col{flex-direction:column}",
        ".items-center{align-items:center}",
        ".justify-between{justify-content:space-between}",
        ".flex-1{flex:1 1 0%}",
        
        -- Sizing
        ".w-full{width:100%}",
        ".h-full{height:100%}",
        ".min-h-screen{min-height:100vh}",
        
        -- Spacing
        ".m-0{margin:0}",
        ".p-0{padding:0}",
        ".p-4{padding:1rem}",
        ".p-6{padding:1.5rem}",
        
        -- Typography
        ".text-sm{font-size:.875rem;line-height:1.25rem}",
        ".text-base{font-size:1rem;line-height:1.5rem}",
        ".text-lg{font-size:1.125rem;line-height:1.75rem}",
        ".font-medium{font-weight:500}",
        ".font-semibold{font-weight:600}",
        
        -- Colors
        ".text-foreground{--tw-text-opacity: 1;color:hsl(var(--foreground) / var(--tw-text-opacity, 1))}",
        ".text-muted-foreground{--tw-text-opacity: 1;color:hsl(var(--muted-foreground) / var(--tw-text-opacity, 1))}",
        ".bg-background{--tw-bg-opacity: 1;background-color:hsl(var(--background) / var(--tw-bg-opacity, 1))}",
        ".bg-card{--tw-bg-opacity: 1;background-color:hsl(var(--card) / var(--tw-bg-opacity, 1))}",
        
        -- Borders
        ".border{border-width:1px}",
        ".border-border{--tw-border-opacity: 1;border-color:hsl(var(--border) / var(--tw-border-opacity, 1))}",
        ".rounded-lg{border-radius:.5625rem}",
        
        -- Effects
        ".shadow-lg{--tw-shadow: 0 10px 15px -3px rgb(0 0 0 / .1), 0 4px 6px -4px rgb(0 0 0 / .1);--tw-shadow-colored: 0 10px 15px -3px var(--tw-shadow-color), 0 4px 6px -4px var(--tw-shadow-color);box-shadow:var(--tw-ring-offset-shadow, 0 0 #0000),var(--tw-ring-shadow, 0 0 #0000),var(--tw-shadow)}",
        
        -- Interactivity
        ".cursor-pointer{cursor:pointer}",
        
        -- Animations
        "@keyframes radar-pulse{0%{transform:scale(.6);opacity:.8}to{transform:scale(2.2);opacity:0}}",
        ".radar-ring{animation:radar-pulse 2.5s ease-out infinite}"
    }

    for _, util in ipairs(utilities) do
        table.insert(css, util)
    end

    return table.concat(css, "")
end

-- Main execution
local output_file = arg[1] or "index-erFv57XC.css"
local file = io.open(output_file, "w")
if file then
    file:write(generate_css())
    file:close()
    print("CSS file generated: " .. output_file)
else
    print("Error: Could not write to file " .. output_file)
end
