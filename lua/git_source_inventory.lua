#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "3605299c961f588ae279e79916dc108d065f46ed8854672f2d9cd1485c06f176", "source_sha256": "42646f32f72b1ca4e041673cd4a65a4b6611379252e110d53df9fb001a5ba6de", "target_language": "lua"}
-- git_source_inventory.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/git_source_inventory.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[Git tree inventory and batched selected-blob loading.]]

local function write_private(path, data)
    local fd = assert(io.open(path, "wb"))
    fd:write(data)
    fd:close()
end

local function snapshot(manager, run_id, run_attempt, workflow_sha)
    local function repository_index(source)
        local name = tostring(source.repo)
        local mirror = manager.QUELLEN_DIR .. "/" .. name .. ".git"

        local function git(...)
            local args = {"git", "-C", mirror}
            for _, arg in ipairs({...}) do
                table.insert(args, arg)
            end
            local proc = io.popen(table.concat(args, " "))
            local result = proc:read("*all")
            proc:close()
            return result
        end

        local refs_output = git("for-each-ref", "--format=%(refname:strip=2)%00%(objectname)", "refs/heads")
        local refs = {}
        for line in refs_output:gmatch("[^\r\n]+") do
            table.insert(refs, line)
        end

        local selected = {}
        for _, line in ipairs(refs) do
            local branch_bytes, commit = line:match("^(.-)%z(.+)$")
            local branch = branch_bytes
            if source.branches == "alle" or vim.tbl_contains(source.branches, branch) then
                table.insert(selected, {branch, commit})
            end
        end

        local function branch_index(item)
            local branch, commit = item[1], item[2]
            local paths = {}
            local ls_tree_output = git("ls-tree", "-r", "-z", "--full-tree", commit)
            for entry in ls_tree_output:gmatch("[^%z]+") do
                if entry ~= "" then
                    local meta, path = entry:match("^(.-)\t(.+)$")
                    local text = path
                    local _, kind = meta:match("^(.-) (.-) ")
                    if kind == "blob" then
                        local suffix = ""
                        local parts = {}
                        for part in text:gmatch("[^%.]+") do
                            table.insert(parts, part)
                        end
                        if #parts > 1 then
                            suffix = "." .. parts[#parts]:lower()
                        end
                        if manager.QUELLSPRACHEN[suffix] then
                            table.insert(paths, text)
                        end
                    end
                end
            end
            return branch, {commit = commit, paths = paths}
        end

        local branches = {}
        for _, item in ipairs(selected) do
            local branch, data = branch_index(item)
            branches[branch] = data
        end

        if not next(branches) or (source.branches ~= "alle" and vim.fn.len(vim.fn.keys(branches)) ~= vim.fn.len(source.branches)) then
            error("incomplete source branches")
        end
        return name, branches
    end

    local repositories = {}
    for _, source in ipairs(manager.QUELLEN) do
        local name, branches = repository_index(source)
        repositories[name] = branches
    end
    return {version = 1, run_id = run_id, run_attempt = run_attempt, workflow_sha = workflow_sha, repositories = repositories}
end

local function prepare_git_sources(manager, directory, state, priority, count, run_id, run_attempt, workflow_sha)
    --[[Index pinned Git trees and materialize only selected source blobs.]]

    local function git(mirror, ...)
        local args = {"git", "-C", mirror}
        for _, arg in ipairs({...}) do
            table.insert(args, arg)
        end
        local proc = io.popen(table.concat(args, " "))
        local result = proc:read("*all")
        proc:close()
        return result
    end

    os.execute("mkdir -p " .. manager.QUELLEN_DIR)

    local function update(source)
        local repo = tostring(source.repo)
        local mirror = manager.QUELLEN_DIR .. "/" .. repo .. ".git"
        local result
        if vim.fn.isdirectory(mirror) == 1 then
            result = manager:_git("remote", "update", "--prune", {verzeichnis = mirror})
        else
            local url = "https://github.com/" .. manager.GITHUB_BENUTZER .. "/" .. repo .. ".git"
            result = manager:_git("clone", "--mirror", "--filter=blob:none", url, mirror)
        end
        if result.returncode ~= 0 then
            error(repo .. ": Quellspiegel nicht verfuegbar")
        end
    end

    for _, source in ipairs(manager.QUELLEN) do
        update(source)
    end

    local index = snapshot(manager, run_id, run_attempt, workflow_sha)
    local sources = {}

    local function list_branch(item)
        local repo, branch, commit = item[1], item[2], item[3]
        local mirror = manager.QUELLEN_DIR .. "/" .. repo .. ".git"
        local records = {}
        local ls_tree_output = git(mirror, "ls-tree", "-r", "-z", "--full-tree", commit)
        for item_entry in ls_tree_output:gmatch("[^%z]+") do
            if item_entry ~= "" then
                local metadata, raw_path = item_entry:match("^(.-)\t(.+)$")
                local mode, kind, oid = metadata:match("^(.-) (.-) (.+)$")
                if kind == "blob" and (mode == "100644" or mode == "100755") then
                    local path = raw_path:gsub("\\\\", "/")
                    local suffix = ""
                    local parts = {}
                    for part in path:gmatch("[^%.]+") do
                        table.insert(parts, part)
                    end
                    if #parts > 1 then
                        suffix = "." .. parts[#parts]:lower()
                    end
                    local language = manager.QUELLSPRACHEN[suffix]
                    local skip = false
                    for _, pattern in ipairs(manager.AUSSCHLUSS) do
                        if "/" .. path:find(pattern, 1, true) then
                            skip = true
                            break
                        end
                    end
                    if language and not skip then
                        if not oid:match("^[0-9a-f]+$") or #oid ~= 40 then
                            error("invalid Git blob identity")
                        end
                        table.insert(records, {repo, branch, commit, path, language, oid})
                    end
                end
            end
        end
        return records
    end

    local branches = {}
    for repo, details in pairs(index.repositories) do
        for branch, data in pairs(details) do
            table.insert(branches, {repo, branch, data.commit})
        end
    end

    for _, records in ipairs(branches) do
        for _, record in ipairs(list_branch(records)) do
            table.insert(sources, record)
        end
    end

    local grouped = {}
    for _, source_data in ipairs(sources) do
        local repo, branch, commit, path, language, oid = unpack(source_data)
        local origin = repo .. "@" .. branch .. ":" .. path
        local item = grouped[oid]
        if not item then
            item = {
                blob = oid,
                repo = repo,
                commit = commit,
                path = path,
                sprache = language,
                herkunft = {},
                prioritaet = manager:_prioritaet(path, language)
            }
            grouped[oid] = item
        end
        table.insert(item.herkunft, origin)
    end

    local rank = {high = 0, medium = 1, low = 2}
    local candidates = {}
    for _, item in pairs(grouped) do
        if priority == "alle" or item.prioritaet == priority then
            table.insert(candidates, item)
        end
    end

    table.sort(candidates, function(a, b)
        if rank[a.prioritaet] == rank[b.prioritaet] then
            return a.path < b.path
        else
            return rank[a.prioritaet] < rank[b.prioritaet]
        end
    end)

    local cursor = state.auswahl_blob_cursor and state.auswahl_blob_cursor[priority]
    if cursor then
        local pos = nil
        for i, item in ipairs(candidates) do
            if item.blob == cursor then
                pos = i
                break
            end
        end
        if pos then
            local new_candidates = {}
            for i = pos + 1, #candidates do
                table.insert(new_candidates, candidates[i])
            end
            for i = 1, pos do
                table.insert(new_candidates, candidates[i])
            end
            candidates = new_candidates
        end
    end

    local selected = {}
    for i = 1, math.min(count, #candidates) do
        table.insert(selected, candidates[i])
    end

    local by_repo = {}
    for _, item in ipairs(selected) do
        if not by_repo[item.repo] then
            by_repo[item.repo] = {}
        end
        table.insert(by_repo[item.repo], item)
    end

    local function read_blobs(pair)
        local repo, items = pair[1], pair[2]
        local mirror = manager.QUELLEN_DIR .. "/" .. repo .. ".git"
        local requested = ""
        for _, item in ipairs(items) do
            requested = requested .. item.blob .. "\n"
        end

        local checks_output = git(mirror, "cat-file", "--batch-check=%(objectname) %(objecttype) %(objectsize)", requested)
        local checks = {}
        for line in checks_output:gmatch("[^\r\n]+") do
            table.insert(checks, line)
        end

        if #checks ~= #items then
            error("incomplete Git blob metadata")
        end

        local eligible = {}
        for i, item in ipairs(items) do
            local line = checks[i]
            local fields = {}
            for field in line:gmatch("%S+") do
                table.insert(fields, field)
            end
            if #fields ~= 3 or fields[1] ~= item.blob or fields[2] ~= "blob" then
                error("invalid Git blob metadata")
            end
            local size = tonumber(fields[3])
            if size <= manager.MAX_BYTES then
                table.insert(eligible, {item, size})
            end
        end

        if not next(eligible) then
            return {}
        end

        local wanted = ""
        for _, item_size in ipairs(eligible) do
            local item = item_size[1]
            wanted = wanted .. item.blob .. "\n"
        end

        local output_data = git(mirror, "cat-file", "--batch", wanted)
        local output = {data = output_data, pos = 1}
        function output:readline()
            local start = self.pos
            local finish = self.data:find("\n", start, true)
            if not finish then
                return nil
            end
            local line = self.data:sub(start, finish - 1)
            self.pos = finish + 1
            return line
        end

        local result = {}
        for _, item_size in ipairs(eligible) do
            local item, size = item_size[1], item_size[2]
            local header_line = output:readline()
            local header = {}
            for part in header_line:gmatch("%S+") do
                table.insert(header, part)
            end
            if #header ~= 3 or header[1] ~= item.blob or header[2] ~= "blob" or tonumber(header[3]) ~= size then
                error("invalid Git blob response")
            end
            local raw = output.data:sub(output.pos, output.pos + size - 1)
            output.pos = output.pos + size + 1
            if #raw ~= size or output.data:sub(output.pos - 1, output.pos - 1) ~= "\n" then
                error("incomplete Git blob response")
            end
            table.insert(result, {item, raw})
        end
        return result
    end

    local loaded = {}
    for _, pair in pairs(by_repo) do
        local results = read_blobs({pair[1].repo, pair})
        for _, result in ipairs(results) do
            local item, raw = result[1], result[2]
            loaded[item.blob] = raw
        end
    end

    local source_dir = directory .. "/sources"
    os.execute("mkdir -p " .. source_dir)

    local inventory = {}
    for _, item in ipairs(selected) do
        local raw = loaded[item.blob]
        if raw and raw:match("%S") and not manager:enthaelt_zugangsdaten(raw) then
            local sha256 = require("openssl").digest.new("sha256"):final(raw)
            local digest = ""
            for i = 1, #sha256 do
                digest = digest .. string.format("%02x", sha256:byte(i))
            end
            local target = source_dir .. "/" .. digest
            if not vim.fn.filereadable(target) then
                write_private(target, raw)
            end
            local source_path_parts = {}
            for part in item.path:gmatch("[^/]+") do
                table.insert(source_path_parts, part)
            end
            local source_filename = source_path_parts[#source_path_parts] or ""
            local stem = source_filename:match("^(.+)%.[^.]*$") or source_filename
            table.insert(inventory, {
                hash = digest:sub(1, 16),
                name = source_filename,
                stamm = stem,
                sprache = item.sprache,
                bytes = #raw,
                pfad = target,
                herkunft = item.herkunft,
                prioritaet = item.prioritaet,
                css_only = false,
                source_blob = item.blob,
                source_repo = item.repo,
                source_commit = item.commit,
                source_path = item.path,
                source_sha256 = digest
            })
        end
    end

    local last_blob = #selected > 0 and selected[#selected].blob or nil
    return index, inventory, last_blob
end

return {
    snapshot = snapshot,
    prepare_git_sources = prepare_git_sources
}
