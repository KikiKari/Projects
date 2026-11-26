#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "21e2d9b0b0e5636087023d5010425ae4bddfd33b47ee535340169e4b36eac790", "source_sha256": "da890cc26fb848b78b6a85373d6cfa4e08f6e7c2002921e1c0247960b8b361d7", "target_language": "lua"}
-- collect_ist_gateway_b.sh — portiert nach lua
-- Quelle: shell, OpenClaw@gateway2:scripts/collect_ist_gateway_b.sh
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local socket = require("socket")
local ltn12 = require("ltn12")
local http = require("socket.http")

-- Hilfsfunktionen
local function exec(cmd)
  local handle = io.popen(cmd)
  local result = handle:read("*a")
  handle:close()
  return result:gsub("%s+$", "")
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
  local stat = socket.gettime() -- dummy use to avoid unused warning
  local ok, _, code = os.rename(path, path)
  if not ok then
    if code == 13 then
      return true
    end
    return false
  else
    return true
  end
end

local function read_file(path)
  local file = io.open(path, "r")
  if file then
    local content = file:read("*a")
    file:close()
    return content
  else
    return nil
  end
end

local function write_file(path, content)
  local file = io.open(path, "w")
  if file then
    file:write(content)
    file:close()
  end
end

local function get_date_utc()
  return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function get_date_local()
  return os.date("%Y-%m-%d %H:%M:%S %Z")
end

local function get_timestamp()
  return os.date("%Y%m%d-%H%M%S")
end

-- Konfiguration
local BASE_DIR = os.getenv("HOME") .. "/.openclaw"
local OUT_DIR = BASE_DIR .. "/workspace/vscode"
local NOW_UTC = get_date_utc()
local NOW_LOCAL = get_date_local()
local TS = get_timestamp()

-- Ordner erstellen
os.execute("mkdir -p " .. OUT_DIR)

-- Dateipfade
local IST_FILE = OUT_DIR .. "/IST-ZUSTAND_GATEWAY-B_NODE7.md"
local INV_FILE = OUT_DIR .. "/ARTEFAKT-INVENTAR_GATEWAY-B_NODE7.md"
local CFG_FILE = OUT_DIR .. "/OPENCLAW-CONFIG-SNAPSHOT_GATEWAY-B_NODE7.md"
local ENV_FILE = OUT_DIR .. "/ENV-STATUS_GATEWAY-B_NODE7.md"
local RUN_FILE = OUT_DIR .. "/RUN-" .. TS .. ".md"

-- Dateipfade für Checks
local OPENCLAW_JSON = BASE_DIR .. "/openclaw.json"
local ENV_DOT = BASE_DIR .. "/.env"
local ENV_SYSTEMD = BASE_DIR .. "/gateway.systemd.env"
local VSCODE_DIR = BASE_DIR .. "/.vscode"

-- Systeminformationen sammeln
local HOSTNAME_FQDN = exec("hostname -f 2>/dev/null || hostname")
local HOSTNAME_SHORT = exec("hostname")
local ARCH = exec("uname -m")
local KERNEL = exec("uname -r")
local OS_PRETTY = exec("grep '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '\"'")
local IPV4_ALL = exec("hostname -I 2>/dev/null | xargs")
local PUBLIC_IP = exec("curl -4 -s --max-time 4 ifconfig.me 2>/dev/null") or "(nicht ermittelt)"
local TAILSCALE_IP = exec("tailscale ip -4 2>/dev/null | head -n1") or "(nicht ermittelt)"
local OPENCLAW_VER = exec("openclaw --version 2>/dev/null") or "(nicht ermittelt)"
local NODE_VER = exec("node -v 2>/dev/null") or "(nicht ermittelt)"

-- IST-Zustand
local ist_content = [[
# IST-Zustand: Gateway B / Node 7

Stand (lokal): ]] .. NOW_LOCAL .. [[  
Stand (UTC): ]] .. NOW_UTC .. [[

## 1) Identität & System

- Gateway: **B**
- Node: **7**
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
- `]] .. BASE_DIR .. [[/plugin-skills`: ]] .. (dir_exists(BASE_DIR .. "/plugin-skills") and "vorhanden" or "fehlt") .. [[

## 4) Hinweis

Diese Datei wird bei jedem Lauf neu geschrieben.
Zusätzlich wird ein Laufprotokoll als `RUN-*.md` erzeugt.
]]

write_file(IST_FILE, ist_content)

-- Artefakt-Inventar
local inv_content = "# Artefakt-Inventar: Gateway B / Node 7\n\n"
inv_content = inv_content .. "Stand: " .. NOW_LOCAL .. "\n\n"
inv_content = inv_content .. "## Top-Level in ~/.openclaw\n\n```\n"
local files = exec("ls -1 " .. BASE_DIR .. " 2>/dev/null")
inv_content = inv_content .. (files or "") .. "\n```\n\n"
inv_content = inv_content .. "## ~/.openclaw/.vscode\n\n```\n"
if dir_exists(VSCODE_DIR) then
  inv_content = inv_content .. exec("ls -la " .. VSCODE_DIR) .. "\n"
