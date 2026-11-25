#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "c531f0bed184d6710b5d4997c4cd80c44d3ce8e757bde845dea02f3a24ed0c60", "source_sha256": "76a9327ec4d8b7b9abcabfcbbbf89350cb4a3a4fdc0c949a0b343fe059dc87a8", "target_language": "lua"}
-- abstractions-manager.sh — portiert nach lua
-- Quelle: shell, OpenClaw@gateway2:scripts/abstractions-manager.sh
-- Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

-- Execute the abstractions manager cron script with passed arguments
local script = "/home/openclaw/.openclaw/scripts/abstractions-manager-cron.sh"
local args = {...}

-- Build command with arguments
local cmd = {script}
for _, arg in ipairs(args) do
    table.insert(cmd, arg)
end

-- Execute the command
local success, exit_code, exit_signal = os.execute(table.concat(cmd, " "))

-- Handle exit codes similar to bash behavior
if type(success) == "number" then
    -- Lua 5.2+ returns exit code directly
    os.exit(success)
else
    -- Lua 5.1 returns boolean
    if success then
        os.exit(0)
    else
        os.exit(1)
    end
end
