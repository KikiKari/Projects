#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "f9ec368523d1da56092ea1c52565a3607fbf100fc8f297d4d8619ff8b73b6b25", "source_sha256": "47064dbc7b32c01d57d42222f8cc3ac7caf9c8d82b98029dc5fc6ecb0d32f2c9", "target_language": "lua"}
-- collect_ist_gateway_a.sh — portiert nach lua
-- Quelle: shell, OpenClaw@gateway1:scripts/collect_ist_gateway_a.sh
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local os = require("os")
local io = require("io")
local table = require("table")

-- Hilfsfunktionen
local function execute(cmd)
  local handle = io.popen(cmd .. " 2>/dev/null")
  if not handle then return "" end
  local result = handle:read("*a"):gsub("%s+$", "")
  handle:close()
  return result
end

local function file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  else
    return false
  end
end

local function dir_exists(path)
  local stat = execute("stat -c %F " .. path)
  return stat == "directory"
end

local function read_file(path)
  local file = io.open(path, "r")
  if file then
    local content = file:read("*a")
    file:close()
    return content or ""
  else
    return ""
  end
end

local function list_dir(path)
  local handle = io.popen("ls -1 " .. path .. " 2>/dev/null")
  if not handle then return "" end
  local result = handle:read("*a")
  handle:close()
  return result:gsub("%s+$", "")
end

local function list_dir_detailed(path)
  local handle = io.popen("ls -la " .. path .. " 2>/dev/null")
  if not handle then return "" end
  local result = handle:read("*a")
  handle:close()
  return result:gsub("%s+$", "")
end

-- Konfiguration
local BASE_DIR = os.getenv("HOME") .. "/.openclaw"
local OUT_DIR = BASE_DIR .. "/workspace/vscode"

-- Zeitstempel
local NOW_UTC = os.date("!%Y-%m-%dT%H:%M:%SZ")
local NOW_LOCAL = os.date("%Y-%m-%d %H:%M:%S %Z")
local TS = os.date("%Y%m%d-%H%M%S")

-- Erstelle Ausgabeverzeichnis
execute("mkdir -p " .. OUT_DIR)

-- Dateipfade
local IST_FILE = OUT_DIR .. "/IST-ZUSTAND_GATEWAY-A_NODE1.md"
local INV_FILE = OUT_DIR .. "/ARTEFAKT-INVENTAR_GATEWAY-A_NODE1.md"
local CFG_FILE = OUT_DIR .. "/OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-A_NODE1.md"
local ENV_FILE = OUT_DIR .. "/ENV-STATUS_GATEWAY-A_NODE1.md"
local RUN_FILE = OUT_DIR .. "/RUN-" .. TS .. ".md"

-- Konstante Pfade
local OPENCLAW_JSON = BASE_DIR .. "/openclaw.json"
local ENV_DOT = BASE_DIR .. "/.env"
local ENV_SYSTEMD = BASE_DIR .. "/gateway.systemd.env"
local VSCODE_DIR = BASE_DIR .. "/.vscode"

-- Systeminformationen sammeln
local HOSTNAME_FQDN = execute("hostname -f") ~= "" and execute("hostname -f") or execute("hostname")
local HOSTNAME_SHORT = execute("hostname")
local ARCH = execute("uname -m")
local KERNEL = execute("uname -r")
local OS_PRETTY = execute("grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '\"'")
local IPV4_ALL = execute("hostname -I")
local PUBLIC_IP = execute("curl -4 -s --max-time 4 ifconfig.me") ~= "" and execute("curl -4 -s --max-time 4 ifconfig.me") or "(nicht ermittelt)"
local TAILSCALE_IP = execute("tailscale ip -4") ~= "" and execute("tailscale ip -4"):match("[^\n]+") or "(nicht ermittelt)"
local OPENCLAW_VER = execute("openclaw --version") ~= "" and execute("openclaw --version") or "(nicht ermittelt)"
local NODE_VER = execute("node -v") ~= "" and execute("node -v") or "(nicht ermittelt)"

-- IST-Zustand erstellen
local ist_content = [[
# IST-Zustand: Gateway A / Node 1

Stand (lokal): ]] .. NOW_LOCAL .. [[  
Stand (UTC): ]] .. NOW_UTC .. [[

## 1) Identitaet & System

- Gateway: **A**
- Node: **1**
- Hostname (short): `]] .. HOSTNAME_SHORT .. [[`
- Hostname (FQDN): `]] .. HOSTNAME_FQDN .. [[`
- Architektur: `]] .. ARCH .. [[`
- Kernel: `]] .. KERNEL .. [[`
- OS: `]] .. OS_PRETTY .. [[`
- IPv4 (lokal): `]] .. IPV4_ALL .. [[`
- Public IPv4: `]] .. PUBLIC_IP .. [[`
- Tailscale IPv4: `]] .. TAILSCALE_IP .. [[`
- OpenClaw Version: `]] .. OPENCLAW_VER .. [[`
- Node.js Version: `]] .. NODE_VER .. [[`

## 2) Arbeitsverzeichnisse

- Basis: `]] .. BASE_DIR .. [[`
- Funktionell VSCode: `]] .. VSCODE_DIR .. [[`
- Workspace Doku: `]] .. OUT_DIR .. [[`

## 3) Kernartefakte (Existenz)

- `]] .. OPENCLAW_JSON .. [[`: ]] .. (file_exists(OPENCLAW_JSON) and "vorhanden" or "fehlt") .. [[
- `]] .. ENV_DOT .. [[`: ]] .. (file_exists(ENV_DOT) and "vorhanden" or "fehlt") .. [[
- `]] .. ENV_SYSTEMD .. [[`: ]] .. (file_exists(ENV_SYSTEMD) and "vorhanden" or "fehlt") .. [[
- `]] .. BASE_DIR .. [[/plugins/installs.json`: ]] .. (file_exists(BASE_DIR .. "/plugins/installs.json") and "vorhanden" or "fehlt") .. [[
- `]] .. BASE_DIR .. [[/plugin-skills`: ]] .. (dir_exists(BASE_DIR .. "/plugin-skills") and "vorhanden" or "fehlt") .. "\n"

