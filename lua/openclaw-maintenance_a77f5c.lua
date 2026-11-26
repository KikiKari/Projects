#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "2bfdb5ce285dd0fd035e97e489a81bacaeebb579571469d8f9d91f1a2c6bc816", "source_sha256": "a77f5c2629fe7fafac268cfbf2f0b3e77a194322aee8f9c06967eb6c33db043e", "target_language": "lua"}
-- openclaw-maintenance.sh — portiert nach lua
-- Quelle: shell, OpenClaw@gateway2:scripts/openclaw-maintenance.sh
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local OPENCLAW_BIN = os.getenv("OPENCLAW_BIN") or (os.getenv("HOME") .. "/.local/bin/openclaw")

-- Prüfe, ob die OpenClaw-Binärdatei existiert und ausführbar ist
local function is_executable(path)
  local handle = io.popen("test -x " .. path .. " && echo 1 || echo 0")
  local result = handle:read("*a"):gsub("%s+", "")
  handle:close()
  return result == "1"
end

if not is_executable(OPENCLAW_BIN) then
  io.stderr:write("ERROR: OpenClaw binary not found: " .. OPENCLAW_BIN .. "\n")
  os.exit(1)
end

-- Hilfsfunktion zum Ausführen von Befehlen
local function run_command(cmd)
  local success, _, code = os.execute(cmd)
  if not success and code ~= 0 then
    error("Command failed: " .. cmd)
  end
end

-- Version anzeigen
local version_handle = io.popen(OPENCLAW_BIN .. " --version")
local version_output = version_handle:read("*a"):gsub("^%s*(.-)%s*$", "%1")
version_handle:close()
print("Using OpenClaw: " .. version_output)

-- === 1. Service-/Config-Drift ===
run_command(OPENCLAW_BIN .. " doctor")

-- === 2. Plugin-Stage (Registry refresh only; updates are explicit/manual) ===
run_command(OPENCLAW_BIN .. " plugins registry --refresh")

if os.getenv("RUN_PLUGIN_UPDATE") == "1" then
  run_command(OPENCLAW_BIN .. " plugins update --all")
else
  print("Skipping plugin update. Run with RUN_PLUGIN_UPDATE=1 to enable.")
end

-- === 3. Tasks ===
run_command(OPENCLAW_BIN .. " tasks maintenance --apply")

-- === 4. Sessions – alle Agents auf einmal ===
run_command(OPENCLAW_BIN .. " sessions cleanup --enforce --all-agents")

-- === 5. Memory – status/index decken alle Agents ab ===
run_command(OPENCLAW_BIN .. " memory status --deep --fix")
run_command(OPENCLAW_BIN .. " memory index --force")

-- === 6. Memory promote – MUSS pro Agent ===
local agents = {"main", "knecht", "docs", "ops-hub", "cron"}
for _, agent in ipairs(agents) do
  run_command(OPENCLAW_BIN .. " memory promote --apply --agent " .. agent)
end

-- === 7. Secrets ===
run_command(OPENCLAW_BIN .. " secrets reload")
