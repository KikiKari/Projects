#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "f8c42595aa8eea89af6373939e1d5a8f2de631876364491c643aabfa583ab121", "source_sha256": "fecaa7522aec9008996f5664c745893f7fb7a2a4a3134a9f2855acde7f79596c", "target_language": "lua"}
-- extract-tiktok-streamlink.sh — portiert nach lua
-- Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-streamlink.sh
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local function emit_json(success, method, username, url, quality, author, title, error_msg, timestamp, status)
    local json = require("cjson")
    local payload = {}
    if success ~= nil and success ~= "" then
        payload.success = (success:lower() == "true")
    end
    if method ~= nil and method ~= "" then payload.method = method end
    if username ~= nil and username ~= "" then payload.username = username end
    if url ~= nil and url ~= "" then payload.url = url end
    if quality ~= nil and quality ~= "" then payload.quality = quality end
    if author ~= nil and author ~= "" then payload.author = author end
    if title ~= nil and title ~= "" then payload.title = title end
    if error_msg ~= nil and error_msg ~= "" then payload.error = error_msg end
    if timestamp ~= nil and timestamp ~= "" then payload.timestamp = timestamp end
    if status ~= nil and status ~= "" then payload.status = status end
    print(json.encode(payload))
end

local function validate_username(username)
    return string.match(username, "^[A-Za-z0-9._]+$") ~= nil and
           string.len(username) >= 1 and string.len(username) <= 24
end

local function validate_quality(quality)
    local valid_qualities = {
        best = true, worst = true, original = true,
        ["1080p60"] = true, ["720p60"] = true, ["720p"] = true,
        ["540p"] = true, ["360p"] = true, auto = true
    }
    return valid_qualities[quality] == true
end

local function get_system_load()
    local f = io.popen("python3 -c 'import os; print(os.getloadavg()[0] / max(1, os.cpu_count() or 1))'")
    local load = f:read("*a")
    f:close()
    return tonumber(load)
end

local function check_command_exists(cmd)
    local handle = io.popen("command -v " .. cmd .. " >/dev/null 2>&1 && echo 1 || echo 0")
    local result = handle:read("*a")
    handle:close()
    return result:match("^%s*1%s*$") ~= nil
end

local function get_timestamp()
    local f = io.popen("date -u +%Y-%m-%dT%H:%M:%SZ")
    local timestamp = f:read("*a"):gsub("\n$", "")
    f:close()
    return timestamp
end

local function run_streamlink_json(url, selector)
    local cmd = string.format('streamlink --json "%s" "%s" 2>/dev/null', url, selector)
    local f = io.popen(cmd)
    local output = f:read("*a")
    local success, _, code = f:close()
    return output, code
end

local function run_streamlink_url(url, selector)
    local cmd = string.format('streamlink --stream-url "%s" "%s" 2>/dev/null', url, selector)
    local f = io.popen(cmd)
    local output = f:read("*a")
    local success, _, code = f:close()
    return output, code
end

local function parse_streamlink_output(output)
    local json = require("cjson")
    local status, data = pcall(json.decode, output)
    if not status then return nil end
    
    local url = data.url or ""
    local streams = data.streams or {}
    
    if url == "" and type(streams) == "table" then
        local keys = {"best", "worst"}
        for k, _ in pairs(streams) do table.insert(keys, k) end
        
        for _, key in ipairs(keys) do
            local stream = streams[key]
            if type(stream) == "table" and stream.url then
                url = stream.url
                break
            end
        end
    end
    
    local metadata = data.metadata or {}
    return {
        url = url,
        author = metadata.author or "",
        title = metadata.title or ""
    }
end

-- Main script logic
local args = {...}
local USERNAME = args[1] or ""
if USERNAME:sub(1, 1) == "@" then USERNAME = USERNAME:sub(2) end
local QUALITY = args[2] or "best"
local JSON_FLAG = args[3] or ""
local TIMESTAMP = get_timestamp()

if not validate_username(USERNAME) then
    io.stderr:write("Invalid TikTok username\n")
    os.exit(64)
end

