#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "d7f1c9ab97f12da06247ad2b663f4666a64acbfdf6a17f265549dd60ae483164", "source_sha256": "0ea45de4496e55f73aa9b10188cc6a04921d74e1cadbe0ac04a948d0f2772243", "target_language": "lua"}
-- node_health.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway2:skills/node-health-monitor/scripts/node_health.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[
Node Health Monitor - Multi-Node Gesundheitsüberwachung
]]

local WORKSPACE = "/home/openclaw/.openclaw/workspace"
local HEALTH_DB = WORKSPACE .. "/db/health.db"
local LOG_FILE = WORKSPACE .. "/logs/node-health.log"

-- Node-Definitionen
local NODES = {
    node1 = {
        name = "Node 1",
        host = "localhost",
        user = "openclaw",
        critical = true
    },
    node2 = {
        name = "Node 2",
        host = "10.10.0.2",
        user = "root",
        ssh_key = "~/.ssh/id_rsa",
        ssh_opts = "-o ConnectTimeout=10 -o BatchMode=yes"
    },
    node3 = {
        name = "Node 3",
        host = "localhost",
        user = "root",
        port = 18794,
        ssh_opts = "-p 18794 -o ConnectTimeout=10 -o BatchMode=yes",
        disk_warning = 85
    },
    node5 = {
        name = "Redmi",
        host = "192.168.1.x",
        user = "openclaw",
        optional = true
    }
}

function log_message(message, level)
    level = level or "INFO"
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local entry = string.format("[%s] [%s] %s", timestamp, level, message)
    print(entry)
    
    local log_dir = string.match(LOG_FILE, "(.-)[^/]*$")
    local dirs = {}
    for dir in string.gmatch(log_dir, "([^/]+)") do
        table.insert(dirs, dir)
    end
    
    local current_path = "/"
    for i, dir in ipairs(dirs) do
        if dir ~= "" then
            current_path = current_path .. dir .. "/"
            os.execute(string.format("mkdir -p %q", current_path))
        end
    end
    
    local file = io.open(LOG_FILE, "a")
    if file then
        file:write(entry .. "\n")
        file:close()
    end
end

function check_ping(host, timeout)
    timeout = timeout or 10
    local success, _, code = os.execute(string.format("ping -c 1 -W %d %q > /dev/null 2>&1", timeout, host))
    return success and code == 0
end

function check_ssh(node_config)
    local host = node_config.host
    local user = node_config.user or "root"
    local ssh_opts = node_config.ssh_opts or ""
    local port = node_config.port
    
    local cmd_parts = {"ssh"}
    if ssh_opts and ssh_opts ~= "" then
        for opt in string.gmatch(ssh_opts, "%S+") do
            table.insert(cmd_parts, opt)
        end
    end
    if port then
        table.insert(cmd_parts, "-p")
        table.insert(cmd_parts, tostring(port))
    end
    table.insert(cmd_parts, "-o")
    table.insert(cmd_parts, "ConnectTimeout=10")
    table.insert(cmd_parts, "-o")
    table.insert(cmd_parts, "BatchMode=yes")
    table.insert(cmd_parts, string.format("%s@%s", user, host))
    table.insert(cmd_parts, "echo")
    table.insert(cmd_parts, '"OK"')
    
    local cmd = table.concat(cmd_parts, " ")
    local handle = io.popen(cmd .. " 2>/dev/null", "r")
    if handle then
        local result = handle:read("*a")
        handle:close()
        return string.find(result or "", "OK") ~= nil
    end
    return false
end

