#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "1b5257781cd3b4b97329692e2710eb517fc5b746d780f4e91308ae3ebb3db38b", "source_sha256": "77eca70a7a8f9c0ff8dc240b14d8c37999854c241e031b8167e1fcd650cbd334", "target_language": "lua"}
-- install_cron.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/install_cron.py
-- auch in: OpenClaw@gateway2:skills/db-maintainer/scripts/install_cron.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[
Installiert den DB-Maintainer als Cron-Job
]]

local json = require("cjson")
local posix = require("posix")

local CRON_JOB = [[
# DB Maintainer - Alle 30 Minuten
*/30 * * * * cd /home/openclaw/.openclaw/workspace && python3 skills/db-maintainer/scripts/db_maintainer.py >> logs/db-maintainer/cron.log 2>&1
]]

local function mkdir_p(path)
    local dirs = {}
    for dir in string.gmatch(path, "([^/]+)") do
        table.insert(dirs, dir)
    end
    
    local current_path = ""
    if string.sub(path, 1, 1) == "/" then
        current_path = "/"
    end
    
    for i, dir in ipairs(dirs) do
        current_path = current_path .. dir
        if not posix.stat(current_path, "type") then
            local success, err = posix.mkdir(current_path)
            if not success then
                error("Failed to create directory " .. current_path .. ": " .. err)
            end
        end
        current_path = current_path .. "/"
    end
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
        return true
    else
        return false
    end
end

local function install()
    local workspace = "/home/openclaw/.openclaw/workspace"
    local cron_file = workspace .. "/crons/db-maintainer.cron"
    
    mkdir_p(workspace .. "/crons")
    
    if not write_file(cron_file, CRON_JOB) then
        error("Failed to write cron file: " .. cron_file)
    end
    
    print("✅ Cron-Job installiert: " .. cron_file)
    print("   Füge zu crontab hinzu mit: crontab < crons/db-maintainer.cron")
    
    -- Auch in OpenClaw cron registrieren
    local jobs_json = workspace .. "/.openclaw/cron/jobs.json"
    if file_exists(jobs_json) then
        local content = read_file(jobs_json)
        if content then
            local jobs = json.decode(content)
            
            jobs["db-maintainer"] = {
                schedule = "*/30 * * * *",
                command = "python3 skills/db-maintainer/scripts/db_maintainer.py",
                enabled = true
            }
            
            local success = write_file(jobs_json, json.encode(jobs))
            if success then
                print("✅ In OpenClaw cron registriert")
            else
                print("❌ Fehler beim Registrieren in OpenClaw cron")
            end
        end
    end
end

install()
