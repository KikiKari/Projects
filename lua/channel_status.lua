#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "46557162ea96b14d5cef9bfed27ce31cf093dca7897a0693df7e08c640e1b3cb", "source_sha256": "705cb2cc5900c507db1038d107f06e2f8452a95c37d0611cd27dfe2ed61dd498", "target_language": "lua"}
-- channel_status.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/channel-status-agent/scripts/channel_status.py
-- auch in: OpenClaw@gateway2:skills/channel-status-agent/scripts/channel_status.py
-- Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

--[[
Channel Status Agent - Automatische Status-Updates
]]

local socket = require("socket")
local json = require("cjson")
local posix = require("posix")

-- Konfiguration
local WORKSPACE = "/home/openclaw/.openclaw/workspace"
local LOGS_DB = WORKSPACE .. "/db/logs.db"
local CONFIG_FILE = WORKSPACE .. "/config/channel-status.json"
local LOG_FILE = WORKSPACE .. "/logs/channel-status.log"

-- Hilfsfunktion für aktuelles Datum/Uhrzeit
local function now()
    return os.date("%Y-%m-%d %H:%M:%S")
end

local function iso_now()
    return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

-- Logging-Funktion
local function log(message, level)
    level = level or "INFO"
    local timestamp = now()
    local entry = string.format("[%s] [%s] %s", timestamp, level, message)
    print(entry)
    
    -- Log-Datei öffnen und schreiben
    local f = io.open(LOG_FILE, "a")
    if f then
        f:write(entry .. "\n")
        f:close()
    end
end

-- System-Status sammeln
local function get_system_status()
    local status = {
        timestamp = iso_now(),
        nodes = {},
        agents = {},
        system = {}
    }

    -- Node-Status (vereinfacht)
    local nodes = {
        node1 = {name = "Gateway", status = "online"},
        node2 = {name = "Worker", status = "online"},
        node3 = {name = "Relay", status = "offline", reason = "disk full"},
        node5 = {name = "Redmi", status = "intermittent"},
        node7 = {name = "Docker", status = "planned"}
    }
    status.nodes = nodes

    -- Agent-Status aus Cron (vereinfachte Version)
    local success, result = pcall(function()
        local handle = io.popen("crontab -l 2>/dev/null | grep -v '^#' | wc -l")
        local output = handle:read("*a")
        handle:close()
        return tonumber(output) or 0
    end)

    if success then
        status.agents.active_crons = result
    else
        status.agents.active_crons = "unknown"
    end

    -- System-Metriken
    local success_df, success_free = true, true
    
    -- Disk usage
    local df_success, df_result = pcall(function()
        local handle = io.popen("df -h /")
        local output = handle:read("*a")
        handle:close()
        
        for line in output:gmatch("[^\r\n]+") do
            if line:find("/") and line:find("%%") then
                local parts = {}
                for part in line:gmatch("%S+") do
                    table.insert(parts, part)
                end
                if #parts >= 5 then
                    return parts[5]
                end
            end
        end
        return nil
    end)

    if df_success and df_result then
        status.system.disk_used = df_result
    end

    -- RAM usage
    local free_success, free_result = pcall(function()
        local handle = io.popen("free -h")
        local output = handle:read("*a")
        handle:close()
        
        for line in output:gmatch("[^\r\n]+") do
            if line:find("Mem:") then
                local parts = {}
                for part in line:gmatch("%S+") do
                    table.insert(parts, part)
                end
                if #parts >= 3 then
                    return {total = parts[2], used = parts[3]}
                end
            end
        end
        return nil
    end)

    if free_success and free_result then
        status.system.ram_total = free_result.total
        status.system.ram_used = free_result.used
    end

    return status
end

