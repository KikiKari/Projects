#!/usr/bin/env tclsh
# abstraction-provenance: {"artifact_sha256": "969b9ab6ead0616b0e51e99c54988ecbc0299f8b5e0ae583afbb51f8d324d567", "source_sha256": "c1bffd970108bca04ccb5b3a9aee8861acc4c11c8c4c461ea0c573b20c5e2f21", "target_language": "tcl"}
# index_4051ed.css — portiert nach tcl
# Quelle: css, Projects@abstractions:css/index_4051ed.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# Abstraction-provenance: {"artifact_sha256": "c0c2aa7750474bc55c705ff744495daa7aef344568dc1eadca3165b431837a79", "source_sha256": "4051edeb8cf3a53e4fdc417f40a86a4e9f16f24bcbc4b7334babe6d8f7500c24", "target_language": "tcl"}
# index.html — portiert nach css
# Quelle: html, Projects@Telegram-Monitor:web/index.html
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

proc write_css {filename} {
    set fd [open $filename w]
    
    puts $fd ":root\{"
    puts $fd "  --bg:#f6f7f9; --card:#fff; --line:#e3e6ea; --text:#16191d; --muted:#6b7280;"
    puts $fd "  --accent:#2481cc; --accent-soft:#e8f2fb; --discord:#5865f2; --discord-soft:#eceefe;"
    puts $fd "  --ok:#15803d; --warn:#b45309; --err:#b91c1c;"
    puts $fd "  color-scheme: light;"
    puts $fd "\}"
    
    puts $fd "*\{box-sizing:border-box\}"
    
    puts $fd "body\{margin:0;background:var(--bg);color:var(--text);"
    puts $fd "     font:15px/1.5 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif\}"
    
    puts $fd "header\{background:var(--card);border-bottom:1px solid var(--line);padding:14px 20px;"
    puts $fd "       display:flex;align-items:center;gap:14px;flex-wrap:wrap;position:sticky;top:0;z-index:5\}"
    
    puts $fd "header h1\{font-size:17px;margin:0;font-weight:650\}"
    
    puts $fd ".pill\{font-size:11px;padding:2px 8px;border-radius:99px;background:var(--accent-soft);"
    puts $fd "      color:var(--accent);font-weight:600;white-space:nowrap\}"
    
    puts $fd ".pill.off\{background:#f1f2f4;color:var(--muted)\}"
    
    puts $fd ".pill.dc\{background:var(--discord-soft);color:var(--discord)\}"
    
    puts $fd "nav\{display:flex;gap:4px;padding:0 20px;background:var(--card);border-bottom:1px solid var(--line)\}"
    
    puts $fd "nav button\{border:0;background:none;padding:11px 14px;font:inherit;font-weight:500;"
    puts $fd "           color:var(--muted);cursor:pointer;border-bottom:2px solid transparent\}"
    
    puts $fd "nav button.active\{color:var(--accent);border-bottom-color:var(--accent)\}"
    
    puts $fd "main\{padding:20px;max-width:1080px;margin:0 auto\}"
    
    puts $fd ".panel\{display:none\} .panel.active\{display:block\}"
    
    puts $fd ".row\{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:14px\}"
    
    puts $fd "input,select\{padding:9px 11px;border:1px solid var(--line);border-radius:8px;font:inherit;"
    puts $fd "             background:var(--card);min-width:180px\}"
    
    puts $fd "input:focus,select:focus\{outline:2px solid var(--accent-soft);border-color:var(--accent)\}"
    
    puts $fd "button.go\{background:var(--accent);color:#fff;border:0;border-radius:8px;padding:9px 16px;"
    puts $fd "          font:inherit;font-weight:600;cursor:pointer\}"
    
    puts $fd "button.go.sec\{background:var(--card);color:var(--text);border:1px solid var(--line)\}"
    
    puts $fd "button.go.dc\{background:var(--discord)\}"
    
    puts $fd "button.go:disabled\{opacity:.5;cursor:default\}"
    
    puts $fd ".card\{background:var(--card);border:1px solid var(--line);border-radius:12px;"
    puts $fd "      padding:14px 16px;margin-bottom:10px\}"
    
    puts $fd ".card h3\{margin:0 0 2px;font-size:15px;display:flex;align-items:center;gap:8px;flex-wrap:wrap\}"
    
    puts $fd ".card .meta\{color:var(--muted);font-size:13px\}"
    
    puts $fd ".card .desc\{margin-top:7px;font-size:13.5px;white-space:pre-wrap\}"
    
    puts $fd ".avatar\{width:34px;height:34px;border-radius:50%;object-fit:cover;background:#eceff3;flex:none\}"
    
    puts $fd ".head\{display:flex;gap:11px;align-items:flex-start\}"
    
    puts $fd ".score\{font-variant-numeric:tabular-nums;font-size:12px;color:var(--muted);"
    puts $fd "       border:1px solid var(--line);border-radius:6px;padding:1px 6px\}"
    
    puts $fd ".tag\{font-size:11px;padding:2px 7px;border-radius:5px;background:#f1f2f4;color:var(--muted);font-weight:600\}"
    
    puts $fd ".tag.ok\{background:#e7f6ec;color:var(--ok)\} .tag.no\{background:#fdeceb;color:var(--err)\}"
    
    puts $fd ".post\{border-left:3px solid var(--accent-soft);padding:6px 0 6px 11px;margin:9px 0;font-size:13.5px\}"
    
    puts $fd ".post .when\{color:var(--muted);font-size:12px\}"
    
    puts $fd ".post .txt\{white-space:pre-wrap;margin-top:2px\}"
    
    puts $fd "a\{color:var(--accent);text-decoration:none\} a:hover\{text-decoration:underline\}"
    
    puts $fd ".empty\{color:var(--muted);padding:22px;text-align:center;border:1px dashed var(--line);border-radius:12px\}"
    
    puts $fd ".err\{background:#fdeceb;border:1px solid #f5c6c2;color:var(--err);padding:10px 13px;"
    puts $fd "     border-radius:8px;margin-bottom:12px;font-size:13.5px\}"
    
    puts $fd ".spin\{color:var(--muted);padding:16px 0\}"
    
    puts $fd "table\{width:100%;border-collapse:collapse;font-size:13.5px\}"
    
    puts $fd "th,td\{text-align:left;padding:8px 10px;border-bottom:1px solid var(--line);vertical-align:top\}"
    
    puts $fd "th\{color:var(--muted);font-weight:600;font-size:12px;text-transform:uppercase;letter-spacing:.03em\}"
    
    puts $fd "code\{background:#f1f2f4;padding:1px 5px;border-radius:4px;font-size:12.5px\}"
    
    puts $fd ".hint\{color:var(--muted);font-size:13px;margin:-4px 0 14px\}"
    
    puts $fd ".stream\{max-height:460px;overflow:auto;border:1px solid var(--line);border-radius:10px;"
    puts $fd "        padding:6px 12px;margin-top:10px;background:var(--card)\}"
    
    puts $fd ".post.fresh\{border-left-color:var(--ok);background:#f3fbf5\}"
    
    puts $fd ".post.fresh .when::after\{content:\" NEU\";color:var(--ok);font-weight:700\}"
    
    puts $fd ".dot\{width:8px;height:8px;border-radius:50%;background:var(--ok);display:inline-block;"
    puts $fd "     margin-right:6px;animation:pulse 2s infinite\}"
    
    puts $fd "@keyframes pulse\{0%,100%\{opacity:1\}50%\{opacity:.35\}\}"
    
    puts $fd ".idle\{background:var(--muted)!important;animation:none\}"
    
    puts $fd ".tt-live\{background:#fe2c55;color:#fff;font-weight:700;font-size:11px;"
    puts $fd "         padding:2px 9px;border-radius:99px\}"
    
    puts $fd ".tt-off\{background:#f1f2f4;color:var(--muted);font-weight:700;font-size:11px;"
    puts $fd "        padding:2px 9px;border-radius:99px\}"
    
    puts $fd ".tt-player\{position:relative;width:100%;max-width:340px;aspect-ratio:9/16;background:#000;"
    puts $fd "           border-radius:10px;overflow:hidden;margin-top:10px;border:1px solid var(--line)\}"
    
    puts $fd ".tt-player iframe\{position:absolute;inset:0;width:100%;height:100%;border:0\}"
    
    puts $fd ".ev\{display:flex;gap:10px;padding:7px 0;border-bottom:1px solid var(--line);font-size:13.5px\}"
    
    puts $fd ".ev:last-child\{border-bottom:0\}"
    
    puts $fd ".ev .k\{font-weight:650;white-space:nowrap\}"
    
    puts $fd ".ev .k.start\{color:#fe2c55\} .ev .k.end\{color:var(--muted)\}"
    
    close $fd
}

# Hauptprogramm
if {$argc != 1} {
    puts stderr "Verwendung: [info script] <ausgabedatei>"
    exit 1
}

set output_file [lindex $argv 0]
write_css $output_file
