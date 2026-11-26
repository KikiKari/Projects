#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "f6f48293e874053a5fb0e627ec5078a1058fbf5cdbea99b558e71273eb9a4d0d", "source_sha256": "dfe62418dcbef9ea8aa7f18ada4f57d0ef73593432b7c7cefd85ee87eee622b4", "target_language": "lua"}
-- github_publisher.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/github_publisher.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[Publish queued, provenance-checked artifacts without staging unrelated files.]]

local json = require("cjson")
local openssl = require("openssl")
local https = require("ssl.https")
local ltn12 = require("ltn12")
local mime = require("mime")
local socket = require("socket")

-- Helper functions for filesystem operations
local function read_file(path)
    local file = io.open(path, "rb")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content
end

local function write_file(path, content)
    local file = io.open(path, "wb")
    if not file then return false end
    file:write(content)
    file:close()
    return true
end

local function file_exists(path)
    local attr = lfs.attributes(path)
    return attr and attr.mode == "file"
end

local function dir_exists(path)
    local attr = lfs.attributes(path)
    return attr and attr.mode == "directory"
end

local function sha256_hex(data)
    local hash = openssl.digest.new("sha256")
    hash:update(data)
    return hash:final():gsub(".", function(c)
        return string.format("%02x", string.byte(c))
    end)
end

local LANGUAGES = {
    perl5 = true, powershell = true, perl6 = true, tcl = true,
    javascript = true, ruby = true, python = true, lua = true,
    shell = true, go = true, java = true, c = true, cpp = true,
    php = true, fsharp = true, css = true
}

local function get_languages_list()
    local list = {}
    for lang in pairs(LANGUAGES) do
        table.insert(list, lang)
    end
    table.sort(list)
    return list
end

local function run_command(cmd, timeout)
    local handle = io.popen(cmd .. " 2>/dev/null")
    if not handle then
        error("Failed to execute command: " .. cmd)
    end
    
    local result = handle:read("*a")
    local success, _, code = handle:close()
    
    if not success then
        error("Command failed with exit code: " .. tostring(code))
    end
    
    return result
end

function synchronize_checkout(root, remote, branch)
    remote = remote or "https://github.com/KikiKari/OpenClaw.git"
    branch = branch or "gateway1-abstractions"
    
    -- Create temporary directory
    local tmp = os.tmpname()
    os.remove(tmp)
    lfs.mkdir(tmp)
    
    local snapshot = tmp .. "/repo"
    
    -- Clone repository
    local clone_cmd = string.format(
        "git clone --quiet --depth=1 --single-branch --branch %s -- %s %s",
        branch, remote, snapshot
    )
    
    local success, err = pcall(function()
        run_command(clone_cmd, 300)
    end)
    
    if not success then
        os.execute("rm -rf " .. tmp)
        error("Failed to clone repository: " .. tostring(err))
    end
    
    -- Get revision
    local rev_cmd = string.format("git -C %s rev-parse HEAD", snapshot)
    local revision = run_command(rev_cmd, 30):gsub("^%s*(.-)%s*$", "%1")
    
    local counts = {}
    
    for _, language in ipairs(get_languages_list()) do
        local source = snapshot .. "/" .. language
        local target = root .. "/" .. language
        
        -- Check if directories exist and are not symlinks
        if lfs.attributes(source, "mode") == "link" or lfs.attributes(target, "mode") == "link" then
            os.execute("rm -rf " .. tmp)
            error("language directory is a symlink")
        end
        
        -- Create target directory
        if not dir_exists(target) then
            lfs.mkdir(target)
        end
        
        -- Get known files checksums
        local known = {}
        for file in lfs.dir(target) do
            if file ~= "." and file ~= ".." then
                local filepath = target .. "/" .. file
                if file_exists(filepath) and lfs.attributes(filepath, "mode") ~= "link" then
                    local data = read_file(filepath)
                    if data then
                        known[sha256_hex(data)] = true
                    end
                end
            end
        end
        
        -- Process source files
        local files = {}
        if dir_exists(source) then
            for file in lfs.dir(source) do
                if file ~= "." and file ~= ".." then
                    local filepath = source .. "/" .. file
                    if lfs.attributes(filepath, "mode") == "link" or not file_exists(filepath) then
                        os.execute("rm -rf " .. tmp)
                        error("invalid remote abstraction")
                    end
                    table.insert(files, file)
                end
            end
            table.sort(files)
        end
        
        counts[language] = #files
        
        for _, item in ipairs(files) do
            local filepath = source .. "/" .. item
            local data = read_file(filepath)
            if not data then
                os.execute("rm -rf " .. tmp)
                error("Failed to read file: " .. filepath)
            end
            
            local digest = sha256_hex(data)
            if not known[digest] then
                local destination = target .. "/" .. item
                if file_exists(destination) or lfs.attributes(destination, "mode") == "link" then
                    local ext = ""
                    local dot = string.find(item, "%.")
                    if dot then
                        ext = string.sub(item, dot)
                        item = string.sub(item, 1, dot - 1)
                    end
                    destination = target .. "/" .. item .. "__pool_" .. digest .. ext
                end
                
                local success_write = write_file(destination, data)
                if not success_write then
                    if lfs.attributes(destination, "mode") == "link" or 
                       not file_exists(destination) or 
                       read_file(destination) ~= data then
                        os.execute("rm -rf " .. tmp)
                        error("local abstraction conflict")
                    end
                end
                known[digest] = true
            end
        end
    end
    
    os.execute("rm -rf " .. tmp)
    return revision, counts
