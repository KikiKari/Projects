#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "d008558eb9645e5b6998474a212ed0391c92620208601450c1982b883fc78e14", "source_sha256": "5081f9f0745ca8b2223c2de657aa97d48e58ccf61c24467e46c9d562803e34a6", "target_language": "lua"}
-- log_collector.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/log-collector/scripts/log_collector.py
-- auch in: OpenClaw@gateway2:skills/log-collector/scripts/log_collector.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[
Log Collector Sub-Agent
Sammelt Logs von allen Nodes via SSH/VPN alle 3 Stunden
]]

local sqlite3 = require("lsqlite3")
local posix = require("posix")

-- Hilfsfunktionen fuer Pfade und Zeit
local function join_paths(...)
    local t = {...}
    return table.concat(t, "/")
end

local function current_date_str()
    return os.date("%Y-%m-%d")
end

local function iso_time()
    return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local WORKSPACE = "/home/openclaw/.openclaw/workspace"
local DB_PATH = join_paths(WORKSPACE, "db", "logs.db")
local LOG_DIR = join_paths(WORKSPACE, "logs", "log-collector")

-- Stelle sicher das Log-Verzeichnis existiert
posix.mkdir(LOG_DIR, tonumber("755", 8))

-- Logger Klasse
local Logger = {}
Logger.__index = Logger

function Logger:new()
    local obj = {
        log_file = join_paths(LOG_DIR, current_date_str() .. ".log")
    }
    setmetatable(obj, Logger)
    return obj
end

function Logger:log(level, msg)
    local ts = iso_time()
    local line = string.format("[%s] [%s] %s", ts, level, msg)
    print(line)
    local f = io.open(self.log_file, "a")
    if f then
        f:write(line .. "\n")
        f:close()
    end
end

function Logger:info(msg) self:log('INFO', msg) end
function Logger:error(msg) self:log('ERROR', msg) end


-- LogCollector Klasse
local LogCollector = {}
LogCollector.__index = LogCollector

function LogCollector:new()
    local obj = {
        logger = Logger:new(),
        conn = nil
    }
    setmetatable(obj, LogCollector)
    return obj
end

function LogCollector:connect_db()
    self.conn = sqlite3.open(DB_PATH)
    -- Initialisiere Schema falls noetig
    self:_init_schema()
    return self.conn
end

function LogCollector:_init_schema()
    local stmt = self.conn:prepare("SELECT name FROM sqlite_master WHERE type='table'")
    local exists = false
    for row in stmt:nrows() do
        exists = true
        break
    end
    stmt:reset()

    if not exists then
        local schema_path = join_paths(WORKSPACE, "db", "logs.db.schema.sql")
        local f = io.open(schema_path, "r")
        if f then
            local schema_sql = f:read("*all")
            f:close()
            self.conn:exec(schema_sql)
            self.conn:commit()
        end
    end
end

function LogCollector:get_nodes()
    local nodes = {}
    local stmt = self.conn:prepare("SELECT * FROM nodes")
    for row in stmt:nrows() do
        table.insert(nodes, row)
    end
    stmt:reset()
    return nodes
end

function LogCollector:check_vpn(ip)
    local handle = io.popen(string.format("ping -c 1 -W 3 %s 2>/dev/null", ip))
    local result = handle:read("*a")
    local success, _, code = handle:close()
    return success and code == 0
end

function LogCollector:ssh_connect_and_collect(node)
    local node_id = node.node_id
    local vpn_ip = node.vpn_ip or node.tailscale_ip or node.wireguard_ip

    if not vpn_ip then
        self.logger:error(node_id .. ": Keine VPN-IP konfiguriert")
        return nil
    end

    -- 1. VPN-Check
    self.logger:info(node_id .. ": Pruefe VPN " .. vpn_ip .. "...")
    if not self:check_vpn(vpn_ip) then
        self.logger:error(node_id .. ": VPN nicht erreichbar")
        self:_log_ssh_connection(node_id, 'tailscale', false, 'VPN unreachable')
        return nil
    end

    -- 2. SSH-Verbindung
    self.logger:info(node_id .. ": Verbinde via SSH...")
    local logs_collected = {}

    local commands = {
        "journalctl -n 500 --no-pager",
        "tail -n 200 /var/log/syslog 2>/dev/null || echo 'no syslog'",
        "tail -n 200 ~/.openclaw/logs/*.log 2>/dev/null || echo 'no openclaw logs'"
    }

    for _, cmd in ipairs(commands) do
        local full_cmd = string.format("ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no openclaw@%s '%s'", vpn_ip, cmd)
        local handle = io.popen(full_cmd)
        if handle then
            local output = handle:read("*a")
            local success, _, code = handle:close()
            if success and code == 0 then
                table.insert(logs_collected, {
                    command = cmd,
                    output = output,
                    timestamp = iso_time()
                })
            end
        end
    end

    -- Erfolg loggen
    self:_log_ssh_connection(node_id, 'ssh', true, nil)

    -- In DB speichern
    self:_insert_logs(node_id, logs_collected)

    return #logs_collected
