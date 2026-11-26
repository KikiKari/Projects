#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "0fa0d5331d1a07e285e51368768a4047adc66349e744403fb29f9676d56007f2", "source_sha256": "3ee904e4ee842489bd9bef8522f5a93fc06583e6cb1c3c5243afae19a4e2ed5f", "target_language": "lua"}
-- db_maintainer.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/db_maintainer.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[
Database Maintainer Sub-Agent
Automated database maintenance with 30min checks, hourly backups (3 days retention),
band tree command execution for important/openclaw-tree.txt
]]

local sqlite3 = require("lsqlite3")
local json = require("cjson")
local posix = require("posix")
local lfs = require("lfs")

local WORKSPACE = "/home/openclaw/.openclaw/workspace"
local DB_DIR = WORKSPACE .. "/db"
local BACKUP_DIR = DB_DIR .. "/backups"
local LOG_DIR = WORKSPACE .. "/logs/db-maintainer"
local IMPORTANT_DIR = WORKSPACE .. "/important"

-- Create directories
posix.mkdir(BACKUP_DIR)
posix.mkdir(LOG_DIR)

Logger = {}
Logger.__index = Logger

function Logger:new()
    local obj = {
        log_file = LOG_DIR .. "/" .. os.date("%Y-%m-%d") .. ".log"
    }
    setmetatable(obj, Logger)
    return obj
end

function Logger:log(level, message)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local line = string.format("[%s] [%s] %s", timestamp, level, message)
    print(line)
    local file = io.open(self.log_file, "a")
    if file then
        file:write(line .. "\n")
        file:close()
    end
end

function Logger:info(msg) self:log("INFO", msg) end
function Logger:warn(msg) self:log("WARN", msg) end
function Logger:error(msg) self:log("ERROR", msg) end

DatabaseMaintainer = {}
DatabaseMaintainer.__index = DatabaseMaintainer

function DatabaseMaintainer:new()
    local obj = {
        logger = Logger:new(),
        state_file = DB_DIR .. "/maintainer_state.json",
        retention_days = 3
    }
    setmetatable(obj, DatabaseMaintainer)
    return obj
end

