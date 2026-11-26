#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "376ea766163b1c5013f496cb3f8eb551069b006b7aac96d38815de6072745c6f", "source_sha256": "5a841c728d9c1585b5c3191e88fdd38cf887a0d51560ce803b8c0172412bef3d", "target_language": "lua"}
-- check_nodes.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/multi-nodes-utils/scripts/check_nodes.py
-- auch in: OpenClaw@gateway2:skills/multi-nodes-utils/scripts/check_nodes.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[
Node-Status Checker - Prüft Verfügbarkeit aller Nodes
]]

local json = require("cjson")
local socket = require("socket")

-- Node-Konfiguration (sollte aus config file geladen werden)
local NODES = {
    node1 = {
        always_available = true,
        capacity = "medium",
        priority = 2,
        description = "Gateway-Master"
    },
    node2 = {
        always_available = true,
        capacity = "medium",
        priority = 3,
        description = "Stable Worker"
    },
    node3 = {
        always_available = false,
        capacity = "medium",
        priority = 4,
        description = "Bald verfügbar (nach Reorganisation)"
    },
    node5 = {
        always_available = false,
        capacity = "low",
        priority = 5,
        device = "Redmi Note 11S",
        description = "Mobile (bei Internet verfügbar)"
    },
    node7 = {
        always_available = true,
        capacity = "high",
        priority = 1,
        description = "Docker Hauptarbeitspferd (bald verfügbar)"
    },
}

local function execute_command(cmd, timeout)
    local handle = io.popen(cmd .. " 2>&1")
    local result = ""
    
    if handle then
        local start_time = socket.gettime()
        while true do
            local line = handle:read("*l")
            if line == nil then break end
            result = result .. line .. "\n"
            
            if socket.gettime() - start_time > timeout then
                handle:close()
                return false, "timeout"
            end
        end
        local success, _, code = handle:close()
        return success, result, code
    else
        return false, "failed to execute"
    end
end

local function check_node_status(node_id)
    -- Prüft Status eines einzelnen Nodes
    local success, result, exit_code = execute_command("openclaw nodes status " .. node_id, 5)
    
    if not success and result == "timeout" then
        return {
            id = node_id,
            online = false,
            available = NODES[node_id].always_available or false,
            response = "Timeout"
        }
    elseif not success then
        return {
            id = node_id,
            online = false,
            available = NODES[node_id].always_available or false,
            response = "Error: " .. tostring(result)
        }
    else
        local is_online = (exit_code == 0) and (
            string.find(string.lower(result), "online") or 
            string.find(string.lower(result), "active")
        )
        
        local response_text = string.sub(result, 1, 100)
        if response_text == "" then response_text = "No response" end
        
        return {
            id = node_id,
            online = is_online and true or false,
            available = NODES[node_id].always_available or false,
            response = response_text
        }
    end
end

local function print_table(nodes_status)
    -- Gibt Node-Status als Tabelle aus
    print("\n" .. string.rep("=", 90))
    print(string.format("%-8s %-12s %-12s %-10s %-10s %s", "Node", "Status", "Verfügbar", "Kapazität", "Priorität", "Gerät/Beschreibung"))
    print(string.rep("=", 90))
    
    for _, status in ipairs(nodes_status) do
        local node_id = status.id
        local config = NODES[node_id]
        
        local status_icon = status.online and "🟢 Online" or "🔴 Offline"
        local avail_icon = status.available and "✅ Immer" or "📱 Bedingt"
        local capacity = config.capacity or "unknown"
        local priority = config.priority or "-"
        local device = config.device or config.description or ""
        
        print(string.format("%-8s %-12s %-12s %-10s %-10s %s", node_id, status_icon, avail_icon, capacity, priority, device))
    end
    
    print(string.rep("=", 90))
    print("\nGeprüft am: " .. os.date("%Y-%m-%d %H:%M:%S"))
end

local function print_json(nodes_status)
    -- Gibt Node-Status als JSON aus
    local output = {
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        nodes = {}
    }
    
    for _, status in ipairs(nodes_status) do
        local node_id = status.id
        output.nodes[node_id] = {
            status = status,
            config = NODES[node_id]
        }
    end
    
    print(json.encode(output))
end

local function save_to_file(filename, nodes_status)
    local output = {
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        nodes = {}
    }
    
    for _, status in ipairs(nodes_status) do
        output.nodes[status.id] = status
    end
    
    local file = io.open(filename, "w")
    if file then
        file:write(json.encode(output, true))
        file:close()
        return true
    else
        return false
    end
end

local function main()
    -- Simple argument parsing
    local args = {}
    local format_type = "table"
    local save_file = nil
    
    for i = 1, #arg do
        if arg[i] == "--format" or arg[i] == "-f" then
            format_type = arg[i+1] or "table"
        elseif arg[i] == "--save" or arg[i] == "-s" then
            save_file = arg[i+1]
        end
    end
    
    print("🔍 Prüfe Node-Status...")
    
    -- Prüfe alle Nodes
    local nodes_status = {}
    local node_ids = {}
    for id in pairs(NODES) do
        table.insert(node_ids, id)
    end
    table.sort(node_ids)
    
    for _, node_id in ipairs(node_ids) do
        io.write("  → " .. node_id .. "... ")
        io.flush()
        local status = check_node_status(node_id)
        table.insert(nodes_status, status)
        print(status.online and "✓" or "✗")
    end
    
    -- Ausgabe
    if format_type == "table" then
        print_table(nodes_status)
    else
        print_json(nodes_status)
    end
    
    -- Speichern
    if save_file then
        if save_to_file(save_file, nodes_status) then
            print("\n💾 Gespeichert: " .. save_file)
        else
            print("\n❌ Fehler beim Speichern: " .. save_file)
        end
    end
    
    -- Zusammenfassung
    local online_count = 0
    for _, s in ipairs(nodes_status) do
        if s.online then
            online_count = online_count + 1
        end
    end
    print("\n📊 Zusammenfassung: " .. online_count .. "/" .. #nodes_status .. " Nodes online")
end

main()
