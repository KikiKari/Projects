#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "4bdf4e9f2dbb81297da007999c6359e91ff979e5cd10b576a8044cf288e20597", "source_sha256": "748c0fc07a58caf07d4983d358cf0e1ce57c4e180b87ae617d598f53c61efcec", "target_language": "lua"}
-- dispatch_job.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/dispatch_job.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[
Job Dispatcher - Verteilt Jobs auf passende Nodes
]]

local json = require("cjson")

local function job_weight_bytes(script_path, target_langs_count)
    -- Arbeitsvolumen: Dateigröße × Anzahl der Zielsprachen
    local file = io.open(script_path, "r")
    if not file then return 0 end
    local size = file:seek("end")
    file:close()
    return size * target_langs_count
end

-- Node-Konfiguration
local NODES = {
    node1 = {always_available = true, capacity = "medium", priority = 3, description = "Gateway"},
    node2 = {always_available = false, capacity = "high", priority = 1, description = "ARM Server"},
    node3 = {always_available = false, capacity = "medium", priority = 4, description = "AMD Server"},
    node4 = {always_available = false, capacity = "low", priority = 5, device = "Redmi Note 11S"},
    node5 = {always_available = false, capacity = "high", priority = 2, device = "Lenovo"},
    node6 = {always_available = false, device = "Lenovo (Docker)"}
}

local NODE_NAMES = {
    node2 = {"openclaw-node2", "arm64-node", "v2202604104722449961", "v2202604104722449961.taild25fea.ts.net", "100.82.198.122"},
    node3 = {"openclaw-node3", "openclaw-node3.taild25fea.ts.net", "100.73.154.125"},
    node4 = {"openclaw-node4", "redmi-note-11s", "redmi-note-11s.taild25fea.ts.net", "100.94.134.39"},
    node5 = {"openclaw-node5", "windows node (lenovo-7)"},
    node6 = {"openclaw-node6"}
}

local function table_contains(tbl, value)
    for _, v in pairs(tbl) do
        if v == value then return true end
    end
    return false
end

local function fetch_node_status()
    -- Return mapped OpenClaw connection states; nil indicates lookup failure
    local success, result = pcall(function()
        local handle = io.popen("timeout 10 openclaw nodes status --json 2>/dev/null")
        if not handle then return nil end
        local output = handle:read("*a")
        handle:close()
        return output
    end)
    
    if not success or not result then
        return nil
    end
    
    local payload = json.decode(result)
    if type(payload) ~= "table" or type(payload.nodes) ~= "table" then
        return nil
    end
    
    local states = {}
    for node, _ in pairs(NODE_NAMES) do
        states[node] = false
    end
    
    for _, item in ipairs(payload.nodes) do
        if type(item) == "table" then
            local names = {}
            if item.displayName then table.insert(names, string.lower(tostring(item.displayName))) end
            if item.nodeId then table.insert(names, string.lower(tostring(item.nodeId))) end
            if item.remoteIp then table.insert(names, string.lower(tostring(item.remoteIp))) end
            
            for node, aliases in pairs(NODE_NAMES) do
                for _, name in ipairs(names) do
                    if table_contains(aliases, name) and item.connected == true then
                        states[node] = true
                    end
                end
            end
        end
    end
    
    states.node1 = true  -- successful Gateway status request
    return states
end

local JobDispatcher = {}
JobDispatcher.__index = JobDispatcher

function JobDispatcher:new()
    local obj = {}
    setmetatable(obj, self)
    return obj
end

function JobDispatcher:get_job_weight(script_path, target_langs_count)
    -- Bewertet Job-Gewicht
    target_langs_count = target_langs_count or 1
    
    local file = io.open(script_path, "r")
    if not file then
        return "medium"
    end
    file:close()
    
    local total_work = job_weight_bytes(script_path, target_langs_count)
    
    if total_work > 50000 then  -- > 50KB
        return "heavy"
    elseif total_work > 10000 then  -- > 10KB
        return "medium"
    else
        return "light"
    end
end

function JobDispatcher:select_node(job_weight)
    -- Wählt besten Node basierend auf Job-Gewicht
    local preferred = {}
    if job_weight == "heavy" then
        preferred = {"node1", "node2", "node5", "node6"}
    elseif job_weight == "medium" then
        preferred = {"node1", "node2", "node3", "node6"}
    elseif job_weight == "light" then
        preferred = {"node2", "node1", "node3", "node4"}
    else
        error("Unknown job weight: " .. tostring(job_weight))
    end

    local states = fetch_node_status()
    for _, node_id in ipairs(preferred) do
        if states and states[node_id] then
            return node_id
        end
    end
    return nil  -- no verified reachable node
end

