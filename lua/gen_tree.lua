#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "9fa4a96d71cfd3fdf8bddaa1198b853227479303d2ebedbd03d8b4eb238a989a", "source_sha256": "0a55a33f11db266892b50c887fd8d01783f387e3072c8c5b9ed86ca6788a8c52", "target_language": "lua"}
-- gen_tree.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway2:scripts/gen_tree.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[Replicates `tree -a -L 6` output for /workspace into important/openclaw-tree.txt
(used because the `tree` binary is unavailable in this sandbox).]]
local ROOT = "/workspace"
local OUT = "/workspace/important/openclaw-tree.txt"
local MAX_DEPTH = 6

function collect(path, prefix, depth)
    local lines = {}
    prefix = prefix or ""
    depth = depth or 1
    local entries = {}
    local handle = io.popen("ls -1 \"" .. path .. "\" 2>/dev/null")
    if not handle then return lines end
    for line in handle:lines() do
        table.insert(entries, line)
    end
    handle:close()
    table.sort(entries)
    local total = #entries
    for i, name in ipairs(entries) do
        local is_last = (i == total)
        local connector = is_last and "└── " or "├── "
        table.insert(lines, prefix .. connector .. name)
        local full = path .. "/" .. name
        local stat_handle = io.popen("stat -c %F \"" .. full .. "\" 2>/dev/null")
        local file_type = stat_handle:read("*l")
        stat_handle:close()
        if depth < MAX_DEPTH and file_type == "directory" then
            local link_check = io.popen("stat -c %N \"" .. full .. "\" 2>/dev/null")
            local link_info = link_check:read("*l")
            link_check:close()
            local is_link = link_info and string.find(link_info, "->") ~= nil
            if not is_link then
                local next_prefix = prefix .. (is_last and "    " or "│   ")
                local sub_lines = collect(full, next_prefix, depth + 1)
                for _, line in ipairs(sub_lines) do
                    table.insert(lines, line)
                end
            end
        end
    end
    return lines
end

local body = collect(ROOT)
local timestamp = os.date("%Y-%m-%dT%H:%M:%S")
local header = (
    "# OpenClaw Workspace Tree\n" ..
    "# Generiert: " .. timestamp .. "\n" ..
    "# Befehl: tree -a -L 6 " .. ROOT .. " (emuliert via gen_tree.lua)\n" ..
    "# Diese Datei wird automatisch von db-maintainer aktualisiert\n\n"
)
local content = header .. ".\n" .. table.concat(body, "\n") .. "\n"

local f = io.open(OUT, "w")
f:write(content)
f:close()

print(string.format("written %s: %d lines, %d bytes", OUT, #body+1, #content))
