#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "b1cfaa3dd8ff3bf33ebdff5d1e0db9b17d8de6b30e4ac790d03c463b6b9ae021", "source_sha256": "128b137e5c7d86f81ea7fdb61718540c70e4ed38de4430ae6a23a5739962c024", "target_language": "lua"}
-- dispatch_job.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway2:skills/multi-nodes-utils/scripts/dispatch_job.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[
Job Dispatcher - Verteilt Jobs auf passende Nodes
]]

local NODES = {
    node1 = {always_available = true, capacity = "medium", priority = 2},
    node2 = {always_available = true, capacity = "medium", priority = 3},
    node3 = {always_available = false, capacity = "medium", priority = 4},
    node5 = {always_available = false, capacity = "low", priority = 5, device = "Redmi Note 11S"},
    node7 = {always_available = true, capacity = "high", priority = 1},
}

local JobDispatcher = {}
JobDispatcher.__index = JobDispatcher

function JobDispatcher:new()
    local obj = {}
    setmetatable(obj, JobDispatcher)
    return obj
end

-- Bewertet Job-Gewicht
function JobDispatcher:get_job_weight(script_path, target_langs_count)
    target_langs_count = target_langs_count or 1
    
    local file = io.open(script_path, "r")
    if not file then
        return "medium"
    end
    
    local content = file:read("*a")
    file:close()
    
    local script_size = #content
    local total_work = script_size * target_langs_count
    
    if total_work > 50000 then  -- > 50KB
        return "heavy"
    elseif total_work > 10000 then  -- > 10KB
        return "medium"
    else
        return "light"
    end
end

-- Wählt besten Node basierend auf Job-Gewicht
function JobDispatcher:select_node(job_weight)
    local preferred
    
    if job_weight == "heavy" then
        -- Schwere Jobs → Node 7 (Docker), dann Node 2, dann Node 1
        preferred = {"node7", "node2", "node1"}
    elseif job_weight == "medium" then
        -- Mittlere Jobs → Stable Nodes
        preferred = {"node2", "node1", "node7"}
    else  -- light
        -- Leichte Jobs → Mobile/verfügbare Nodes
        preferred = {"node5", "node1", "node2"}
    end
    
    -- Prüfe Verfügbarkeit
    for _, node_id in ipairs(preferred) do
        if self:check_node_available(node_id) then
            return node_id
        end
    end
    
    -- Fallback
    return "node1"
end

-- Prüft ob Node erreichbar ist
function JobDispatcher:check_node_available(node_id)
    if not NODES[node_id] then
        return false
    end
    
    local node = NODES[node_id]
    
    -- Nicht immer-verfügbare Nodes nur wenn explizit requested
    if not node.always_available then
        -- Für light-jobs prüfen wir ob online
        if node_id == "node5" then  -- Redmi
            return self:_check_mobile_online()
        end
        return false
    end
    
    -- Für immer-verfügbare Nodes: prüfe ob wirklich online
    local success, _, code = os.execute("openclaw nodes status " .. node_id)
    return success and code == 0
end

-- Prüft ob Redmi (Node 5) Internet hat
function JobDispatcher:_check_mobile_online()
    local handle = io.popen("openclaw nodes status node5 2>/dev/null", "r")
    if not handle then
        return false
    end
    
    local result = handle:read("*a")
    handle:close()
    
    return string.find(result:lower(), "online") ~= nil
end

-- Dispatched Job und gibt Info zurück
function JobDispatcher:dispatch(job_script, target_langs)
    target_langs = target_langs or {"perl5"}
    
    local weight = self:get_job_weight(job_script, #target_langs)
    local selected_node = self:select_node(weight)
    
    return {
        job = job_script,
        weight = weight,
        selected_node = selected_node,
        target_langs = target_langs,
        status = "dispatched"
    }
end

local function file_exists(path)
    local file = io.open(path, "r")
    if file then
        file:close()
        return true
    end
    return false
end

local function get_file_size(path)
    local file = io.open(path, "r")
    if not file then
        return 0
    end
    local size = #file:read("*a")
    file:close()
    return size
end

local function split_string(str, delimiter)
    local parts = {}
    for part in string.gmatch(str, "[^"..delimiter.."]+") do
        table.insert(parts, part)
    end
    return parts
end

local function main()
    -- Simple argument parsing
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
        print("Usage: "..arg[0].." --job JOB_FILE [--langs LANGS] [--weight WEIGHT] [--execute]")
        os.exit(1)
    end
    
    if not file_exists(args.job) then
        print("❌ Job not found: "..args.job)
        os.exit(1)
    end
    
    local dispatcher = JobDispatcher:new()
    local target_langs = args.langs and split_string(args.langs, ",") or {"perl5"}
    
    -- Determine weight
    local weight
    if args.weight then
        weight = args.weight
    else
        weight = dispatcher:get_job_weight(args.job, #target_langs)
    end
    
    -- Select node
    local selected_node = dispatcher:select_node(weight)
    
    -- Output
    print("📦 Job Dispatch Information")
    print(string.rep("=", 50))
    print("Job: "..args.job)
    print("Size: "..get_file_size(args.job).." bytes")
    print("Target langs: "..table.concat(target_langs, ", "))
    print("Job weight: "..weight)
    print("Selected node: "..selected_node)
    print(string.rep("=", 50))
    
    if args.execute then
        print("\n🚀 Executing on "..selected_node.."...")
        -- TODO: Implement remote execution
        print("(Remote execution not yet implemented)")
    else
        print("\n💡 To execute: "..table.concat(arg, " ").." --execute")
    end
end

main()
