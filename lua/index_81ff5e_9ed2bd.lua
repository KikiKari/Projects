#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "80258717ef332f15936830f2b07e605cd240145e6bbd4a779299146d40a58214", "source_sha256": "9ed2bdeb80b99c649aeb5bf47416f21d76279e40bca0b04d2f75f7e1afd3a910", "target_language": "lua"}
-- index_81ff5e.css — portiert nach lua
-- Quelle: css, Projects@abstractions:css/index_81ff5e.css
-- Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

local function generate_css()
    local css = {}

    -- Helper function to add rules
    local function add_rule(selector, properties)
        table.insert(css, selector .. " {")
        for _, prop in ipairs(properties) do
            table.insert(css, "  " .. prop)
        end
        table.insert(css, "}")
        table.insert(css, "")
    end

    -- Root variables
    add_rule(":root", {
        "color-scheme: light;",
        "--ink: #1b1c1f;",
        "--muted: #6c6e75;",
        "--faint: #9a9ca3;",
        "--card: #fff;",
        "--line: #e9eaee;",
        "--accent: #5b5bd6;",
        "--accent2: #7c5cff;",
        "--ok: #22a06b;",
        "--err: #e0533d;",
        "--radius: 16px;",
        "--shadow: 0 1px 2px rgba(20, 20, 40, 0.04), 0 6px 20px rgba(20, 20, 40, 0.06);"
    })

    -- Universal selector
    add_rule("*", {
        "box-sizing: border-box;"
    })

    -- Body styles
    add_rule("body", {
        "margin: 0;",
        'font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;',
        "color: var(--ink);",
        "min-height: 100vh;",
        "background: radial-gradient(1100px 560px at 100% -10%, #e8ecff 0%, rgba(232, 236, 255, 0) 55%), linear-gradient(180deg, #eef1f6, #f7f7f8 42%);",
        "background-attachment: fixed;"
    })

    -- Wrap class
    add_rule(".wrap", {
        "max-width: 820px;",
        "margin: 0 auto;",
        "padding: 24px 18px 70px;"
    })

    -- Brand class
    add_rule(".brand", {
        "display: flex;",
        "align-items: center;",
        "gap: 12px;",
        "margin-bottom: 4px;"
    })

    -- Mark class and pseudo-element
    add_rule(".mark", {
        "width: 32px;",
        "height: 32px;",
        "border-radius: 9px;",
        "background: linear-gradient(135deg, var(--accent), var(--accent2));",
        "box-shadow: 0 4px 12px rgba(91, 91, 214, 0.35);",
        "position: relative;",
        "flex: 0 0 auto;"
    })

    add_rule(".mark:after", {
        'content: "";',
        "position: absolute;",
        "inset: 8px;",
        "border-radius: 4px;",
        "border: 2px solid rgba(255, 255, 255, 0.92);"
    })

    -- Heading styles
    add_rule("h1", {
        "font-size: 21px;",
        "margin: 0;",
        "font-weight: 700;"
    })

    add_rule(".sub", {
        "color: var(--muted);",
        "font-size: 13px;",
        "margin: 2px 0 16px;"
    })

    -- Card styles
    add_rule(".card", {
        "background: var(--card);",
        "border: 1px solid var(--line);",
        "border-radius: var(--radius);",
        "box-shadow: var(--shadow);",
        "padding: 16px;",
        "margin-bottom: 14px;"
    })

    add_rule(".card h2", {
        "font-size: 14px;",
        "margin: 0 0 10px;"
    })

    -- Label styles
    add_rule("label.lab", {
        "display: block;",
        "font-size: 12px;",
        "font-weight: 600;",
        "color: var(--muted);",
        "margin: 8px 0 3px;"
    })

    -- Input and textarea styles
    add_rule("input, textarea", {
        "width: 100%;",
        "font-size: 13px;",
        "padding: 8px 10px;",
        "border: 1px solid var(--line);",
        "border-radius: 9px;",
        "font-family: ui-monospace, Menlo, Consolas, monospace;",
        "background: #fff;"
    })

    add_rule("textarea", {
        "min-height: 90px;",
        "white-space: pre;",
        "overflow: auto;"
    })

    -- Row styles
    add_rule(".row", {
        "display: flex;",
        "gap: 8px;",
        "flex-wrap: wrap;",
        "align-items: center;"
    })

    -- Button styles
    add_rule(".btn", {
        "font-size: 13px;",
        "font-weight: 600;",
        "padding: 8px 14px;",
        "border: 1px solid var(--line);",
        "border-radius: 10px;",
        "background: #fff;",
        "cursor: pointer;",
        "box-shadow: var(--shadow);",
        "transition: transform 0.1s;"
    })

    add_rule(".btn:hover", {
        "transform: translateY(-1px);"
    })

    add_rule(".btn.primary", {
        "background: linear-gradient(135deg, var(--accent), var(--accent2));",
        "color: #fff;",
        "border-color: transparent;"
    })

    add_rule(".btn.sm", {
        "padding: 5px 9px;",
        "font-size: 12px;"
    })

    -- Message styles
    add_rule(".msg", {
        "font-size: 12px;",
        "margin-left: 6px;"
    })

    add_rule(".msg.ok", {
        "color: var(--ok);"
    })

    add_rule(".msg.err", {
        "color: var(--err);"
    })

    -- Provenance styles
    add_rule(".prov", {
        "border: 1px solid var(--line);",
        "border-radius: 12px;",
        "padding: 10px 12px;",
        "margin-bottom: 10px;"
    })

    add_rule(".prov h3", {
        "margin: 0 0 6px;",
        "font-size: 13.5px;",
        "display: flex;",
        "align-items: center;",
        "gap: 8px;"
    })

    -- Key-value styles
    add_rule(".kv", {
        "display: grid;",
        "grid-template-columns: 180px 1fr auto;",
        "gap: 6px;",
        "margin: 4px 0;",
        "align-items: center;"
    })

    add_rule(".kv input", {
        "font-size: 12px;",
        "padding: 5px 7px;"
    })

    add_rule(".kv .k", {
        "color: var(--muted);",
        "font-weight: 600;"
    })

    -- Muted text
    add_rule(".muted", {
        "color: var(--faint);",
        "font-size: 13px;"
    })

    -- Hidden elements
    add_rule(".hide", {
        "display: none;"
    })

    -- Footer styles
    add_rule(".foot", {
        "color: var(--faint);",
        "font-size: 11.5px;",
        "text-align: center;",
        "margin-top: 18px;",
        "line-height: 1.5;"
    })

    -- Link styles
    add_rule("a", {
        "color: var(--accent);"
    })

    return table.concat(css, "\n")
end

-- Main execution
local filename = arg[1]
if not filename then
    print("Usage: " .. arg[0] .. " <output_file>")
    os.exit(1)
end

local file = io.open(filename, "w")
if not file then
    print("Error: Could not open file " .. filename .. " for writing")
    os.exit(1)
end

file:write(generate_css())
file:close()

print("CSS written to " .. filename)
