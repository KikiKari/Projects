#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "72c97bc236ebe4586248252e47e8a4ebfad6516c9169331fdb099ee751095b8b", "source_sha256": "04518825207cd6ef771c2d840daf0a025f3144f4e384f1d13b46e016570f59df", "target_language": "lua"}
-- fix_gateway_node_path.sh — portiert nach lua
-- Quelle: shell, OpenClaw@gateway1:scripts/fix_gateway_node_path.sh
-- auch in: OpenClaw@gateway2:scripts/fix_gateway_node_path.sh
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local os = require("os")
local io = require("io")

-- Backup der originalen Service-Datei
local timestamp = os.date("%Y%m%d_%H%M%S")
local backup_cmd = string.format("cp /etc/systemd/system/openclaw-gateway.service /etc/systemd/system/openclaw-gateway.service.backup-%s", timestamp)
os.execute(backup_cmd)

-- Korrektur des Node.js Pfads in der Service-Datei
-- Annahme: Node.js ist unter /usr/bin/node verfügbar (wie von 'which node' gezeigt)
local file = "/etc/systemd/system/openclaw-gateway.service"
local temp_file = "/tmp/openclaw-gateway.service.tmp"

local f = io.open(file, "r")
if not f then
    print("Fehler: Kann Datei nicht lesen: " .. file)
    return 1
end

local content = f:read("*all")
f:close()

local new_content = string.gsub(content, "/home/openclaw/.nvm/versions/node/v22.22.2/bin/node", "/usr/bin/node")

local out = io.open(temp_file, "w")
if not out then
    print("Fehler: Kann temporäre Datei nicht schreiben: " .. temp_file)
    return 1
end

out:write(new_content)
out:close()

-- Verschiebe die temporäre Datei an den richtigen Ort (ersetzt die Originale)
os.execute("mv " .. temp_file .. " " .. file)

-- Service neu laden und neu starten
os.execute("systemctl daemon-reload")
os.execute("systemctl restart openclaw-gateway")

-- Status prüfen
os.execute("systemctl status openclaw-gateway --no-pager")