local ist_file = io.open(IST_FILE, "w")
ist_file:write(ist_content)
ist_file:close()

-- Artefakt-Inventar erstellen
local inv_file = io.open(INV_FILE, "w")
inv_file:write("# Artefakt-Inventar: Gateway A / Node 1\n\n")
inv_file:write("Stand: " .. NOW_LOCAL .. "\n\n")
inv_file:write("## Top-Level in ~/.openclaw\n\n")
inv_file:write('```text\n')
inv_file:write(list_dir(BASE_DIR) .. "\n")
inv_file:write('```\n\n')
inv_file:write("## ~/.openclaw/.vscode\n\n")
inv_file:write('```text\n')
if dir_exists(VSCODE_DIR) then
  inv_file:write(list_dir_detailed(VSCODE_DIR) .. "\n")
else
  inv_file:write("(nicht vorhanden)\n")
end
inv_file:write('```\n\n')
inv_file:write("## plugin-skills/\n\n")
inv_file:write('```text\n')
if dir_exists(BASE_DIR .. "/plugin-skills") then
  inv_file:write(list_dir(BASE_DIR .. "/plugin-skills") .. "\n")
else
  inv_file:write("(nicht vorhanden)\n")
end
inv_file:write('```\n\n')
inv_file:write("## openclaw.json Backups\n\n")
inv_file:write('```text\n')
local backups = execute("ls -1 " .. BASE_DIR .. "/openclaw.json.bak* 2>/dev/null")
if backups ~= "" then
  inv_file:write(backups .. "\n")
else
  inv_file:write("(keine gefunden)\n")
end
inv_file:write('```\n')
inv_file:close()

-- Config Snapshot erstellen
local cfg_file = io.open(CFG_FILE, "w")
cfg_file:write("# OpenClaw Config Snapshot: Gateway A / Node 1\n\n")
cfg_file:write("Stand: " .. NOW_LOCAL .. "\n\n")
cfg_file:write("## Schluesselpositionen (grep)\n\n")
cfg_file:write('```text\n')
if file_exists(OPENCLAW_JSON) then
  cfg_file:write(execute("grep -nE '\"gateway\"|\\\"session\\\"|\\\"dmScope\\\"|\\\"auth\\\"|\\\"secrets\\\"|\\\"tools\\\"|\\\"plugins\\\"|\\\"profile\\\"|\\\"alsoAllow\\\"|\\\"denyCommands\\\"' " .. OPENCLAW_JSON) .. "\n")
else
  cfg_file:write("openclaw.json fehlt\n")
end
cfg_file:write('```\n\n')
cfg_file:write("## Ausschnitt gateway/session/auth\n\n")
cfg_file:write('```json\n')
if file_exists(OPENCLAW_JSON) then
  local file = io.open(OPENCLAW_JSON, "r")
  if file then
    local lines = {}
    for line in file:lines() do
      table.insert(lines, line)
    end
    file:close()
    
    local start_line = 580
    local end_line = 780
    for i = start_line, math.min(end_line, #lines) do
      cfg_file:write(lines[i] .. "\n")
    end
  end
else
  cfg_file:write('{ "error": "openclaw.json fehlt" }\n')
end
cfg_file:write('```\n')
cfg_file:close()

-- ENV-Status erstellen
local env_file = io.open(ENV_FILE, "w")
env_file:write("# ENV-Status: Gateway A / Node 1\n\n")
env_file:write("Stand: " .. NOW_LOCAL .. "\n\n")
env_file:write("## Dateien\n\n")
env_file:write('```text\n')
env_file:write(execute("ls -la " .. ENV_DOT .. " " .. ENV_SYSTEMD .. " 2>/dev/null") .. "\n")
env_file:write('```\n\n')
env_file:write("## .env (vollstaendig)\n\n")
env_file:write('```dotenv\n')
if file_exists(ENV_DOT) then
  env_file:write(read_file(ENV_DOT) .. "\n")
else
  env_file:write("# .env fehlt\n")
end
env_file:write('```\n\n')
env_file:write("## gateway.systemd.env (vollstaendig)\n\n")
env_file:write('```dotenv\n')
if file_exists(ENV_SYSTEMD) then
  env_file:write(read_file(ENV_SYSTEMD) .. "\n")
else
  env_file:write("# gateway.systemd.env fehlt\n")
end
env_file:write('```\n')
env_file:close()

-- Laufprotokoll erstellen
local run_content = [[
# Laufprotokoll Gateway A / Node 1

- Zeit (lokal): ]] .. NOW_LOCAL .. [[
- Zeit (UTC): ]] .. NOW_UTC .. [[
- Script: ]] .. arg[0] .. [[

## Erzeugte Dateien

- IST-ZUSTAND_GATEWAY-A_NODE1.md
- ARTEFAKT-INVENTAR_GATEWAY-A_NODE1.md
- OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-A_NODE1.md
- ENV-STATUS_GATEWAY-A_NODE1.md
]]

local run_file = io.open(RUN_FILE, "w")
run_file:write(run_content)
run_file:close()

-- Erfolgsmeldung
print("OK: IST-Zustand erfasst.")
local listing = execute("ls -1 " .. OUT_DIR)
for line in listing:gmatch("[^\r\n]+") do
  print("- " .. line)
end