end

function update_status_counts(path, revision, counts)
    local content = read_file(path)
    if not content then
        error("Failed to read STATUS.md")
    end
    
    local rows = {
        "## Bestand", "", 
        "GitHub-Stand: `" .. revision .. "`", "",
        "| Zielsprache | Dateien |", 
        "|---|---:|"
    }
    
    local total = 0
    for _, language in ipairs(get_languages_list()) do
        local count = counts[language] or 0
        table.insert(rows, "| " .. language .. " | " .. count .. " |")
        total = total + count
    end
    
    table.insert(rows, "| **gesamt** | **" .. total .. "** |")
    table.insert(rows, "")
    table.insert(rows, "")
    
    local new_content = table.concat(rows, "\n")
    
    -- Replace the section using pattern matching
    local pattern = "## Bestand\n.-\n## Quellen"
    content = string.gsub(content, pattern, new_content .. "## Quellen", 1)
    
    if not write_file(path, content) then
        error("Failed to write updated STATUS.md")
    end
end

function queue_artifact(state, root, path)
    -- Normalize paths
    local abs_path = path
    local relative_path = path:gsub("^" .. root .. "/", "")
    
    -- Check if it's a symlink
    if lfs.attributes(abs_path, "mode") == "link" then
        error("artifact must not be a symlink")
    end
    
    -- Validate path is within language directory
    if relative_path ~= "STATUS.md" then
        local parts = {}
        for part in string.gmatch(relative_path, "[^/]+") do
            table.insert(parts, part)
        end
        if #parts == 0 or not LANGUAGES[parts[1]] then
            error("artifact is outside a language directory")
        end
    end
    
    -- Read file and calculate hash
    local data = read_file(abs_path)
    if not data then
        error("failed to read artifact file")
    end
    
    local hash = sha256_hex(data)
    
    -- Initialize queue if needed
    if not state.ausstehende_veroeffentlichungen then
        state.ausstehende_veroeffentlichungen = {}
    end
    
    state.ausstehende_veroeffentlichungen[relative_path] = hash
end

