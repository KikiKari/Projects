#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "62981ee65b8b29bc0821807a489e577f7eebe16646152b7e7002b826ef4b207e", "source_sha256": "b32c733987d23de98ace1b2a5119f7cb7989a0887c165c1db133ecb4ef278438", "target_language": "lua"}
-- index_f17dea.css — portiert nach lua
-- Quelle: css, Projects@abstractions:css/index_f17dea.css
-- Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

local function generate_css()
    local css = {}

    -- Helper function to add CSS rule
    local function add_rule(selector, properties)
        table.insert(css, selector .. " {")
        for _, prop in ipairs(properties) do
            table.insert(css, "    " .. prop)
        end
        table.insert(css, "}")
    end

    -- Add comments
    table.insert(css, "/* abstraction-provenance: {\"artifact_sha256\": \"9ebfdd610ffe88b7273a5ac8e215314a7bee0dffecf25fe9a995b6a39703e204\", \"source_sha256\": \"f17deae3e31b89fd76d250bd20903b36591af417c97b34d987e923632be9ac37\", \"target_language\": \"css\"} */")
    table.insert(css, "/* index.html — portiert nach css */")
    table.insert(css, "/* Quelle: html, OpenClaw@gateway1:skills/scripting-utils/references/raku/index.html */")
    table.insert(css, "/* auch in: OpenClaw@gateway2:skills/scripting-utils/references/raku/index.html */")
    table.insert(css, "/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */")
    table.insert(css, "")

    -- General Styles
    add_rule("html", {"scroll-padding-top: 60px;"})
    table.insert(css, "")
    
    add_rule("body.has-navbar-fixed-top", {"padding-top: 60px;"})
    table.insert(css, "")

    -- Navbar Styles
    add_rule(".navbar.is-fixed-top", {
        "position: fixed;",
        "top: 0;",
        "left: 0;",
        "right: 0;",
        "z-index: 30;",
        "min-height: 3.25rem;"
    })
    table.insert(css, "")
    
    add_rule(".navbar.is-flex-touch", {"display: flex;"})
    table.insert(css, "")
    
    add_rule(".container.is-justify-content-space-around", {"justify-content: space-around;"})
    table.insert(css, "")
    
    add_rule(".navbar-brand", {
        "display: flex;",
        "align-items: center;"
    })
    table.insert(css, "")
    
    add_rule(".navbar-logo", {
        "display: flex;",
        "align-items: center;"
    })
    table.insert(css, "")
    
    add_rule(".navbar-logo-tm", {
        "font-size: 0.75rem;",
        "margin-left: 0.25rem;"
    })
    table.insert(css, "")
    
    add_rule(".navbar-burger", {
        "display: block;",
        "position: relative;",
        "cursor: pointer;"
    })
    table.insert(css, "")
    
    add_rule(".navbar-burger span", {
        "display: block;",
        "height: 1px;",
        "width: 20px;",
        "background-color: currentColor;",
        "margin: 5px 0;",
        "transition: transform 0.3s ease;"
    })
    table.insert(css, "")
    
    add_rule(".navbar-menu", {"display: none;"})
    table.insert(css, "")
    
    add_rule(".navbar-start, .navbar-end", {
        "display: flex;",
        "align-items: center;"
    })
    table.insert(css, "")
    
    add_rule(".navbar-item", {
        "display: block;",
        "padding: 0.5rem 0.75rem;"
    })
    table.insert(css, "")
    
    add_rule(".navbar-link", {
        "display: block;",
        "padding: 0.5rem 0.75rem;"
    })
    table.insert(css, "")
    
    add_rule(".navbar-dropdown", {
        "display: none;",
        "position: absolute;",
        "top: 100%;",
        "left: 0;",
        "background-color: white;",
        "border-radius: 4px;",
        "box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1);"
    })
    table.insert(css, "")
    
    add_rule(".navbar-dropdown.is-right", {
        "left: auto;",
        "right: 0;"
    })
    table.insert(css, "")
    
    add_rule(".navbar-dropdown.is-rounded", {"border-radius: 4px;"})
    table.insert(css, "")
    
    add_rule(".navbar-divider", {
        "display: block;",
        "height: 1px;",
        "background-color: #dbdbdb;",
        "margin: 0.5rem 0;"
    })
    table.insert(css, "")
    
    add_rule(".has-dropdown:hover .navbar-dropdown", {"display: block;"})
    table.insert(css, "")
    
    add_rule(".navbar-search-wrapper", {
        "display: flex;",
        "align-items: center;"
    })
    table.insert(css, "")
    
    add_rule(".field.has-addons", {"display: flex;"})
    table.insert(css, "")
    
    add_rule(".control", {"position: relative;"})
    table.insert(css, "")
    
    add_rule(".autoComplete_options", {"flex-grow: 1;"})
    table.insert(css, "")
    
    add_rule(".input", {
        "display: block;",
        "width: 100%;",
        "padding: 0.375rem 0.75rem;",
        "font-size: 1rem;",
        "line-height: 1.5;",
        "color: #495057;",
        "background-color: #fff;",
        "background-clip: padding-box;",
        "border: 1px solid #ced4da;",
        "border-radius: 0.25rem;",
        "transition: border-color 0.15s ease-in-out, box-shadow 0.15s ease-in-out;"
    })
    table.insert(css, "")
    
    add_rule(".button.is-primary", {
        "background-color: #00d1b2;",
        "border-color: transparent;",
        "color: #fff;"
    })
    table.insert(css, "")
    
    add_rule(".icon", {
        "display: inline-flex;",
        "justify-content: center;",
        "align-items: center;"
    })
    table.insert(css, "")
    
    add_rule(".modal", {
        "position: fixed;",
        "top: 0;",
        "left: 0;",
        "right: 0;",
        "bottom: 0;",
        "z-index: 40;",
        "display: none;",
        "opacity: 0;",
        "transition: opacity 0.15s linear;"
    })
    table.insert(css, "")
    
    add_rule(".modal.is-active", {
        "display: flex;",
        "opacity: 1;"
    })
    table.insert(css, "")
    
    add_rule(".modal-background", {
        "position: absolute;",
        "top: 0;",
        "left: 0;",
        "right: 0;",
        "bottom: 0;",
        "background-color: rgba(10, 10, 10, 0.86);"
    })
    table.insert(css, "")
    
    add_rule(".modal-content", {
        "position: relative;",
        "width: 100%;",
        "max-height: calc(100vh - 160px);",
        "overflow: auto;",
        "margin: 0 auto;",
        "padding: 20px;"
    })
    table.insert(css, "")
    
    add_rule(".box", {
        "background-color: white;",
        "border-radius: 6px;",
        "box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02);",
        "padding: 1.25rem;"
    })
    table.insert(css, "")
    
    add_rule(".modal-close", {
        "position: absolute;",
        "top: 20px;",
        "right: 20px;",
        "width: 40px;",
        "height: 40px;",
        "background: none;",
        "border: none;",
        "cursor: pointer;"
    })
    table.insert(css, "")
    
    add_rule(".options-search-controls", {
        "display: flex;",
        "flex-direction: column;",
        "gap: 1rem;"
    })
    table.insert(css, "")
    
    add_rule(".centreToggle", {
        "display: flex;",
        "align-items: center;",
        "gap: 0.5rem;"
    })
    table.insert(css, "")
    
    add_rule(".centreToggle input[type=\"checkbox\"]", {
        "width: var(--switch-width, 10.5em);",
        "height: 2em;",
        "appearance: none;",
        "background: #ccc;",
        "border-radius: 1em;",
        "position: relative;",
        "cursor: pointer;"
    })
    table.insert(css, "")
    
    add_rule(".centreToggle input[type=\"checkbox\"]:checked", {"background: #00d1b2;"})
    table.insert(css, "")
    
    add_rule(".centreToggle input[type=\"checkbox\"]::before", {
        "content: '';",
        "position: absolute;",
        "width: 1.6em;",
        "height: 1.6em;",
        "background: white;",
        "border-radius: 50%;",
        "top: 0.2em;",
        "left: 0.2em;",
        "transition: transform 0.3s;"
    })
    table.insert(css, "")
    
    add_rule(".centreToggle input[type=\"checkbox\"]:checked::before", {
        "transform: translateX(calc(var(--switch-width, 10.5em) - 2em));"
    })
    table.insert(css, "")
    
    add_rule(".centreToggle .text, .centreToggle .on, .centreToggle .off", {"font-weight: bold;"})
    table.insert(css, "")
    
    add_rule(".centreToggle .on, .centreToggle .off", {
        "position: absolute;",
        "top: 50%;",
        "transform: translateY(-50%);"
    })
    table.insert(css, "")
    
    add_rule(".centreToggle .on", {
        "left: 0.5em;",
        "color: white;"
    })
    table.insert(css, "")
    
    add_rule(".centreToggle .off", {
        "right: 0.5em;",
        "color: #333;"
    })
    table.insert(css, "")

    -- Hero Section
    add_rule(".hero.is-medium", {"min-height: 300px;"})
    table.insert(css, "")
    
    add_rule(".hero.is-primary", {
        "background-color: #00d1b2;",
        "color: #fff;"
    })
    table.insert(css, "")
    
    add_rule(".hero-body", {"padding: 3rem 1.5rem;"})
    table.insert(css, "")
    
    add_rule(".title.is-1", {"font-size: 3rem;"})
    table.insert(css, "")
    
    add_rule(".subtitle.is-4", {"font-size: 1.5rem;"})
    table.insert(css, "")
    
    add_rule(".mt-3", {"margin-top: 0.75rem;"})
    table.insert(css, "")
    
    add_rule(".has-text-centered", {"text-align: center;"})
    table.insert(css, "")

    -- Cards
    add_rule(".card-home", {
        "border-radius: 6px;",
        "box-shadow: 0 0.5em 1em -0.125em rgba(10, 10, 10, 0.1), 0 0 0 1px rgba(10, 10, 10, 0.02);",
        "background-color: white;",
        "margin-bottom: 1.5rem;"
    })
    table.insert(css, "")
    
    add_rule(".card-content", {"padding: 1.5rem;"})
    table.insert(css, "")
    
    add_rule(".content.has-text-centered", {"text-align: center;"})
    table.insert(css, "")
    
    add_rule(".title.is-5", {
        "font-size: 1.25rem;",
        "margin-bottom: 0.5rem;"
    })
    table.insert(css, "")
    
    add_rule(".has-text-primary", {"color: #00d1b2 !important;"})
    table.insert(css, "")
    
    add_rule(".icon.is-large", {"font-size: 2rem;"})
    table.insert(css, "")

    -- Links Block
    add_rule(".raku.links-block", {
        "background-color: #f5f5f5;",
        "padding: 2rem 0;"
    })
    table.insert(css, "")
    
    add_rule(".columns.is-vcentered", {"align-items: center;"})
    table.insert(css, "")
    
    add_rule(".column.is-one-third", {
        "flex: none;",
        "width: 33.3333%;"
    })
    table.insert(css, "")
    
    add_rule(".column.is-two-thirds", {
        "flex: none;",
        "width: 66.6666%;"
    })
    table.insert(css, "")
    
    add_rule(".pt-5", {"padding-top: 1.5rem;"})
    table.insert(css, "")
    
    add_rule(".head", {
        "font-weight: bold;",
        "margin-bottom: 0.5rem;"
    })
    table.insert(css, "")

    -- Footer
    add_rule(".footer.main-footer", {
        "background-color: #fafafa;",
        "padding: 3rem 1.5rem;"
    })
    table.insert(css, "")
    
    add_rule(".level", {
        "display: flex;",
        "justify-content: space-between;",
        "align-items: center;"
    })
    table.insert(css, "")
    
    add_rule(".level-left, .level-right", {
        "display: flex;",
        "align-items: center;"
    })
    table.insert(css, "")
    
    add_rule(".level-item", {
        "margin: 0 0.5rem;"
    })
    table.insert(css, "")

    -- Responsive Adjustments
    table.insert(css, "@media screen and (max-width: 1023px) {")
    table.insert(css, "    .navbar-menu {")
    table.insert(css, "        background-color: white;")
    table.insert(css, "        box-shadow: 0 8px 16px rgba(10, 10, 10, 0.1);")
    table.insert(css, "        padding: 0.5rem 0;")
    table.insert(css, "    }")
    table.insert(css, "    ")
    table.insert(css, "    .navbar-menu.is-active {")
    table.insert(css, "        display: block;")
    table.insert(css, "    }")
    table.insert(css, "    ")
    table.insert(css, "    .navbar-end {")
    table.insert(css, "        margin-top: 1rem;")
    table.insert(css, "    }")
    table.insert(css, "}")
    table.insert(css, "")
    
    table.insert(css, "@media screen and (max-width: 768px) {")
    table.insert(css, "    .title.is-1.is-size-2-mobile {")
    table.insert(css, "        font-size: 2rem;")
    table.insert(css, "    }")
    table.insert(css, "    ")
    table.insert(css, "    .columns.is-multiline {")
    table.insert(css, "        display: flex;")
    table.insert(css, "        flex-wrap: wrap;")
    table.insert(css, "    }")
    table.insert(css, "    ")
    table.insert(css, "    .column.is-one-half, ")
    table.insert(css, "    .column.is-one-third {")
    table.insert(css, "        width: 100%;")
    table.insert(css, "    }")
    table.insert(css, "    ")
    table.insert(css, "    .raku.links-block .columns {")
    table.insert(css, "        flex-direction: column;")
    table.insert(css, "    }")
    table.insert(css, "    ")
    table.insert(css, "    .column.is-one-third, ")
    table.insert(css, "    .column.is-two-thirds {")
    table.insert(css, "        width: 100%;")
    table.insert(css, "    }")
    table.insert(css, "}")

    return table.concat(css, "\n")
end

-- Main execution
local output_file = arg[1] or "index_f17dea.css"
local css_content = generate_css()

local file = io.open(output_file, "w")
if file then
    file:write(css_content)
    file:close()
    print("CSS file generated: " .. output_file)
else
    print("Error: Could not write to file " .. output_file)
    os.exit(1)
end