else
  inv_content = inv_content .. "(nicht vorhanden)\n"
end
inv_content = inv_content .. "```\n\n"
inv_content = inv_content .. "## plugin-skills/\n\n```\n"
if dir_exists(BASE_DIR .. "/plugin-skills") then
  inv_content = inv_content .. exec("ls -1 " .. BASE_DIR .. "/plugin-skills") .. "\n"
else
  inv_content = inv_content .. "(nicht vorhanden)\n"
end
inv_content = inv_content .. "```\n\n"
inv_content = inv_content .. "## openclaw.json Backups\n\n```\n"
local backups = exec("ls -1 " .. BASE_DIR .. "/openclaw.json.bak* 2>/dev/null")
inv_content = inv_content .. (backups or "(keine gefunden)") .. "\n```\n"

write_file(INV_FILE, inv_content)

-- Config Snapshot
local cfg_content = "# OpenClaw Config Snapshot: Gateway B / Node 7\n\n"
cfg_content = cfg_content .. "Stand: " .. NOW_LOCAL .. "\n\n"
cfg_content = cfg_content .. "## Schlüsselpositionen (grep)\n\n```\n"
if file_exists(OPENCLAW_JSON) then
  cfg_content = cfg_content .. exec("grep -nE '\"gateway\"|\\\"session\\\"|\\\"dmScope\\\"|\\\"auth\\\"|\\\"secrets\\\"|\\\"tools\\\"|\\\"plugins\\\"|\\\"profile\\\"|\\\"alsoAllow\\\"|\\\"denyCommands\\\"' " .. OPENCLAW_JSON) .. "\n"
else
  cfg_content = cfg_content .. "openclaw.json fehlt\n"
end
cfg_content = cfg_content .. "```\n\n"
cfg_content = cfg_content .. "## Ausschnitt gateway/session/auth (ungefiltert, betriebsnah)\n\n```\n"
if file_exists(OPENCLAW_JSON) then
  local json_content = read_file(OPENCLAW_JSON)
  local lines = {}
  for line in json_content:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  for i = 580, 780 do
    if lines[i] then
      cfg_content = cfg_content .. lines[i] .. "\n"
    end
  end
else
  cfg_content = cfg_content .. "{ \"error\": \"openclaw.json fehlt\" }\n"
end
cfg_content = cfg_content .. "```\n"

write_file(CFG_FILE, cfg_content)

-- ENV-Status
local env_content = "# ENV-Status: Gateway B / Node 7\n\n"
env_content = env_content .. "Stand: " .. NOW_LOCAL .. "\n\n"
env_content = env_content .. "## Dateien\n\n```\n"
env_content = env_content .. exec("ls -la " .. ENV_DOT .. " " .. ENV_SYSTEMD .. " 2>/dev/null") .. "\n```\n\n"
env_content = env_content .. "## .env (vollständig, ungefiltert)\n\n```\n"
if file_exists(ENV_DOT) then
  env_content = env_content .. read_file(ENV_DOT) .. "\n"
else
  env_content = env_content .. "# .env fehlt\n"
end
env_content = env_content .. "```\n\n"
env_content = env_content .. "## gateway.systemd.env (vollständig, ungefiltert)\n\n```\n"
if file_exists(ENV_SYSTEMD) then
  env_content = env_content .. read_file(ENV_SYSTEMD) .. "\n"
else
  env_content = env_content .. "# gateway.systemd.env fehlt\n"
end
env_content = env_content .. "```\n"

write_file(ENV_FILE, env_content)

-- Laufprotokoll
local run_content = "# Laufprotokoll Gateway B / Node 7\n\n"
run_content = run_content .. "- Zeit (lokal): " .. NOW_LOCAL .. "\n"
run_content = run_content .. "- Zeit (UTC): " .. NOW_UTC .. "\n"
run_content = run_content .. "- Script: " .. arg[0] .. "\n\n"
run_content = run_content .. "## Erzeugte Dateien\n\n"
run_content = run_content .. "- " .. IST_FILE:match("([^/]+)$") .. "\n"
run_content = run_content .. "- " .. INV_FILE:match("([^/]+)$") .. "\n"
run_content = run_content .. "- " .. CFG_FILE:match("([^/]+)$") .. "\n"
run_content = run_content .. "- " .. ENV_FILE:match("([^/]+)$") .. "\n"

write_file(RUN_FILE, run_content)

print("OK: IST-Zustand erfasst.")
print("Ausgabeordner: " .. OUT_DIR)
print("Dateien:")
local files_list = exec("ls -1 " .. OUT_DIR)
for file in files_list:gmatch("[^\r\n]+") do
  print("- " .. file)
end