function get_node_metrics(node_config)
    local host = node_config.host
    local user = node_config.user or "root"
    
    local metrics = {
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        available = false,
        cpu = nil,
        ram = nil,
        disk = nil,
        load = nil
    }
    
    local cmd = string.format([[ssh -o ConnectTimeout=10 %s@%s '
        # CPU
        echo "CPU:$(top -bn1 | grep "Cpu(s)" | awk "{print \$2}" | cut -d"%" -f1)"
        
        # RAM
        echo "RAM:$(free | grep Mem | awk "{print (\$3/\$2) * 100.0}")"
        
        # Disk
        echo "DISK:$(df -h / | tail -1 | awk "{print \$5}" | tr -d "%")"
        
        # Load
        echo "LOAD:$(uptime | awk -F"load average:" "{print \$2}" | awk "{print \$1}" | tr -d ",")"
        
        # Gateway Status
        if command -v openclaw >/dev/null 2>&1; then
            systemctl is-active openclaw-gateway 2>/dev/null || echo "GATEWAY:inactive"
        fi
    ']], user, host)
    
    local handle = io.popen(cmd .. " 2>/dev/null", "r")
    if handle then
        local output = handle:read("*a")
        handle:close()
        
        if output and output ~= "" then
            metrics.available = true
            
            for line in string.gmatch(output, "[^\n]+") do
                local key, value = string.match(line, "([^:]+):(.*)")
                if key and value then
                    if key == "CPU" then
                        metrics.cpu = tonumber(value)
                    elseif key == "RAM" then
                        metrics.ram = tonumber(value)
                    elseif key == "DISK" then
                        metrics.disk = tonumber(value)
                    elseif key == "LOAD" then
                        metrics.load = tonumber(value)
                    elseif key == "GATEWAY" then
                        metrics.gateway_status = value
                    end
                end
            end
        end
    end
    
    return metrics
end

function check_alerts(node_id, node_config, metrics)
    local alerts = {}
    
    if not metrics.available then
        if not node_config.optional then
            table.insert(alerts, {
                level = "CRITICAL",
                message = string.format("Node %s nicht erreichbar!", node_config.name)
            })
        end
    else
        if metrics.cpu and metrics.cpu > 90 then
            table.insert(alerts, {
                level = "WARNING",
                message = string.format("Node %s: CPU bei %.1f%%", node_config.name, metrics.cpu)
            })
        end
        
        if metrics.ram and metrics.ram > 90 then
            table.insert(alerts, {
                level = "WARNING",
                message = string.format("Node %s: RAM bei %.1f%%", node_config.name, metrics.ram)
            })
        end
        
        local disk_threshold = node_config.disk_warning or 85
        if metrics.disk and metrics.disk > disk_threshold then
            local level = metrics.disk > 95 and "CRITICAL" or "WARNING"
            table.insert(alerts, {
                level = level,
                message = string.format("Node %s: Disk bei %d%%", node_config.name, metrics.disk)
            })
        end
        
        if node_config.critical and metrics.gateway_status == "inactive" then
            table.insert(alerts, {
                level = "CRITICAL",
                message = string.format("Node %s: OpenClaw Gateway nicht aktiv!", node_config.name)
            })
        end
    end
    
    return alerts
end

function send_alert(alert)
    local cmd = string.format('python3 %q --type alert --message "%s: %s"',
        WORKSPACE .. "/skills/channel-status-agent/scripts/channel_status.py",
        alert.level,
        alert.message)
    
    local success, _, code = os.execute(cmd .. " > /dev/null 2>&1")
    if success and code == 0 then
        log_message(string.format("Alert sent: %s", alert.message))
    else
        log_message(string.format("Failed to send alert: %s", alert.message), "ERROR")
    end
end

function split(str, delimiter)
    local parts = {}
    for part in string.gmatch(str, "[^"..delimiter.."]+") do
        table.insert(parts, part)
    end
    return parts
end

function main()
    local args = {}
    local i = 1
    while i <= #arg do
        if arg[i] == "--node" and i+1 <= #arg then
            args.node = arg[i+1]
            i = i + 2
        elseif arg[i] == "--check" and i+1 <= #arg then
            args.check = arg[i+1]
            i = i + 2
        elseif arg[i] == "--alert" then
            args.alert = true
            i = i + 1
        else
            i = i + 1
        end
    end
    
    args.node = args.node or "all"
    args.check = args.check or "all"
    
    local nodes_to_check = {}
    if args.node == "all" then
        for id, config in pairs(NODES) do
            nodes_to_check[id] = config
        end
    else
        if NODES[args.node] then
            nodes_to_check[args.node] = NODES[args.node]
        else
            log_message(string.format("Unknown node: %s", args.node), "ERROR")
            os.exit(1)
        end
    end
    
    local all_alerts = {}
    
    for node_id, node_config in pairs(nodes_to_check) do
        log_message(string.format("Checking %s (%s)", node_config.name, node_id))
        
        if args.check == "ping" or args.check == "all" then
            if node_config.host ~= "localhost" then
                local ping_ok = check_ping(node_config.host)
                log_message(string.format("  Ping: %s", ping_ok and "OK" or "FAILED"))
            end
        end
        
        if args.check == "ssh" or args.check == "all" then
            local ssh_ok = check_ssh(node_config)
            log_message(string.format("  SSH: %s", ssh_ok and "OK" or "FAILED"))
        end
        
        if args.check == "metrics" or args.check == "all" then
            local metrics = get_node_metrics(node_config)
            
            if metrics.available then
                log_message(string.format("  CPU: %s", metrics.cpu and string.format("%.1f%%", metrics.cpu) or "N/A"))
                log_message(string.format("  RAM: %s", metrics.ram and string.format("%.1f%%", metrics.ram) or "N/A"))
                log_message(string.format("  Disk: %s", metrics.disk and string.format("%d%%", metrics.disk) or "N/A"))
                log_message(string.format("  Load: %s", metrics.load or "N/A"))
            else
                log_message("  Metrics: UNAVAILABLE")
            end
            
            local alerts = check_alerts(node_id, node_config, metrics)
            for _, alert in ipairs(alerts) do
                table.insert(all_alerts, alert)
            end
        end
    end
    
    if args.alert and #all_alerts > 0 then
        log_message(string.format("\nSending %d alerts...", #all_alerts))
        for _, alert in ipairs(all_alerts) do
            send_alert(alert)
        end
    elseif #all_alerts > 0 then
        log_message(string.format("\n%d alerts found (use --alert to send)", #all_alerts))
    else
        log_message("\nAll nodes healthy!")
    end
end

main()
