#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "53d94c1c7041be1b7e836c8aaafda01d047f1018aa5039b1ed8853c26be1726e", "source_sha256": "8c27d4100abf548d397238253c635c8516dc1bf3a1f72639a0d8228e949fcbbd", "target_language": "lua"}
-- style.css — portiert nach lua
-- Quelle: css, Projects@Vision-Check:Vision-Check/app/css/style.css
-- Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

--[[
═══════════════════════════════════════════════════════════
Vision-Check — Design System
Dark-Tech Theme | Analyse-Board Layout
═══════════════════════════════════════════════════════════
]]

local function generate_css()
    local css = {}

    -- Helper functions
    local function append(str)
        table.insert(css, str)
    end

    local function rule(selector, properties)
        append(selector .. " {")
        for key, value in pairs(properties) do
            append("  " .. key .. ": " .. value .. ";")
        end
        append("}")
    end

    local function comment(text)
        append("/* " .. text .. " */")
    end

    -- Root variables
    comment("═══════════════════════════════════════════════════════════\n   Vision-Check — Design System\n   Dark-Tech Theme | Analyse-Board Layout\n═══════════════════════════════════════════════════════════")

    append(":root {")
    append("  /* Farben */")
    append("  --bg-deep:      #0a0f1e;")
    append("  --bg-surface:   #111827;")
    append("  --bg-card:      #1a2235;")
    append("  --bg-hover:     #1f2d45;")
    append("  --border:       rgba(99, 179, 237, 0.15);")
    append("  --border-glow:  rgba(99, 179, 237, 0.4);")
    append("")
    append("  --accent:       #63b3ed;")
    append("  --accent-2:     #4fd1c5;")
    append("  --accent-warn:  #fbd38d;")
    append("  --accent-ok:    #68d391;")
    append("  --accent-err:   #fc8181;")
    append("")
    append("  --text-primary: #e2e8f0;")
    append("  --text-muted:   #718096;")
    append("  --text-dim:     #4a5568;")
    append("")
    append("  /* Schicht-Farben */")
    append("  --layer-0: #805ad5; /* iNaturalist */")
    append("  --layer-1: #4fd1c5; /* TensorFlow lokal */")
    append("  --layer-2: #fbd38d; /* Canvas Filter */")
    append("  --layer-3-gpt:    #68d391;")
    append("  --layer-3-gemini: #63b3ed;")
    append("  --layer-3-claude: #fc8181;")
    append("")
    append("  /* Spacing */")
    append("  --radius:  8px;")
    append("  --radius-l: 14px;")
    append("  --gap:     12px;")
    append("}")

    -- Reset & Basis
    comment("── Reset & Basis ──")
    rule("*", {
        ["box-sizing"] = "border-box",
        ["margin"] = "0",
        ["padding"] = "0"
    })
    
    rule("html, body", {
        ["height"] = "100%",
        ["background"] = "var(--bg-deep)",
        ["color"] = "var(--text-primary)",
        ["font-family"] = "'Inter', system-ui, -apple-system, sans-serif",
        ["font-size"] = "14px",
        ["line-height"] = "1.5",
        ["overflow"] = "hidden"
    })

    -- Header
    comment("── Header ──")
    rule("#app-header", {
        ["display"] = "flex",
        ["align-items"] = "center",
        ["justify-content"] = "space-between",
        ["padding"] = "10px 16px",
        ["background"] = "var(--bg-surface)",
        ["border-bottom"] = "1px solid var(--border)",
        ["height"] = "52px",
        ["flex-shrink"] = "0",
        ["z-index"] = "100"
    })

    rule(".header-brand", {
        ["display"] = "flex",
        ["align-items"] = "center",
        ["gap"] = "8px"
    })

    rule(".header-brand svg", {
        ["width"] = "28px",
        ["height"] = "28px",
        ["color"] = "var(--accent)"
    })

    rule(".header-brand h1", {
        ["font-size"] = "16px",
        ["font-weight"] = "700",
        ["background"] = "linear-gradient(90deg, var(--accent), var(--accent-2))",
        ["-webkit-background-clip"] = "text",
        ["-webkit-text-fill-color"] = "transparent",
        ["background-clip"] = "text"
    })

    rule(".header-controls", {
        ["display"] = "flex",
        ["align-items"] = "center",
        ["gap"] = "8px"
    })

    -- App Layout
    comment("── App Layout (Board) ──")
    rule("#app", {
        ["display"] = "flex",
        ["flex-direction"] = "column",
        ["height"] = "100vh"
    })

    rule("#board", {
        ["display"] = "grid",
        ["grid-template-columns"] = "1fr 320px",
        ["grid-template-rows"] = "1fr auto",
        ["gap"] = "var(--gap)",
        ["padding"] = "var(--gap)",
        ["flex"] = "1",
        ["overflow"] = "hidden"
    })

    -- Camera Panel
    comment("── Kamera-Panel (links, groß) ──")
    rule("#camera-panel", {
        ["grid-column"] = "1",
        ["grid-row"] = "1",
        ["background"] = "var(--bg-card)",
        ["border"] = "1px solid var(--border)",
        ["border-radius"] = "var(--radius-l)",
        ["display"] = "flex",
        ["flex-direction"] = "column",
        ["overflow"] = "hidden",
        ["position"] = "relative"
    })

    rule(".panel-header", {
        ["display"] = "flex",
        ["align-items"] = "center",
        ["justify-content"] = "space-between",
        ["padding"] = "10px 14px",
        ["border-bottom"] = "1px solid var(--border)",
        ["background"] = "var(--bg-surface)",
        ["flex-shrink"] = "0"
    })

    rule(".panel-title", {
        ["font-size"] = "12px",
        ["font-weight"] = "600",
        ["text-transform"] = "uppercase",
        ["letter-spacing"] = "0.08em",
        ["color"] = "var(--text-muted)"
    })

    rule(".badge", {
        ["display"] = "inline-flex",
        ["align-items"] = "center",
        ["gap"] = "4px",
        ["padding"] = "2px 8px",
        ["border-radius"] = "20px",
        ["font-size"] = "10px",
        ["font-weight"] = "600",
        ["text-transform"] = "uppercase"
    })

    rule(".badge-live", {
        ["background"] = "rgba(104, 211, 145, 0.15)",
        ["color"] = "var(--accent-ok)"
    })

    rule(".badge-idle", {
        ["background"] = "rgba(113, 128, 150, 0.15)",
        ["color"] = "var(--text-muted)"
    })

    rule(".badge-loading", {
        ["background"] = "rgba(251, 211, 141, 0.15)",
        ["color"] = "var(--accent-warn)"
    })

    -- Camera Viewport
    rule("#camera-viewport", {
        ["flex"] = "1",
        ["display"] = "flex",
        ["align-items"] = "center",
        ["justify-content"] = "center",
        ["position"] = "relative",
        ["background"] = "#000",
        ["overflow"] = "hidden"
    })

    rule("#video", {
        ["width"] = "100%",
        ["height"] = "100%",
        ["object-fit"] = "contain",
        ["display"] = "block"
    })

    rule("#canvas-overlay", {
        ["position"] = "absolute",
        ["top"] = "0",
        ["left"] = "0",
        ["width"] = "100%",
        ["height"] = "100%",
        ["pointer-events"] = "none"
    })

    rule("#snap-canvas", {
        ["display"] = "none"
    })

    -- Zoom Loupe
    rule("#pixel-loupe", {
        ["position"] = "absolute",
        ["bottom"] = "16px",
        ["right"] = "16px",
        ["width"] = "160px",
        ["height"] = "160px",
        ["border"] = "2px solid var(--accent)",
        ["border-radius"] = "var(--radius)",
        ["overflow"] = "hidden",
        ["background"] = "#000",
        ["display"] = "none",
        ["box-shadow"] = "0 0 20px rgba(99, 179, 237, 0.3)"
    })

    rule("#loupe-canvas", {
        ["width"] = "100%",
        ["height"] = "100%"
    })

    rule("#loupe-info", {
        ["position"] = "absolute",
        ["bottom"] = "0",
        ["left"] = "0",
        ["right"] = "0",
        ["background"] = "rgba(0,0,0,0.8)",
        ["padding"] = "4px 6px",
        ["font-size"] = "10px",
        ["font-family"] = "'JetBrains Mono', monospace",
        ["color"] = "var(--accent)",
        ["text-align"] = "center"
    })

    -- Camera Controls
    rule("#camera-controls", {
        ["padding"] = "10px 14px",
        ["border-top"] = "1px solid var(--border)",
        ["display"] = "flex",
        ["align-items"] = "center",
        ["gap"] = "8px",
        ["flex-wrap"] = "wrap",
        ["background"] = "var(--bg-surface)",
        ["flex-shrink"] = "0"
    })

    -- Right Panel
    comment("── Rechtes Panel ──")
    rule("#right-panel", {
        ["grid-column"] = "2",
        ["grid-row"] = "1 / 3",
        ["display"] = "flex",
        ["flex-direction"] = "column",
        ["gap"] = "var(--gap)",
        ["overflow-y"] = "auto",
        ["padding-right"] = "2px"
    })

    rule("#right-panel::-webkit-scrollbar", {
        ["width"] = "4px"
    })

    rule("#right-panel::-webkit-scrollbar-track", {
        ["background"] = "transparent"
    })

    rule("#right-panel::-webkit-scrollbar-thumb", {
        ["background"] = "var(--border)",
        ["border-radius"] = "2px"
    })

    -- Cards
    comment("── Cards ──")
    rule(".card", {
        ["background"] = "var(--bg-card)",
        ["border"] = "1px solid var(--border)",
        ["border-radius"] = "var(--radius-l)",
        ["overflow"] = "hidden"
    })

    rule(".card-body", {
        ["padding"] = "12px 14px"
    })

    -- Filter Panel
    comment("── Filter-Panel ──")
    rule(".slider-row", {
        ["display"] = "flex",
        ["align-items"] = "center",
        ["gap"] = "8px",
        ["margin-bottom"] = "10px"
    })

    rule(".slider-row:last-child", {
        ["margin-bottom"] = "0"
    })

    rule(".slider-label", {
        ["width"] = "90px",
        ["font-size"] = "11px",
        ["color"] = "var(--text-muted)",
        ["flex-shrink"] = "0"
    })

    rule(".slider-row input[type=\"range\"]", {
        ["flex"] = "1",
        ["-webkit-appearance"] = "none",
        ["height"] = "4px",
        ["border-radius"] = "2px",
        ["background"] = "var(--bg-deep)",
        ["outline"] = "none",
        ["cursor"] = "pointer"
    })

    rule(".slider-row input[type=\"range\"]::-webkit-slider-thumb", {
        ["-webkit-appearance"] = "none",
        ["width"] = "14px",
        ["height"] = "14px",
        ["border-radius"] = "50%",
        ["background"] = "var(--accent)",
        ["border"] = "2px solid var(--bg-card)",
        ["cursor"] = "pointer",
        ["transition"] = "transform 0.15s"
    })

    rule(".slider-row input[type=\"range\"]::-webkit-slider-thumb:hover", {
        ["transform"] = "scale(1.2)"
    })

    rule(".slider-value", {
        ["width"] = "32px",
        ["font-size"] = "11px",
        ["color"] = "var(--accent)",
        ["font-family"] = "monospace",
        ["text-align"] = "right",
        ["flex-shrink"] = "0"
    })

    -- Analysis Results
    comment("── Analyse-Results ──")
    rule(".result-block", {
        ["margin-bottom"] = "12px",
        ["padding"] = "10px",
        ["background"] = "var(--bg-surface)",
        ["border"] = "1px solid var(--border)",
        ["border-radius"] = "var(--radius)"
    })

    rule(".result-block:last-child", {
        ["margin-bottom"] = "0"
    })

    rule(".result-header", {
        ["display"] = "flex",
        ["align-items"] = "center",
        ["justify-content"] = "space-between",
        ["margin-bottom"] = "6px"
    })

    rule(".layer-tag", {
        ["display"] = "inline-flex",
        ["align-items"] = "center",
        ["gap"] = "5px",
        ["font-size"] = "10px",
        ["font-weight"] = "700",
        ["text-transform"] = "uppercase",
        ["letter-spacing"] = "0.06em"
    })

    rule(".result-text", {
        ["font-size"] = "12px",
        ["color"] = "var(--text-primary)",
        ["line-height"] = "1.6",
        ["white-space"] = "pre-wrap"
    })

    rule(".detection-item", {
        ["display"] = "flex",
        ["align-items"] = "center",
        ["justify-content"] = "space-between",
        ["padding"] = "4px 0",
        ["border-bottom"] = "1px solid var(--border)",
        ["font-size"] = "12px"
    })

    rule(".detection-item:last-child", {
        ["border-bottom"] = "none"
    })

    rule(".detection-class", {
        ["font-weight"] = "600",
        ["color"] = "var(--layer-1)"
    })

    rule(".confidence-bar", {
        ["display"] = "flex",
        ["align-items"] = "center",
        ["gap"] = "6px"
    })

    rule(".confidence-track", {
        ["width"] = "60px",
        ["height"] = "4px",
        ["background"] = "var(--bg-deep)",
        ["border-radius"] = "2px",
        ["overflow"] = "hidden"
    })

    rule(".confidence-fill", {
        ["height"] = "100%",
        ["background"] = "var(--accent-ok)",
        ["border-radius"] = "2px",
        ["transition"] = "width 0.3s"
    })

    rule(".confidence-pct", {
        ["font-size"] = "10px",
        ["color"] = "var(--text-muted)",
        ["width"] = "32px",
        ["text-align"] = "right"
    })

    -- Pixel Inspector
    comment("── Pixel-Inspector ──")
    rule("#pixel-info", {
        ["display"] = "flex",
        ["gap"] = "8px",
        ["align-items"] = "center"
    })

    rule(".pixel-swatch", {
        ["width"] = "36px",
        ["height"] = "36px",
        ["border-radius"] = "var(--radius)",
        ["border"] = "2px solid var(--border)",
        ["flex-shrink"] = "0"
    })

    rule(".pixel-values", {
        ["display"] = "flex",
        ["flex-direction"] = "column",
        ["gap"] = "2px"
    })

    rule(".pixel-values span", {
        ["font-size"] = "11px",
        ["font-family"] = "'JetBrains Mono', monospace",
        ["color"] = "var(--text-primary)"
    })

    -- Buttons
    comment("── Buttons ──")
    rule(".btn", {
        ["display"] = "inline-flex",
        ["align-items"] = "center",
        ["gap"] = "6px",
        ["padding"] = "7px 14px",
        ["border"] = "1px solid var(--border)",
        ["border-radius"] = "var(--radius)",
        ["background"] = "var(--bg-surface)",
        ["color"] = "var(--text-primary)",
        ["font-size"] = "12px",
        ["font-weight"] = "500",
        ["cursor"] = "pointer",
        ["transition"] = "all 0.2s",
        ["white-space"] = "nowrap"
    })

    rule(".btn:hover", {
        ["background"] = "var(--bg-hover)",
        ["border-color"] = "var(--border-glow)"
    })

    rule(".btn:disabled", {
        ["opacity"] = "0.4",
        ["cursor"] = "not-allowed"
    })

    rule(".btn-primary", {
        ["background"] = "rgba(99, 179, 237, 0.15)",
        ["border-color"] = "var(--accent)",
        ["color"] = "var(--accent)"
    })

    rule(".btn-primary:hover", {
        ["background"] = "rgba(99, 179, 237, 0.25)"
    })

    rule(".btn-snap", {
        ["background"] = "rgba(104, 211, 145, 0.15)",
        ["border-color"] = "var(--accent-ok)",
        ["color"] = "var(--accent-ok)",
        ["padding"] = "9px 20px",
        ["font-size"] = "13px",
        ["font-weight"] = "600"
    })

    rule(".btn-snap:hover", {
        ["background"] = "rgba(104, 211, 145, 0.25)"
    })

    rule(".btn-danger", {
        ["background"] = "rgba(252, 129, 129, 0.1)",
        ["border-color"] = "var(--accent-err)",
        ["color"] = "var(--accent-err)"
    })

    rule(".btn-sm", {
        ["padding"] = "4px 10px",
        ["font-size"] = "11px"
    })

    rule(".btn-icon", {
        ["padding"] = "7px",
        ["border-radius"] = "var(--radius)"
    })

    -- Select
    comment("── Select ──")
    rule("select", {
        ["background"] = "var(--bg-surface)",
        ["border"] = "1px solid var(--border)",
        ["color"] = "var(--text-primary)",
        ["border-radius"] = "var(--radius)",
        ["padding"] = "6px 10px",
        ["font-size"] = "12px",
        ["cursor"] = "pointer",
        ["outline"] = "none",
        ["transition"] = "border-color 0.2s"
    })

    rule("select:hover, select:focus", {
        ["border-color"] = "var(--border-glow)"
    })

    -- Spinner
    comment("── Spinner ──")
    rule(".spinner", {
        ["width"] = "16px",
        ["height"] = "16px",
        ["border"] = "2px solid var(--border)",
        ["border-top-color"] = "var(--accent)",
        ["border-radius"] = "50%",
        ["animation"] = "spin 0.7s linear infinite",
        ["flex-shrink"] = "0"
    })

    append("@keyframes spin { to { transform: rotate(360deg); } }")

    -- Settings Modal
    comment("── Settings Modal ──")
    rule("#settings-modal", {
        ["display"] = "none",
        ["position"] = "fixed",
        ["inset"] = "0",
        ["background"] = "rgba(0,0,0,0.7)",
        ["z-index"] = "200",
        ["align-items"] = "center",
        ["justify-content"] = "center",
        ["backdrop-filter"] = "blur(4px)"
    })

    rule("#settings-modal.open", {
        ["display"] = "flex"
    })

    rule(".modal-box", {
        ["background"] = "var(--bg-card)",
        ["border"] = "1px solid var(--border-glow)",
        ["border-radius"] = "var(--radius-l)",
        ["padding"] = "24px",
        ["width"] = "480px",
        ["max-width"] = "calc(100vw - 32px)",
        ["max-height"] = "80vh",
        ["overflow-y"] = "auto"
    })

    rule(".modal-title", {
        ["font-size"] = "16px",
        ["font-weight"] = "700",
        ["color"] = "var(--accent)",
        ["margin-bottom"] = "20px"
    })

    rule(".settings-section", {
        ["margin-bottom"] = "20px"
    })

    rule(".settings-label", {
        ["display"] = "block",
        ["font-size"] = "11px",
        ["font-weight"] = "600",
        ["text-transform"] = "uppercase",
        ["letter-spacing"] = "0.08em",
        ["color"] = "var(--text-muted)",
        ["margin-bottom"] = "6px"
    })

    rule(".settings-input", {
        ["width"] = "100%",
        ["background"] = "var(--bg-deep)",
        ["border"] = "1px solid var(--border)",
        ["color"] = "var(--text-primary)",
        ["border-radius"] = "var(--radius)",
        ["padding"] = "8px 12px",
        ["font-size"] = "12px",
        ["font-family"] = "'JetBrains Mono', monospace",
        ["outline"] = "none",
        ["transition"] = "border-color 0.2s"
    })

    rule(".settings-input:focus", {
        ["border-color"] = "var(--accent)"
    })

    rule(".settings-hint", {
        ["font-size"] = "10px",
        ["color"] = "var(--text-dim)",
        ["margin-top"] = "4px"
    })

    rule(".settings-section-title", {
        ["font-size"] = "13px",
        ["font-weight"] = "600",
        ["color"] = "var(--text-primary)",
        ["margin-bottom"] = "12px",
        ["padding-bottom"] = "8px",
        ["border-bottom"] = "1px solid var(--border)"
    })

    -- Snapshot Preview
    comment("── Snapshot Preview ──")
    rule("#snapshot-area", {
        ["display"] = "none"
    })

    rule("#snapshot-preview", {
        ["width"] = "100%",
        ["border-radius"] = "var(--radius)",
        ["border"] = "1px solid var(--border)"
    })

    -- Status Bar
    comment("── Bottom-Statusleiste ──")
    rule("#status-bar", {
        ["grid-column"] = "1",
        ["grid-row"] = "2",
        ["background"] = "var(--bg-surface)",
        ["border"] = "1px solid var(--border)",
        ["border-radius"] = "var(--radius)",
        ["padding"] = "6px 12px",
        ["display"] = "flex",
        ["align-items"] = "center",
        ["gap"] = "12px",
        ["font-size"] = "11px",
        ["color"] = "var(--text-muted)",
        ["flex-shrink"] = "0"
    })

    rule(".status-dot", {
        ["width"] = "6px",
        ["height"] = "6px",
        ["border-radius"] = "50%",
        ["background"] = "var(--text-dim)",
        ["flex-shrink"] = "0"
    })

    rule(".status-dot.ok", {
        ["background"] = "var(--accent-ok)",
        ["box-shadow"] = "0 0 6px var(--accent-ok)"
    })

    rule(".status-dot.warn", {
        ["background"] = "var(--accent-warn)"
    })

    rule(".status-dot.err", {
        ["background"] = "var(--accent-err)"
    })

    rule("#status-text", {
        ["flex"] = "1"
    })

    -- Layer Indicator
    comment("── Layer-Indicator ──")
    rule(".layer-indicator", {
        ["display"] = "flex",
        ["gap"] = "4px",
        ["align-items"] = "center"
    })

    rule(".layer-dot", {
        ["width"] = "8px",
        ["height"] = "8px",
        ["border-radius"] = "50%",
        ["opacity"] = "0.3",
        ["transition"] = "opacity 0.3s, box-shadow 0.3s"
    })

    rule(".layer-dot.active", {
        ["opacity"] = "1",
        ["box-shadow"] = "0 0 6px currentColor"
    })

    -- Analysis Tabs
    comment("── Analyse-Tabs ──")
    rule(".tab-bar", {
        ["display"] = "flex",
        ["gap"] = "2px",
        ["padding"] = "8px 14px",
        ["border-bottom"] = "1px solid var(--border)",
        ["background"] = "var(--bg-surface)"
    })

    rule(".tab", {
        ["padding"] = "5px 12px",
        ["border-radius"] = "var(--radius)",
        ["font-size"] = "11px",
        ["font-weight"] = "600",
        ["cursor"] = "pointer",
        ["color"] = "var(--text-muted)",
        ["transition"] = "all 0.2s",
        ["border"] = "1px solid transparent",
        ["background"] = "transparent"
    })

    rule(".tab.active", {
        ["background"] = "var(--bg-hover)",
        ["border-color"] = "var(--border-glow)",
        ["color"] = "var(--accent)"
    })

    rule(".tab-content", {
        ["display"] = "none"
    })

    rule(".tab-content.active", {
        ["display"] = "block"
    })

    -- iNaturalist Card
    comment("── iNaturalist Karte ──")
    rule(".species-card", {
        ["display"] = "flex",
        ["gap"] = "10px",
        ["padding"] = "8px",
        ["background"] = "var(--bg-deep)",
        ["border-radius"] = "var(--radius)",
        ["margin-bottom"] = "8px",
        ["border"] = "1px solid var(--border)"
    })

    rule(".species-img", {
        ["width"] = "48px",
        ["height"] = "48px",
        ["border-radius"] = "var(--radius)",
        ["object-fit"] = "cover",
        ["flex-shrink"] = "0",
        ["background"] = "var(--bg-surface)"
    })

    rule(".species-info", {
        ["flex"] = "1",
        ["min-width"] = "0"
    })

    rule(".species-name", {
        ["font-size"] = "12px",
        ["font-weight"] = "600",
        ["color"] = "var(--layer-0)",
        ["white-space"] = "nowrap",
        ["overflow"] = "hidden",
        ["text-overflow"] = "ellipsis"
    })

    rule(".species-latin", {
        ["font-size"] = "10px",
        ["color"] = "var(--text-muted)",
        ["font-style"] = "italic"
    })

    rule(".species-score", {
        ["font-size"] = "10px",
        ["color"] = "var(--text-dim)",
        ["margin-top"] = "2px"
    })

    -- Responsive Mobile
    comment("── Responsive: Mobile ──")
    append("@media (max-width: 768px) {")
    rule("#board", {
        ["grid-template-columns"] = "1fr",
        ["grid-template-rows"] = "1fr auto auto",
        ["overflow-y"] = "auto"
    })

    rule("#camera-panel", {
        ["grid-column"] = "1",
        ["grid-row"] = "1",
        ["min-height"] = "55vw"
    })

    rule("#right-panel", {
        ["grid-column"] = "1",
        ["grid-row"] = "2",
        ["overflow-y"] = "visible",
        ["max-height"] = "none"
    })

    rule("#status-bar", {
        ["grid-column"] = "1",
        ["grid-row"] = "3"
    })

    rule("html, body", {
        ["overflow"] = "auto"
    })
    append("}")

    -- Animations
    comment("── Animationen ──")
    append("@keyframes pulse-glow {")
    append("  0%, 100% { box-shadow: 0 0 4px var(--accent); }")
    append("  50% { box-shadow: 0 0 16px var(--accent); }")
    append("}")

    rule(".glow-pulse", {
        ["animation"] = "pulse-glow 2s ease-in-out infinite"
    })

    rule(".fade-in", {
        ["animation"] = "fadeIn 0.3s ease"
    })

    append("@keyframes fadeIn {")
    append("  from { opacity: 0; transform: translateY(4px); }")
    append("  to { opacity: 1; transform: translateY(0); }")
    append("}")

    -- Upload Zone
    comment("── Upload-Zone ──")
    rule("#upload-zone", {
        ["border"] = "2px dashed var(--border)",
        ["border-radius"] = "var(--radius)",
        ["padding"] = "20px",
        ["text-align"] = "center",
        ["cursor"] = "pointer",
        ["transition"] = "all 0.2s",
        ["color"] = "var(--text-muted)",
        ["font-size"] = "12px"
    })

    rule("#upload-zone:hover, #upload-zone.drag-over", {
        ["border-color"] = "var(--accent)",
        ["background"] = "rgba(99, 179, 237, 0.05)",
        ["color"] = "var(--accent)"
    })

    -- Toggle Switch
    comment("── Toggle Switch ──")
    rule(".toggle-switch", {
        ["position"] = "relative",
        ["width"] = "36px",
        ["height"] = "20px",
        ["flex-shrink"] = "0"
    })

    rule(".toggle-switch input", {
        ["display"] = "none"
    })

    rule(".toggle-track", {
        ["position"] = "absolute",
        ["inset"] = "0",
        ["border-radius"] = "10px",
        ["background"] = "var(--bg-deep)",
        ["border"] = "1px solid var(--border)",
        ["cursor"] = "pointer",
        ["transition"] = "background 0.2s"
    })

    rule(".toggle-thumb", {
        ["position"] = "absolute",
        ["top"] = "3px",
        ["left"] = "3px",
        ["width"] = "12px",
        ["height"] = "12px",
        ["border-radius"] = "50%",
        ["background"] = "var(--text-dim)",
        ["transition"] = "transform 0.2s, background 0.2s"
    })

    rule(".toggle-switch input:checked + .toggle-track", {
        ["background"] = "rgba(99, 179, 237, 0.2)",
        ["border-color"] = "var(--accent)"
    })

    rule(".toggle-switch input:checked ~ .toggle-thumb,\n.toggle-switch input:checked + .toggle-track + .toggle-thumb", {
        ["background"] = "var(--accent)",
        ["transform"] = "translateX(16px)"
    })

    return table.concat(css, "\n")
end

-- Main execution
local output_file = arg[1] or "style.css"
local file = io.open(output_file, "w")
if file then
    file:write(generate_css())
    file:close()
    print("CSS file generated: " .. output_file)
else
    print("Error: Could not write to file " .. output_file)
    os.exit(1)
end
