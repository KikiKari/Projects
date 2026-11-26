#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "5e239002ca042adbf58aa778f3b75eb66a3f6f8381e85e3638120304e08de5cb", "source_sha256": "08fdd65a33a6ec90261b4ce48be82ca8338400da1b321dfc70a57bedabfa45aa", "target_language": "lua"}
-- App.css — portiert nach lua
-- Quelle: css, OpenClaw@main:src/App.css
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local function generate_css()
    local css = {}

    -- Root styles
    table.insert(css, ":root {")
    table.insert(css, "  color-scheme: dark;")
    table.insert(css, "  font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, \"Segoe UI\", sans-serif;")
    table.insert(css, "  background: #0b1020;")
    table.insert(css, "  color: #eef2ff;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Universal selector
    table.insert(css, "* {")
    table.insert(css, "  box-sizing: border-box;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Body styles
    table.insert(css, "body {")
    table.insert(css, "  margin: 0;")
    table.insert(css, "  min-width: 320px;")
    table.insert(css, "  min-height: 100vh;")
    table.insert(css, "  background:")
    table.insert(css, "    radial-gradient(circle at 20% 20%, rgba(56, 189, 248, 0.22), transparent 30rem),")
    table.insert(css, "    radial-gradient(circle at 80% 10%, rgba(168, 85, 247, 0.2), transparent 28rem),")
    table.insert(css, "    linear-gradient(135deg, #050816 0%, #111827 55%, #172033 100%);")
    table.insert(css, "}")
    table.insert(css, "")

    -- Page shell
    table.insert(css, ".page-shell {")
    table.insert(css, "  min-height: 100vh;")
    table.insert(css, "  display: grid;")
    table.insert(css, "  place-items: center;")
    table.insert(css, "  padding: 2rem;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Hero card
    table.insert(css, ".hero-card {")
    table.insert(css, "  width: min(100%, 56rem);")
    table.insert(css, "  padding: clamp(2rem, 6vw, 4.5rem);")
    table.insert(css, "  border: 1px solid rgba(148, 163, 184, 0.28);")
    table.insert(css, "  border-radius: 2rem;")
    table.insert(css, "  background: rgba(15, 23, 42, 0.72);")
    table.insert(css, "  box-shadow: 0 2rem 6rem rgba(0, 0, 0, 0.35);")
    table.insert(css, "  backdrop-filter: blur(18px);")
    table.insert(css, "}")
    table.insert(css, "")

    -- Eyebrow
    table.insert(css, ".eyebrow {")
    table.insert(css, "  margin: 0 0 1rem;")
    table.insert(css, "  color: #67e8f9;")
    table.insert(css, "  font-size: 0.8rem;")
    table.insert(css, "  font-weight: 700;")
    table.insert(css, "  letter-spacing: 0.18em;")
    table.insert(css, "  text-transform: uppercase;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Heading
    table.insert(css, "h1 {")
    table.insert(css, "  margin: 0;")
    table.insert(css, "  max-width: 12ch;")
    table.insert(css, "  font-size: clamp(2.75rem, 8vw, 6rem);")
    table.insert(css, "  line-height: 0.95;")
    table.insert(css, "  letter-spacing: -0.06em;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Lead paragraph
    table.insert(css, ".lead {")
    table.insert(css, "  margin: 1.5rem 0 0;")
    table.insert(css, "  max-width: 42rem;")
    table.insert(css, "  color: #cbd5e1;")
    table.insert(css, "  font-size: clamp(1.05rem, 2vw, 1.35rem);")
    table.insert(css, "  line-height: 1.65;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Link grid container
    table.insert(css, ".link-grid {")
    table.insert(css, "  display: grid;")
    table.insert(css, "  gap: 0.85rem;")
    table.insert(css, "  margin-top: 2rem;")
    table.insert(css, "}")
    table.insert(css, "")

    -- Link grid items
    table.insert(css, ".link-grid a {")
    table.insert(css, "  display: flex;")
    table.insert(css, "  align-items: center;")
    table.insert(css, "  justify-content: space-between;")
    table.insert(css, "  gap: 1rem;")
    table.insert(css, "  padding: 1rem 1.15rem;")
    table.insert(css, "  border: 1px solid rgba(148, 163, 184, 0.25);")
    table.insert(css, "  border-radius: 1rem;")
    table.insert(css, "  color: #f8fafc;")
    table.insert(css, "  text-decoration: none;")
    table.insert(css, "  background: rgba(255, 255, 255, 0.06);")
    table.insert(css, "}")
    table.insert(css, "")

    -- Link hover and focus states
    table.insert(css, ".link-grid a:hover,")
    table.insert(css, ".link-grid a:focus-visible {")
    table.insert(css, "  border-color: rgba(103, 232, 249, 0.75);")
    table.insert(css, "  outline: none;")
    table.insert(css, "  background: rgba(103, 232, 249, 0.12);")
    table.insert(css, "}")

    return table.concat(css, "\n")
end

local function write_css_to_file(filename)
    local file = io.open(filename, "w")
    if not file then
        error("Could not open file " .. filename .. " for writing")
    end
    file:write(generate_css())
    file:close()
end

-- Main execution
local output_file = arg[1] or "App.css"
write_css_to_file(output_file)
