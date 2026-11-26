#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "9af30712c1ac57e228d87170ac2b7ea0e6c9d2fb1fb5e96108bd94e5479581ae", "source_sha256": "5aa602a80e57cbc63f54485d4cd66e205c54bd9f32bc03434218ff9bd388b3ab", "target_language": "lua"}
-- collect_compare_bundle.sh — portiert nach lua
-- Quelle: shell, OpenClaw@gateway1:scripts/collect_compare_bundle.sh
-- auch in: OpenClaw@gateway2:scripts/collect_compare_bundle.sh
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local ROOT = "/home/openclaw/.openclaw"
local OUT_DIR = ROOT .. "/workspace/vscode/compare"
local TRANSFER_DIR = OUT_DIR .. "/transfer"
local MD_FILE = OUT_DIR .. "/local-gateway-config.md"
local TREE_FILE = OUT_DIR .. "/tree.txt"
local BACKUP_FILE = "/home/openclaw/openclaw-backup.tar.gz"

-- Hilfsfunktionen
local function execute_command(cmd)
  local handle = io.popen(cmd)
  local result = handle:read("*a")
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
  local stat = io.popen("test -d '" .. path .. "' && echo 'exists'"):read("*l")
  return stat == "exists"
end

local function mkdir_p(path)
  os.execute("mkdir -p '" .. path .. "'")
end

-- Zeit und Host Informationen
local NOW_LOCAL = execute_command("date '+%Y-%m-%d %H:%M:%S %Z'"):gsub("\n$", "")
local NOW_UTC = execute_command("date -u '+%Y-%m-%dT%H:%M:%SZ'"):gsub("\n$", "")
local HOST = execute_command("hostname -f 2>/dev/null || hostname"):gsub("\n$", "")

-- Pfade zu Konfigurationsdateien
local OPENCLAW_JSON = ROOT .. "/openclaw.json"
local EXEC_APPROVALS_JSON = ROOT .. "/exec-approvals.json"
local GATEWAY_SYSTEMD_ENV = ROOT .. "/gateway.systemd.env"
local DOT_ENV = ROOT .. "/.env"
local CONFIG_DIR = ROOT .. "/.config"
local AGENTS_DIR = ROOT .. "/agents"

-- Verzeichnisse erstellen
mkdir_p(OUT_DIR)
mkdir_p(TRANSFER_DIR)

-- Prüfen ob 'tree' verfügbar ist
local tree_check = execute_command("command -v tree >/dev/null 2>&1 && echo 'found'")
if tree_check ~= "found" then
  print("Fehler: 'tree' ist nicht installiert.")
  os.exit(1)
end

-- Funktionen zum Schreiben in die Markdown-Datei
local md_handle

local function append_file_verbatim(label, path, lang)
  lang = lang or "text"
  md_handle:write("\n## " .. label .. "\n\n")
  md_handle:write("Pfad: `" .. path .. "`\n\n")
  md_handle:write("```" .. lang .. "\n")
  if file_exists(path) then
    local file = io.open(path, "r")
    local content = file:read("*a")
    file:close()
    md_handle:write(content)
  else
    md_handle:write("[FEHLT] " .. path .. "\n")
  end
  md_handle:write("\n```\n")
end

local function append_env_verbatim()
  md_handle:write("\n## Umgebungsvariablen (env)\n\n")
  md_handle:write("```text\n")
  local env_vars = execute_command("env")
  md_handle:write(env_vars)
  md_handle:write("```\n")
end

local function append_dir_files_verbatim(section, dir)
  md_handle:write("\n## " .. section .. "\n\n")
  if not dir_exists(dir) then
    md_handle:write("[FEHLT] " .. dir .. "\n")
    return
  end
  md_handle:write("Basisverzeichnis: `" .. dir .. "`\n")

  local find_cmd = "find '" .. dir .. "' -type f -print0 | sort -z"
  local handle = io.popen(find_cmd)
  local files = handle:read("*a")
  handle:close()

  for f in string.gmatch(files, "[^\0]+") do
    md_handle:write("\n### Datei: `" .. f .. "`\n\n")
    md_handle:write("```text\n")
    local file = io.open(f, "r")
    if file then
      local content = file:read("*a")
      file:close()
      md_handle:write(content)
    end
    md_handle:write("\n```\n")
  end
end

-- Hauptausführung
md_handle = io.open(MD_FILE, "w")

md_handle:write("# Lokaler Gateway-Konfigurationsstand\n\n")
md_handle:write("Generiert: " .. NOW_LOCAL .. "\n")
md_handle:write("UTC: " .. NOW_UTC .. "\n")
md_handle:write("Host: " .. HOST .. "\n\n")
md_handle:write("Diese Datei enthaelt den lokalen Stand mit unveraenderten Inhalten.\n")

append_file_verbatim("openclaw.json", OPENCLAW_JSON, "json")
append_file_verbatim("exec-approvals.json", EXEC_APPROVALS_JSON, "json")
append_file_verbatim("gateway.systemd.env", GATEWAY_SYSTEMD_ENV, "dotenv")
append_file_verbatim(".env", DOT_ENV, "dotenv")
append_env_verbatim()
append_dir_files_verbatim(".config (alle Dateien rekursiv)", CONFIG_DIR)
append_dir_files_verbatim("agents (alle Dateien rekursiv)", AGENTS_DIR)

md_handle:close()

-- Baumstruktur generieren
os.execute("tree -a -L 6 '" .. ROOT .. "' > '" .. TREE_FILE .. "'")

-- Backup erstellen
os.execute("openclaw backup create --output '" .. BACKUP_FILE .. "' --verify")
os.execute("cp '" .. BACKUP_FILE .. "' '" .. OUT_DIR .. "'")

print("OK")
print("Erzeugt:")
print("- " .. MD_FILE)
print("- " .. TREE_FILE)
print("- " .. BACKUP_FILE)
print("- " .. TRANSFER_DIR .. " (leer)")