function DatabaseMaintainer:load_state()
    local file = io.open(self.state_file, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local ok, state = pcall(json.decode, content)
        if ok then
            return state
        end
    end
    return {last_check = nil, last_backup = nil, last_tree_update = nil, file_hashes = {}}
end

function DatabaseMaintainer:save_state(state)
    local file = io.open(self.state_file, "w")
    if file then
        file:write(json.encode(state))
        file:close()
    end
end

function DatabaseMaintainer:get_file_hash(filepath)
    local file = io.open(filepath, "rb")
    if not file then return nil end
    
    local content = file:read("*all")
    file:close()
    
    local hash = require("openssl").digest.new("md5")
    hash:update(content)
    return hash:final()
end

function DatabaseMaintainer:run_tree_command()
    local handle = io.popen(string.format("timeout 60 tree -a -L 8 %s 2>/dev/null", WORKSPACE))
    if not handle then
        self.logger:error("Failed to execute tree command")
        return nil
    end
    
    local result = handle:read("*all")
    local success, _, retcode = handle:close()
    
    if success and retcode == 0 then
        self.logger:info("tree -a -L 8 executed successfully")
        return result
    else
        self.logger:error("tree command failed")
        return nil
    end
end

function DatabaseMaintainer:update_tree_file(tree_output)
    if not tree_output then
        return false
    end
    
    local tree_file = IMPORTANT_DIR .. "/openclaw-tree.txt"
    local file = io.open(tree_file, "w")
    if not file then
        self.logger:error("Failed to open tree file for writing")
        return false
    end
    
    local header = string.format([[
# OpenClaw Workspace Tree
# Generated: %s
# Command: tree -a -L 8 %s
# This file is automatically updated by db-maintainer

]], os.date("!%Y-%m-%dT%H:%M:%SZ"), WORKSPACE)
    
    file:write(header)
    file:write(tree_output)
    file:close()
    
    self.logger:info("openclaw-tree.txt updated: " .. tree_file)
    return true
end

function DatabaseMaintainer:scan_documentations()
    local docs = {}
    
    local function scan_directory(dir)
        for file in lfs.dir(dir) do
            if file ~= "." and file ~= ".." then
                local path = dir .. "/" .. file
                local attr = lfs.attributes(path)
                
                if attr.mode == "directory" then
                    scan_directory(path)
                elseif string.match(file, "%.md$") then
                    if not string.find(path, "db/backups") and not string.find(path, "node_modules") then
                        local rel_path = string.gsub(path, "^" .. WORKSPACE .. "/", "")
                        table.insert(docs, {
                            path = rel_path,
                            hash = self:get_file_hash(path),
                            mtime = attr.modification
                        })
                    end
                end
            end
        end
    end
    
    scan_directory(WORKSPACE)
    return docs
end

function DatabaseMaintainer:check_for_changes()
    local state = self:load_state()
    local current_docs = self:scan_documentations()
    
    local changes = {}
    local current_hashes = {}
    
    for _, doc in ipairs(current_docs) do
        local path = doc.path
        current_hashes[path] = doc.hash
        
        if not state.file_hashes[path] then
            table.insert(changes, "NEW: " .. path)
        elseif state.file_hashes[path] ~= doc.hash then
            table.insert(changes, "CHANGED: " .. path)
        end
    end
    
    for old_path, _ in pairs(state.file_hashes) do
        if not current_hashes[old_path] then
            table.insert(changes, "DELETED: " .. old_path)
        end
    end
    
    return changes, current_hashes
end

function DatabaseMaintainer:update_databases()
    local handle = io.popen(string.format("timeout 60 python3 %s/scripts/update_docs_db.py 2>&1", WORKSPACE))
    if not handle then
        self.logger:error("Failed to execute update_docs_db.py")
        return false
    end
    
    local result = handle:read("*all")
    local success, _, retcode = handle:close()
    
    if success and retcode == 0 then
        self.logger:info("docs.db updated")
        return true
    else
        self.logger:error("DB update failed: " .. result)
        return false
    end
end

function DatabaseMaintainer:update_tree_db_v2()
    local handle = io.popen(string.format("timeout 120 python3 %s/scripts/tree_indexer_v2.py 2>&1", WORKSPACE))
    if not handle then
        self.logger:error("Failed to execute tree_indexer_v2.py")
        return false
    end
    
    local result = handle:read("*all")
    local success, _, retcode = handle:close()
    
    if success and retcode == 0 then
        self.logger:info("tree.db v2 updated")
        return true
    else
        self.logger:error("Tree-DB v2 failed: " .. result)
        return false
    end
end

function DatabaseMaintainer:create_backup()
    local timestamp = os.date("%Y-%m-%d_%H-%M")
    
    for _, db_name in ipairs({"docs.db", "tree.db"}) do
        local source = DB_DIR .. "/" .. db_name
        local attr = lfs.attributes(source)
        if attr then
            local backup_name = timestamp .. "_" .. db_name .. ".bak"
            local backup_path = BACKUP_DIR .. "/" .. backup_name
            
            local src = io.open(source, "rb")
            local dst = io.open(backup_path, "wb")
            
            if src and dst then
                local content = src:read("*all")
                dst:write(content)
                src:close()
                dst:close()
                self.logger:info("Backup created: " .. backup_name)
            else
                if src then src:close() end
                if dst then dst:close() end
                self.logger:error("Failed to create backup: " .. backup_name)
            end
        end
    end
    
    return timestamp
end

function DatabaseMaintainer:cleanup_old_backups()
    local cutoff = os.time() - (self.retention_days * 24 * 60 * 60)
    local deleted = 0
    
    for _, db_name in ipairs({"docs.db", "tree.db"}) do
        local pattern = BACKUP_DIR .. "/*_" .. db_name .. ".bak"
        local files = {}
        
        -- Find matching files
        local handle = io.popen("ls " .. pattern .. " 2>/dev/null")
        if handle then
            for filename in handle:lines() do
                table.insert(files, filename)
            end
            handle:close()
        end
        
        for _, backup in ipairs(files) do
            local basename = string.match(backup, "([^/]+)$")
            local parts = {}
            for part in string.gmatch(basename, "[^_]+") do
                table.insert(parts, part)
            end
            
            if #parts >= 2 then
                local date_part = parts[1]
                local time_part = string.gsub(parts[2], "%.bak$", "")
                
                local success, backup_time = pcall(function()
                    return os.time({
                        year = tonumber(string.sub(date_part, 1, 4)),
                        month = tonumber(string.sub(date_part, 6, 7)),
                        day = tonumber(string.sub(date_part, 9, 10)),
                        hour = tonumber(string.sub(time_part, 1, 2)),
                        min = tonumber(string.sub(time_part, 4, 5)),
                        sec = 0
                    })
                end)
                
                if success and backup_time < cutoff then
                    os.remove(backup)
                    deleted = deleted + 1
                    self.logger:info("Deleted old backup: " .. basename)
                end
            else
                self.logger:warn("Could not parse backup date: " .. basename)
            end
        end
    end
    
    if deleted == 0 then
        self.logger:info("No old backups to delete")
    else
        self.logger:info(deleted .. " old backups deleted (< 3 days)")
    end
end

function DatabaseMaintainer:run_cycle()
    self.logger:info(string.rep("=", 60))
    self.logger:info("DB MAINTAINER CYCLE START")
    self.logger:info(string.rep("=", 60))
    
    local state = self:load_state()
    
    -- 1. Run tree command and write to openclaw-tree.txt
    self.logger:info("Running tree -a -L 8...")
    local tree_output = self:run_tree_command()
    if tree_output then
        self:update_tree_file(tree_output)
        state.last_tree_update = os.date("!%Y-%m-%dT%H:%M:%SZ")
    end
    
    -- 2. Update tree.db (internal v2)
    self.logger:info("Updating tree.db v2...")
    self:update_tree_db_v2()
    
    -- 3. Check for changes
    self.logger:info("Checking for documentation changes...")
    local changes, current_hashes = self:check_for_changes()
    
    if #changes > 0 then
        self.logger:info(#changes .. " changes found:")
        for i = 1, math.min(10, #changes) do
            self.logger:info("  - " .. changes[i])
        end
        if #changes > 10 then
            self.logger:info("  ... and " .. (#changes - 10) .. " more")
        end
        
        -- 4. Update docs.db
        self.logger:info("Updating docs.db...")
        if self:update_databases() then
            state.last_check = os.date("!%Y-%m-%dT%H:%M:%SZ")
            state.file_hashes = current_hashes
        end
    else
        self.logger:info("No documentation changes found")
    end
    
    -- 5. Check if backup is due (hourly)
    local last_backup = state.last_backup
    local do_backup = false
    
    if last_backup then
        local last_backup_time = os.time()
        local current_time = os.time()
        do_backup = (current_time - last_backup_time) >= 3600  -- 1 hour
    else
        do_backup = true
    end
    
    if do_backup then
        self.logger:info("Creating hourly backup...")
        local timestamp = self:create_backup()
        state.last_backup = os.date("!%Y-%m-%dT%H:%M:%SZ")
        
        -- 6. Cleanup old backups (3 days retention)
        self.logger:info("Cleaning up old backups (3 days retention)...")
        self:cleanup_old_backups()
    else
        self.logger:info("Backup not needed (last < 1h)")
    end
    
    self:save_state(state)
    
    self.logger:info(string.rep("=", 60))
    self.logger:info("DB MAINTAINER CYCLE END")
    self.logger:info(string.rep("=", 60))
end

function main()
    local maintainer = DatabaseMaintainer:new()
    
    local success, err = pcall(function()
        maintainer:run_cycle()
    end)
    
    if not success then
        maintainer.logger:error("CRITICAL ERROR: " .. tostring(err))
        os.exit(1)
    end
end

main()