end

function LogCollector:_log_ssh_connection(node_id, conn_type, success, error_msg)
    local stmt = self.conn:prepare([[
        INSERT INTO ssh_connections (node_id, connection_type, success, error_message)
        VALUES (?, ?, ?, ?)
    ]])
    stmt:bind_values(node_id, conn_type, success and 1 or 0, error_msg)
    stmt:step()
    stmt:reset()
    self.conn:commit()
end

function LogCollector:_insert_logs(node_id, logs)
    local stmt = self.conn:prepare([[
        INSERT INTO logs (node_id, log_type, source, content, severity, 
                         collected_by, collection_method, retention_until)
        VALUES (?, 'system', ?, ?, 'info', ?, 'ssh', ?)
    ]])

    local retention = os.time() + (30 * 24 * 60 * 60) -- 30 Tage in Sekunden

    for _, log_entry in ipairs(logs) do
        local source = string.sub(log_entry.command, 1, 50)
        local content = string.sub(log_entry.output, 1, 10000)
        stmt:bind_values(node_id, source, content, 'node1', os.date("!%Y-%m-%dT%H:%M:%SZ", retention))
        stmt:step()
        stmt:reset()
    end

    self.conn:commit()
    self.logger:info(node_id .. ": " .. #logs .. " Log-Eintraege gespeichert")
end

function LogCollector:cleanup_retention()
    local stmt = self.conn:prepare([[
        DELETE FROM logs WHERE retention_until < datetime('now')
    ]])
    stmt:step()
    local deleted = self.conn:changes()
    stmt:reset()
    self.conn:commit()
    self.logger:info("Retention-Cleanup: " .. deleted .. " alte Logs geloescht")
    return deleted
end

function LogCollector:run_collection_cycle()
    self.logger:info(string.rep("=", 60))
    self.logger:info("LOG COLLECTOR CYCLE START")
    self.logger:info(string.rep("=", 60))

    self:connect_db()

    -- 1. Nodes holen
    local nodes = self:get_nodes()
    self.logger:info("Gefunden: " .. #nodes .. " Nodes")

    -- 2. Collection-Run starten
    local stmt_insert_run = self.conn:prepare([[
        INSERT INTO collection_runs (started_at, nodes_total)
        VALUES (CURRENT_TIMESTAMP, ?)
    ]])
    stmt_insert_run:bind_values(#nodes)
    stmt_insert_run:step()
    local run_id = self.conn:last_insert_rowid()
    stmt_insert_run:reset()
    self.conn:commit()

    -- 3. Fuer jeden Node sammeln
    local success_count = 0
    local failed_count = 0
    local total_logs = 0

    for _, node in ipairs(nodes) do
        if node.node_id == 'node1' then
            -- Lokale Logs (Gateway selbst)
            self.logger:info("node1: Lokale Collection (Gateway)")
            success_count = success_count + 1
        else
            -- Remote-Node abfragen
            local result = self:ssh_connect_and_collect(node)
            if result ~= nil then
                success_count = success_count + 1
                total_logs = total_logs + result
            else
                failed_count = failed_count + 1
            end
        end
    end

    -- 4. Run abschliessen
    local stmt_update_run = self.conn:prepare([[
        UPDATE collection_runs SET
            finished_at = CURRENT_TIMESTAMP,
            nodes_success = ?,
            nodes_failed = ?,
            logs_collected = ?
        WHERE run_id = ?
    ]])
    stmt_update_run:bind_values(success_count, failed_count, total_logs, run_id)
    stmt_update_run:step()
    stmt_update_run:reset()
    self.conn:commit()

    -- 5. Retention-Cleanup
    self.logger:info("Retention-Cleanup (30 Tage)...")
    self:cleanup_retention()

    self.logger:info(string.rep("=", 60))
    self.logger:info(string.format("SUMMARY: %d OK, %d Failed, %d Logs", success_count, failed_count, total_logs))
    self.logger:info(string.rep("=", 60))
end


-- Hauptprogramm
function main()
    print(string.rep("=", 60))
    print("LOG COLLECTOR")
    print(string.rep("=", 60))

    local collector = LogCollector:new()

    local status, err = pcall(function()
        collector:run_collection_cycle()
    end)

    if not status then
        print("CRITICAL ERROR: " .. tostring(err))
        os.exit(1)
    end
end

main()