function publish_pending(root, state, save, token, opener, sync)
    opener = opener or function(req)
        return https.request(req)
    end
    
    local pending = state.ausstehende_veroeffentlichungen or {}
    
    -- Validate pending is a table
    if type(pending) ~= "table" then
        error("invalid publication queue")
    end
    
    -- Early return if nothing to do
    local has_pending = false
    for _ in pairs(pending) do
        has_pending = true
        break
    end
    
    if not has_pending and sync == nil then
        return true
    end
    
    if not token or token:match("^%s*$") then
        return false
    end
    
    local headers = {
        Authorization = "Bearer " .. token:match("^%s*(.-)%s*$"),
        Accept = "application/vnd.github+json",
        ["X-GitHub-Api-Version"] = "2022-11-28",
        ["User-Agent"] = "abstractions-manager"
    }
    
    local success = true
    
    -- Sort entries to put STATUS.md last
    local entries = {}
    for name, expected in pairs(pending) do
        table.insert(entries, {name = name, expected = expected})
    end
    
    table.sort(entries, function(a, b)
        if a.name == "STATUS.md" and b.name ~= "STATUS.md" then
            return false
        elseif b.name == "STATUS.md" and a.name ~= "STATUS.md" then
            return true
        else
            return a.name < b.name
        end
    end)
    
    local synced = false
    
    for _, entry in ipairs(entries) do
        local name = entry.name
        local expected = entry.expected
        
        local function process_entry()
            local path = root .. "/" .. name
            
            -- Check if path is valid
            if lfs.attributes(path, "mode") == "link" then
                error("invalid queued path")
            end
            
            -- Read file data
            local data = read_file(path)
            if not data then
                error("failed to read queued file")
            end
            
            -- Verify hash matches
            if sha256_hex(data) ~= expected then
                error("queued artifact changed")
            end
            
            -- Handle STATUS.md synchronization
            if name == "STATUS.md" and sync ~= nil then
                if not success then
                    error("artifact publication incomplete")
                end
                
                local revision, counts = sync(root)
                synced = true
                update_status_counts(path, revision, counts)
                
                data = read_file(path)
                if not data then
                    error("failed to read updated STATUS.md")
                end
                
                expected = sha256_hex(data)
                pending[name] = expected
                save(state)
            end
            
            local function lookup(remote_name)
                local endpoint = "https://api.github.com/repos/KikiKari/OpenClaw/contents/" .. 
                                remote_name:gsub("([^A-Za-z0-9/_-])", function(c)
                                    return string.format("%%%02X", string.byte(c))
                                end)
                
                local req = {
                    url = endpoint .. "?ref=gateway1-abstractions",
                    headers = headers,
                    method = "GET"
                }
                
                local response_body = {}
                req.sink = ltn12.sink.table(response_body)
                
                local ok, code, headers_resp, status = https.request(req)
                
                if not ok or code == 404 then
                    return endpoint, nil
                elseif not ok then
                    error("HTTP request failed: " .. tostring(status))
                end
                
                local response_data = table.concat(response_body)
                if response_data and response_data ~= "" then
                    return endpoint, json.decode(response_data)
                end
                
                return endpoint, nil
            end
            
            local function same(existing)
                return existing and 
                       type(existing) == "table" and 
                       existing.encoding == "base64" and
                       mime.unb64(existing.content or "") == data
            end
            
            local endpoint, existing = lookup(name)
            
            if name == "STATUS.md" and existing and not same(existing) then
                local sha = type(existing) == "table" and existing.sha or nil
                if type(sha) ~= "string" or sha == "" then
                    error("missing remote status version")
                end
                
                local body_data = {
                    message = "Update abstraction status",
                    branch = "gateway1-abstractions",
                    content = mime.b64(data),
                    sha = sha
                }
                
                local body_json = json.encode(body_data)
                
                local req = {
                    url = endpoint,
                    headers = headers,
                    method = "PUT",
                    source = ltn12.source.string(body_json)
                }
                
                local response_body = {}
                req.sink = ltn12.sink.table(response_body)
                
                local ok, code, headers_resp, status = https.request(req)
                if not ok then
                    error("Failed to update STATUS.md: " .. tostring(status))
                end
                
            elseif existing and not same(existing) then
                -- Handle conflicts by creating alternate filename
                local candidate_parts = {}
                for part in string.gmatch(name, "[^/]+") do
                    table.insert(candidate_parts, part)
                end
                
                local candidate_name = candidate_parts[#candidate_parts]
                local candidate_dir = ""
                for i = 1, #candidate_parts - 1 do
                    candidate_dir = candidate_dir .. candidate_parts[i] .. "/"
                end
                
                local ext = ""
                local basename = candidate_name
                local dot = string.find(candidate_name, "%.")
                if dot then
                    ext = string.sub(candidate_name, dot)
                    basename = string.sub(candidate_name, 1, dot - 1)
                end
                
                local alternate = candidate_dir .. basename .. "_" .. string.sub(expected, 1, 12) .. ext
                endpoint, existing = lookup(alternate)
                
                if existing and not same(existing) then
                    error("remote artifact conflict")
                end
            end
            
            if not existing then
                local body_data = {
                    message = "Publish script abstraction",
                    branch = "gateway1-abstractions",
                    content = mime.b64(data)
                }
                
                local body_json = json.encode(body_data)
                
                local req = {
                    url = endpoint,
                    headers = headers,
                    method = "PUT",
                    source = ltn12.source.string(body_json)
                }
                
                local response_body = {}
                req.sink = ltn12.sink.table(response_body)
                
                local ok, code, headers_resp, status = https.request(req)
                if not ok then
                    error("Failed to publish file: " .. tostring(status))
                end
            end
            
            -- Remove from pending and save state
            pending[name] = nil
            save(state)
        end
        
        local ok, err = pcall(process_entry)
        if not ok then
            success = false
        end
    end
    
    -- Run sync if needed
    if sync ~= nil and not synced then
        local ok, err = pcall(function()
            sync(root)
        end)
        if not ok then
            success = false
        end
    end
    
    return success
end

return {
    synchronize_checkout = synchronize_checkout,
    update_status_counts = update_status_counts,
    queue_artifact = queue_artifact,
    publish_pending = publish_pending,
    LANGUAGES = LANGUAGES
}
