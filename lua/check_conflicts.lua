#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "96e6e652094574085cbc6e50fca4fd4cd41cb3aabb873423c3a668d9231580c9", "source_sha256": "5d90ebcd250a3cb80a0de664d94397af7ec03343d9d9fa64a28a9a11ad880754", "target_language": "lua"}
-- check_conflicts.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
-- auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
-- Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

--[[
Check Conflicts - Erkennt Sync-Konflikte
]]

local CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills"
local GIT_DIR = "/home/openclaw/.openclaw/workspace/git/skills"

-- Helper function to execute shell commands and return output
local function shell_exec(cmd)
    local handle = io.popen(cmd)
    local result = handle:read("*a")
    handle:close()
    return result
end

-- Function to get file hash (using sha256sum)
local function get_file_hash(filepath)
    local cmd = "sha256sum '" .. filepath .. "' 2>/dev/null | cut -d' ' -f1"
    local hash = shell_exec(cmd)
    return hash:match("^%s*(.-)%s*$") -- trim whitespace
end

-- Function to check if a path exists and is a directory
local function is_directory(path)
    local attr = io.open(path, "r")
    if attr then
        local mode = attr:seek("end")
        attr:close()
        -- This is a simple check; for better accuracy we could use lfs or similar
        -- but sticking to standard libraries as per requirements
        return mode ~= nil
    end
    return false
end

-- Function to list directories in a given path
local function list_directories(base_path)
    local dirs = {}
    local cmd = "find '" .. base_path .. "' -maxdepth 1 -type d -not -path '" .. base_path .. "' 2>/dev/null"
    local handle = io.popen(cmd)
    for line in handle:lines() do
        local dir_name = line:match("([^/]+)$")
        if dir_name and dir_name ~= ".git" then
            dirs[dir_name] = line
        end
    end
    handle:close()
    return dirs
end

-- Function to recursively list files with relative paths
local function list_files_recursive(base_path)
    local files = {}
    local cmd = "find '" .. base_path .. "' -type f -not -path '*/.git/*' 2>/dev/null"
    local handle = io.popen(cmd)
    for line in handle:lines() do
        local rel_path = string.gsub(line, "^" .. base_path .. "/", "")
        files[rel_path] = line
    end
    handle:close()
    return files
end

-- Function to get modification time of a file
local function get_modification_time(filepath)
    local cmd = "stat -c %Y '" .. filepath .. "' 2>/dev/null"
    local timestamp_str = shell_exec(cmd)
    local timestamp = tonumber(timestamp_str)
    if timestamp then
        return os.date("%Y-%m-%d %H:%M:%S", timestamp)
    end
    return "Unknown"
end

-- Main conflict checking logic
local function check_conflicts()
    local conflicts = {}

    -- Get skills from both locations
    local clawhub_skills = list_directories(CLAWHUB_DIR)
    local git_skills = list_directories(GIT_DIR)

    -- Find common skills
    local common_skills = {}
    for name, _ in pairs(clawhub_skills) do
        if git_skills[name] then
            table.insert(common_skills, name)
        end
    end

    table.sort(common_skills)

    print("Prüfe " .. #common_skills .. " Skills auf Konflikte...\n")

    for _, skill in ipairs(common_skills) do
        local clawhub_path = clawhub_skills[skill]
        local git_path = git_skills[skill]

        local skill_conflicts = {}

        -- List files in each location
        local clawhub_files = list_files_recursive(clawhub_path)
        local git_files = list_files_recursive(git_path)

        -- Compare common files
        local common_files = {}
        for rel_path, _ in pairs(clawhub_files) do
            if git_files[rel_path] then
                table.insert(common_files, rel_path)
            end
        end

        for _, rel_path in ipairs(common_files) do
            local clawhub_file = clawhub_files[rel_path]
            local git_file = git_files[rel_path]

            local clawhub_hash = get_file_hash(clawhub_file)
            local git_hash = get_file_hash(git_file)

            if clawhub_hash ~= git_hash then
                local clawhub_mtime = get_modification_time(clawhub_file)
                local git_mtime = get_modification_time(git_file)

                -- Determine which is newer (simple string comparison here)
                local newer = "unknown"
                if clawhub_mtime > git_mtime then
                    newer = "clawhub"
                elseif git_mtime > clawhub_mtime then
                    newer = "git"
                end

                table.insert(skill_conflicts, {
                    file = rel_path,
                    clawhub_modified = clawhub_mtime,
                    git_modified = git_mtime,
                    newer = newer
                })
            end
        end

        if #skill_conflicts > 0 then
            table.insert(conflicts, {
                skill = skill,
                conflicts = skill_conflicts
            })
        end
    end

    -- Output results
    if #conflicts > 0 then
        print("⚠️  KONFLIKTE GEFUNDEN:")
        print(string.rep("=", 80))

        for _, conflict in ipairs(conflicts) do
            print("\n📦 Skill: " .. conflict.skill)
            print(string.rep("-", 40))

            for _, file_conflict in ipairs(conflict.conflicts) do
                print("  📄 " .. file_conflict.file)
                print("     ClawHub: " .. file_conflict.clawhub_modified)
                print("     Git:     " .. file_conflict.git_modified)
                print("     Neuer:   " .. file_conflict.newer:upper())
                print()
            end
        end

        print(string.rep("=", 80))
        print("Gesamt: " .. #conflicts .. " Skills mit Konflikten")
        print("\nNutze 'sync_utils/scripts/resolve_conflict.py' zum Auflösen.")
    else
        print("✅ Keine Konflikte gefunden!")
        print("Alle gemeinsamen Skills sind synchron.")
    end
end

-- Main function
local function main()
    check_conflicts()
end

-- Run main function
main()
