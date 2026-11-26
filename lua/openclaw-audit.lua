#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "80b01e9c8382b92a722eed425288e4a7f87a96adfdcb91769ff81c31bc94d0e7", "source_sha256": "e51b94641336291974fe14bf4bb7299a75ec7dcce49e1d413282c8043e9f09f1", "target_language": "lua"}
-- openclaw-audit.sh — portiert nach lua
-- Quelle: shell, OpenClaw@gateway1:scripts/openclaw-audit.sh
-- auch in: OpenClaw@gateway2:scripts/openclaw-audit.sh
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

-- OpenClaw read-only audit/diagnostic sweep
-- Output: openclaw-audit-YYYY-MM-DD.log im selben Verzeichnis wie dieses Script

local os = os
local io = io
local table = table

-- Hilfsfunktionen für Datum und Pfad
function formatDate(format)
  local date = os.date("*t")
  if format == "%Y-%m-%d" then
    return string.format("%04d-%02d-%02d", date.year, date.month, date.day)
  elseif format == "iso-8601" then
    return string.format("%04d-%02d-%02dT%02d:%02d:%02d", 
      date.year, date.month, date.day, date.hour, date.min, date.sec)
  end
  return ""
end

-- Aktuelles Verzeichnis ermitteln (vereinfacht)
local script_dir = "."

-- Datumstempel erstellen
local date_stamp = formatDate("%Y-%m-%d")
local out = script_dir .. "/openclaw-audit-" .. date_stamp .. ".log"

-- OpenClaw Kommando-Array (als Tabelle)
local oc = {"openclaw", "--no-color"}

-- Funktion zum Ausführen von Kommandos und Protokollieren der Ausgabe
function run_cmd(title, cmd_array)
  local cmd_str = table.concat(cmd_array, " ")
  local full_cmd = cmd_str .. " 2>&1"
  
  local file = io.open(out, "a")
  if not file then
    print("Fehler beim Öffnen der Log-Datei: " .. out)
    return
  end
  
  file:write("\n")
  file:write("----------------------------------------------------------------\n")
  file:write("### " .. title .. "\n")
  file:write("### $ " .. cmd_str .. "\n")
  file:write("### " .. formatDate("iso-8601") .. "\n")
  file:write("----------------------------------------------------------------\n")
  file:close()
  
  -- Ausführung des Kommandos und Anhängen an Log
  local handle = io.popen(full_cmd, "r")
  local result = handle:read("*a")
  local success, _, exit_code = handle:close()
  
  file = io.open(out, "a")
  if file then
    file:write(result)
    if success then
      file:write("[exit: 0]\n")
    else
      file:write("[exit: " .. (exit_code or 1) .. "]\n")
    end
    file:close()
  end
end

-- Initialer Header in Log schreiben
do
  local file = io.open(out, "w")
  if file then
    file:write("================================================================\n")
    file:write("OpenClaw audit run\n")
    file:write("Started:  " .. formatDate("iso-8601") .. "\n")
    file:write("Host:     " .. (os.getenv("HOSTNAME") or "unknown") .. "\n")
    file:write("User:     " .. (os.getenv("USER") or "unknown") .. "\n")
    
    -- Version ermitteln
    local version_handle = io.popen("openclaw --version 2>/dev/null", "r")
    local version = "unknown"
    if version_handle then
      version = version_handle:read("*l") or "unknown"
      version_handle:close()
    end
    file:write("Version:  " .. version .. "\n")
    file:write("Output:   " .. out .. "\n")
    file:write("================================================================\n")
    file:close()
  end
end

-- Audit-Kommandos ausführen
run_cmd("tasks audit --severity error", {table.unpack(oc), "tasks", "audit", "--severity", "error"})
run_cmd("secrets audit", {table.unpack(oc), "secrets", "audit"})
run_cmd("security audit", {table.unpack(oc), "security", "audit"})
run_cmd("plugins doctor", {table.unpack(oc), "plugins", "doctor"})
run_cmd("plugins deps", {table.unpack(oc), "plugins", "deps"})
run_cmd("plugins registry", {table.unpack(oc), "plugins", "registry"})
run_cmd("skills check", {table.unpack(oc), "skills", "check"})
run_cmd("hooks check", {table.unpack(oc), "hooks", "check"})
run_cmd("gateway status --deep", {table.unpack(oc), "gateway", "status", "--deep"})
run_cmd("channels status --probe", {table.unpack(oc), "channels", "status", "--probe"})
run_cmd("memory status --deep", {table.unpack(oc), "memory", "status", "--deep"})
run_cmd("sessions --all-agents", {table.unpack(oc), "sessions", "--all-agents"})
run_cmd("tasks list", {table.unpack(oc), "tasks", "list"})
run_cmd("cron list", {table.unpack(oc), "cron", "list"})

-- Abschlussmeldung
do
  local file = io.open(out, "a")
  if file then
    file:write("\n")
    file:write("================================================================\n")
    file:write("Audit complete: " .. formatDate("iso-8601") .. "\n")
    file:write("================================================================\n")
    file:close()
  end
end

print("Audit complete. Output: " .. out)