-- Täglichen Status formatieren
local function format_daily_status(status)
    local nodes = status.nodes
    local online_count = 0
    for _, info in pairs(nodes) do
        if info.status == "online" then
            online_count = online_count + 1
        end
    end

    local message = string.format([[📊 **Täglicher Status-Report**
🗓️ %s

**🖥️ Nodes (%d/5 online):**
]], os.date("%Y-%m-%d %H:%M"), online_count)

    for node_id, info in pairs(nodes) do
        local emoji = "🟢"
        if info.status == "offline" then
            emoji = "🔴"
        elseif info.status ~= "online" then
            emoji = "🟡"
        end
        
        message = message .. emoji .. " " .. info.name .. ": " .. info.status
        if info.reason then
            message = message .. " (" .. info.reason .. ")"
        end
        message = message .. "\n"
    end

    message = message .. "\n**🤖 Agents:**\n"
    message = message .. "Aktive Cron-Jobs: " .. tostring(status.agents.active_crons) .. "\n"

    if status.system.disk_used then
        message = message .. "\n**💾 System:**\n"
        message = message .. "Disk: " .. status.system.disk_used .. " belegt\n"
        message = message .. "RAM: " .. status.system.ram_used .. " / " .. status.system.ram_total .. "\n"
    end

    return message
end

-- Wöchentlichen Status formatieren
local function format_weekly_status(status)
    return string.format([[📈 **Wöchentlicher Report**
📅 Woche %s - %s

**Zusammenfassung:**
- 5 aktive Sub-Agents
- 11 Skills synchronisiert
- 3 neue Features implementiert

**Top-Ereignisse:**
1. ClawHub-Git Sync implementiert ✅
2. Node 3 Disk voll (95%) ⚠️
3. Channel-Status-Agent aktiviert 🆕

**Geplante Wartungen:**
- Node 3: Disk-Cleanup erforderlich
- Node 7: Docker-Setup ausstehend
]], os.date("%V"), os.date("%Y"))
end

-- Nachricht an Channel senden
local function send_to_channel(message, channel_type, channel_id)
    channel_type = channel_type or "telegram"
    channel_id = channel_id or "-1002381931352"
    
    if channel_type ~= "telegram" then
        log("Channel type " .. channel_type .. " not implemented", "WARN")
        return false
    end

    -- Befehl vorbereiten
    local cmd = string.format('echo %q | openclaw message send --target %s --message -', 
                              message:gsub('"', '\\"'), channel_id)
    
    -- Befehl ausführen
    local success, exit_code, signal = os.execute(cmd)
    
    if success and exit_code == 0 then
        log("Message sent to " .. channel_type .. " " .. channel_id)
        return true
    else
        log("Failed to send message", "ERROR")
        return false
    end
end

-- Hauptfunktion
local function main()
    -- Argumente parsen
    local args = {
        type = nil,
        message = nil,
        channel = "-1002381931352",
        dry_run = false
    }

    -- Einfacher Argparser
    for i = 1, #arg do
        if arg[i] == "--type" and arg[i+1] then
            args.type = arg[i+1]
            i = i + 1
        elseif arg[i] == "--message" and arg[i+1] then
            args.message = arg[i+1]
            i = i + 1
        elseif arg[i] == "--channel" and arg[i+1] then
            args.channel = arg[i+1]
            i = i + 1
        elseif arg[i] == "--dry-run" then
            args.dry_run = true
        end
    end

    if not args.type then
        print("Fehler: --type ist erforderlich")
        print("Verwendung: channel_status.lua --type <daily|weekly|alert> [--message TEXT] [--channel ID] [--dry-run]")
        os.exit(1)
    end

    log("Starting " .. args.type .. " status update")

    -- Status sammeln
    local status = get_system_status()

    -- Nachricht formatieren
    local message
    if args.type == "daily" then
        message = format_daily_status(status)
    elseif args.type == "weekly" then
        message = format_weekly_status(status)
    elseif args.type == "alert" then
        message = "🚨 **ALERT**\n" .. (args.message or "Manual alert")
    else
        print("Unbekannter Typ: " .. args.type)
        os.exit(1)
    end

    -- Senden oder Dry-Run
    if args.dry_run then
        print("\n--- DRY RUN ---")
        print(message)
        print("--- END ---")
    else
        send_to_channel(message, "telegram", args.channel)
    end

    log("Status update completed")
end

-- Sicherstellen, dass das Log-Verzeichnis existiert
local function ensure_log_dir()
    local log_dir = WORKSPACE .. "/logs"
    -- Prüfen ob Verzeichnis existiert
    local stat = posix.stat(log_dir, "type")
    if not stat then
        -- Versuchen Verzeichnis zu erstellen
        posix.mkdir(WORKSPACE)
        posix.mkdir(log_dir)
    end
end

-- Skript starten
ensure_log_dir()
main()