if not validate_quality(QUALITY) then
    io.stderr:write("Invalid stream quality\n")
    os.exit(64)
end

-- Check system load
local LOAD_PER_CPU = get_system_load()
local MAX_LOAD = os.getenv("TIKTOK_MAX_LOAD_PER_CPU") or "1.5"
MAX_LOAD = tonumber(MAX_LOAD)

if LOAD_PER_CPU > MAX_LOAD then
    emit_json("false", "streamlink", USERNAME, "", QUALITY, "", "", 
              "host overloaded", TIMESTAMP, "overloaded")
    io.stderr:write(emit_json("false", "streamlink", USERNAME, "", QUALITY, "", "", 
                              "host overloaded", TIMESTAMP, "overloaded"))
    os.exit(75)
end

-- Check if streamlink exists
if not check_command_exists("streamlink") then
    emit_json("false", "streamlink", USERNAME, "", QUALITY, "", "", 
              "streamlink not installed", TIMESTAMP, "dependency_missing")
    io.stderr:write(emit_json("false", "streamlink", USERNAME, "", QUALITY, "", "", 
                              "streamlink not installed", TIMESTAMP, "dependency_missing"))
    os.exit(2)
end

local LIVE_URL = "https://www.tiktok.com/@" .. USERNAME .. "/live"

-- Quality selector mapping
local selectors = {
    original = "origin,uhd_60,hd_60,hd,sd,ld,best,worst",
    auto = "best,origin,uhd_60,hd_60,hd,sd,ld,worst",
    ["1080p60"] = "uhd_60,hd_60,hd,sd,ld,worst",
    ["720p60"] = "hd_60,hd,sd,ld,worst",
    ["720p"] = "hd,sd,ld,worst",
    ["540p"] = "sd,ld,worst",
    ["360p"] = "ld,worst"
}
local SELECTOR = selectors[QUALITY] or QUALITY

-- Try streamlink with JSON output first
local OUTPUT, EXIT_CODE = run_streamlink_json(LIVE_URL, SELECTOR)

if EXIT_CODE ~= 0 or OUTPUT == "" then
    -- Fallback to stream-url
    local URL, code = run_streamlink_url(LIVE_URL, SELECTOR)
    if code ~= 0 or URL == "" then
        emit_json("false", "streamlink", USERNAME, "", QUALITY, "", "", 
                  "streamlink failed or no stream found", TIMESTAMP, "offline")
        io.stderr:write(emit_json("false", "streamlink", USERNAME, "", QUALITY, "", "", 
                                  "streamlink failed or no stream found", TIMESTAMP, "offline"))
        os.exit(1)
    end
    
    URL = URL:gsub("\n$", "")
    if JSON_FLAG == "--json" then
        emit_json("true", "streamlink", USERNAME, URL, QUALITY, "", "", "", TIMESTAMP, "live")
    else
        print(URL)
    end
    os.exit(0)
end

-- Parse JSON output
local parsed_data = parse_streamlink_output(OUTPUT)
if not parsed_data then
    emit_json("false", "streamlink", USERNAME, "", QUALITY, "", "", 
              "invalid streamlink JSON", TIMESTAMP, "technical_error")
    io.stderr:write(emit_json("false", "streamlink", USERNAME, "", QUALITY, "", "", 
                              "invalid streamlink JSON", TIMESTAMP, "technical_error"))
    os.exit(2)
end

local URL = parsed_data.url
local AUTHOR = parsed_data.author
local TITLE = parsed_data.title

if URL == "" then
    emit_json("false", "streamlink", USERNAME, "", QUALITY, AUTHOR, TITLE, 
              "could not extract stream URL", TIMESTAMP, "offline")
    io.stderr:write(emit_json("false", "streamlink", USERNAME, "", QUALITY, AUTHOR, TITLE, 
                              "could not extract stream URL", TIMESTAMP, "offline"))
    os.exit(1)
end

if JSON_FLAG == "--json" then
    emit_json("true", "streamlink", USERNAME, URL, QUALITY, AUTHOR, TITLE, "", TIMESTAMP, "live")
else
    print(URL)
end