function JobDispatcher:check_node_available(node_id)
    -- Use the live connection state rather than static availability
    local states = fetch_node_status()
    return not not (states and states[node_id])
end

function JobDispatcher:_check_mobile_online()
    -- Check Node4 (Redmi)
    return self:check_node_available("node4")
end

function JobDispatcher:dispatch(job_script, target_langs, source_text, source_language)
    -- Dispatched Job und gibt Info zurück
    target_langs = target_langs or {"perl5"}
    
    local weight = self:get_job_weight(job_script, #target_langs)
    local selected_node = self:select_node(weight)
    local translation_jobs = {}
    
    for _, language in ipairs(target_langs) do
        local job = {
            job_id = tostring(os.time()) .. "-" .. math.random(1000000),  -- Simple UUID replacement
            source = job_script,
            target_language = language,
            selected_node = selected_node
        }
        if source_text ~= nil then
            job.source_text = source_text
        end
        if source_language ~= nil then
            job.source_language = source_language
        end
        table.insert(translation_jobs, job)
    end
    
    return {
        job = job_script,
        weight = weight,
        selected_node = selected_node,
        target_langs = target_langs,
        translation_jobs = translation_jobs,
        status = (selected_node and "selected" or "unavailable")
    }
end

local function execute_translation(job, transport)
    -- Execute via a supplied transport and verify its result belongs to the job
    if not job.selected_node or not transport then
        error("no verified node or authorized translation transport")
    end
    local response = transport(job)
    if type(response) ~= "table" then
        error("invalid transport response")
    end
    for _, key in ipairs({"job_id", "selected_node", "target_language"}) do
        if response[key] ~= job[key] then
            error("transport response does not match job")
        end
    end
    local code = response.code
    if response.status ~= "ok" or type(code) ~= "string" or not code:match("%S") then
        error("translation did not complete with code")
    end
    return code
end

local function dispatch_abstraction_job(job_script, target_langs)
    -- Erstellt eine Node-Auswahl und je (Skript, Sprache) einen Auftrag
    local dispatcher = JobDispatcher:new()
    return dispatcher:dispatch(job_script, target_langs)
end

local function split_string(str, delimiter)
    local parts = {}
    for part in string.gmatch(str, "([^" .. delimiter .. "]+)") do
        table.insert(parts, part)
    end
    return parts
end

local function file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

local function main()
    -- Parse command line arguments manually since Lua doesn't have argparse built-in
    local args = {}
    for i = 1, #arg do
        if arg[i] == "--job" or arg[i] == "-j" then
            args.job = arg[i+1]
        elseif arg[i] == "--langs" or arg[i] == "-l" then
            args.langs = arg[i+1]
        elseif arg[i] == "--weight" or arg[i] == "-w" then
            args.weight = arg[i+1]
        elseif arg[i] == "--execute" or arg[i] == "-x" then
            args.execute = true
        end
    end
    
    if not args.job then
        print("Usage: " .. (arg[0] or "dispatch_job.lua") .. " --job JOB_FILE [--langs LANGS] [--weight WEIGHT] [--execute]")
        return 1
    end
    
    local job_path = args.job
    if not file_exists(job_path) then
        print("❌ Job not found: " .. job_path)
        return 1
    end
    
    local dispatcher = JobDispatcher:new()
    local target_langs = args.langs and split_string(args.langs, ",") or {"perl5"}
    
    -- Determine weight
    local weight
    if args.weight then
        weight = args.weight
    else
        weight = dispatcher:get_job_weight(job_path, #target_langs)
    end
    
    -- Select node
    local selected_node = dispatcher:select_node(weight)
    
    -- Output
    print("📦 Job Dispatch Information")
    print(string.rep("=", 50))
    
    local file = io.open(job_path, "r")
    local size = 0
    if file then
        size = file:seek("end")
        file:close()
    end
    
    print("Job: " .. job_path)
    print("Size: " .. size .. " bytes")
    print("Target langs: " .. table.concat(target_langs, ", "))
    print("Job weight: " .. weight)
    print("Selected node: " .. tostring(selected_node))
    print(string.rep("=", 50))
    
    if args.execute then
        print("\nTranslation dispatch on " .. tostring(selected_node) .. " is not implemented.")
        return 1
    else
        print("\n💡 To execute: " .. (arg[0] or "dispatch_job.lua") .. " --job " .. args.job .. " --execute")
    end
    return 0
end

-- Run main if this script is executed directly
if not package.loaded[...] then
    os.exit(main())
else
    -- Export functions for use as module
    return {
        JobDispatcher = JobDispatcher,
        dispatch_abstraction_job = dispatch_abstraction_job,
        execute_translation = execute_translation,
        fetch_node_status = fetch_node_status
    }
end
