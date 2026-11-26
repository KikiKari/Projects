#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "1837da4950006490f72792cd362b735e319be1589c2c69e171dd8650d08398a5", "source_sha256": "b00f64d55d344bbcc351ae7ade12137f0d9293b556aa0881ede43bef5bcb778b", "target_language": "lua"}
-- extract-tiktok-yt-dlp.sh — portiert nach lua
-- Quelle: shell, OpenClaw@gateway2:skills/tiktok-live-mon/scripts/extraction-methods/extract-tiktok-yt-dlp.sh
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local function emit_json(success, method, username, url, format, error_msg, timestamp, status)
    local payload = {}
    if success ~= nil and success ~= "" then
        payload.success = success:lower() == "true"
    end
    if method ~= nil and method ~= "" then payload.method = method end
    if username ~= nil and username ~= "" then payload.username = username end
    if url ~= nil and url ~= "" then payload.url = url end
    if format ~= nil and format ~= "" then payload.format = format end
    if error_msg ~= nil and error_msg ~= "" then payload.error = error_msg end
    if timestamp ~= nil and timestamp ~= "" then payload.timestamp = timestamp end
    if status ~= nil and status ~= "" then payload.status = status end
    
    local json_str = "{"
    local first = true
    for k, v in pairs(payload) do
        if not first then json_str = json_str .. "," else first = false end
        json_str = json_str .. "\"" .. k .. "\":" 
        if type(v) == "boolean" then
            json_str = json_str .. tostring(v):lower()
        else
            json_str = json_str .. "\"" .. v:gsub('"', '\\"') .. "\""
        end
    end
    json_str = json_str .. "}"
    return json_str
end

-- Get current UTC timestamp
local function get_utc_timestamp()
    local date_table = os.date("!*t")
    return string.format("%04d-%02d-%02dT%02d:%02d:%02dZ", 
        date_table.year, date_table.month, date_table.day,
        date_table.hour, date_table.min, date_table.sec)
end

-- Create temporary directory
local function create_temp_dir()
    local template = "/tmp/tiktok-yt-dlp.XXXXXX"
    local tmp_name = os.tmpname()
    os.remove(tmp_name)  -- Remove the file created by tmpname
    os.execute("mkdir -p " .. tmp_name)  -- Use it as directory name
    return tmp_name
end

-- Main script logic
local args = {...}
local USERNAME = args[1] or ""
if USERNAME:sub(1,1) == "@" then
    USERNAME = USERNAME:sub(2)
end
local FORMAT = args[2] or "best"
local JSON_FLAG = args[3] or ""
local TIMESTAMP = get_utc_timestamp()

-- Validate username
if not USERNAME:match("^[A-Za-z0-9._]+$") or #USERNAME > 24 or #USERNAME < 1 then
    io.stderr:write("Invalid TikTok username\n")
    os.exit(64)
end

-- Validate format
local valid_formats = {
    "hls-origin/hls-pull/hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-origin/flv-hd/flv-ld",
    "hls-uhd_60/hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld",
    "hls-hd_60/hls-hd/hls-sd/hls-ld/flv-hd/flv-ld",
    "hls-hd/hls-sd/hls-ld/flv-hd/flv-sd/flv-ld",
    "hls-sd/hls-ld/flv-sd/flv-ld",
    "hls-ld/flv-ld",
    "hls-origin/hls-hd/hls-sd/hls-ld/hls-pull/flv-origin/flv-hd/flv-ld"
}
local format_valid = false
for _, valid_format in ipairs(valid_formats) do
    if FORMAT == valid_format then
        format_valid = true
        break
    end
end
if not format_valid then
    io.stderr:write("Invalid yt-dlp format\n")
    os.exit(64)
end

-- Check system load
local load_per_cpu = 0
local f = io.popen("cat /proc/loadavg | cut -d' ' -f1")
if f then
    local load_avg = tonumber(f:read("*l"))
    f:close()
    local cpu_count = 1
    local cf = io.open("/proc/cpuinfo", "r")
    if cf then
        local content = cf:read("*a")
        cf:close()
        local _, count = content:gsub("processor", "")
        cpu_count = math.max(1, count)
    end
    load_per_cpu = load_avg / cpu_count
end

local max_load = tonumber(os.getenv("TIKTOK_MAX_LOAD_PER_CPU") or "1.5")
if load_per_cpu > max_load then
    io.stderr:write(emit_json("false", "yt-dlp", USERNAME, "", FORMAT, "host overloaded", TIMESTAMP, "overloaded") .. "\n")
    os.exit(75)
end

-- Check if yt-dlp exists
local result = os.execute("which yt-dlp > /dev/null 2>&1")
if result ~= 0 then
    io.stderr:write(emit_json("false", "yt-dlp", USERNAME, "", FORMAT, "yt-dlp not installed", TIMESTAMP, "dependency_missing") .. "\n")
    os.exit(2)
end

-- Create temp directory
local TMP_DIR = create_temp_dir()
local function cleanup()
    os.execute("rm -rf " .. TMP_DIR)
end

-- Set up cleanup on exit
local original_exit = os.exit
os.exit = function(code)
    cleanup()
    original_exit(code)
end

-- Run yt-dlp
local LIVE_URL = "https://www.tiktok.com/@" .. USERNAME .. "/live"
local stdout_file = TMP_DIR .. "/stdout.json"
local stderr_file = TMP_DIR .. "/stderr.log"

local cmd = string.format('yt-dlp --no-warnings --dump-single-json --skip-download --format "%s" "%s" >"%s" 2>"%s"',
    FORMAT, LIVE_URL, stdout_file, stderr_file)

local success, _, exit_code = os.execute(cmd)
exit_code = exit_code or (success and 0 or 1)

if exit_code ~= 0 then
    local status, code
    local error_content = ""
    
    local ef = io.open(stderr_file, "r")
    if ef then
        error_content = ef:read(1000) or ""
        ef:close()
        
        if error_content:lower():find("not currently live") or 
           error_content:lower():find("no live cdn found") or
           error_content:lower():find("not available") or
           error_content:lower():find("private video") then
            status = "offline"
            code = 1
        else
            status = "technical_error"
            code = 2
        end
    end
    
    io.stderr:write(emit_json("false", "yt-dlp", USERNAME, "", FORMAT, error_content, TIMESTAMP, status) .. "\n")
    os.exit(code)
end

-- Extract URL from JSON
local URL = ""
local sf = io.open(stdout_file, "r")
if sf then
    local content = sf:read("*a")
    sf:close()
    
    -- Simple JSON parsing for this specific case
    local candidates = {}
    
    -- Extract direct URL field
    local url_match = content:match('"url"%s*:%s*"([^"]+)"')
    if url_match then
        table.insert(candidates, url_match)
    end
    
    -- Extract URLs from formats array
    for url in content:gmatch('"url"%s*:%s*"([^"]+)"') do
        if url ~= url_match then  -- Avoid duplicates
            table.insert(candidates, url)
        end
    end
    
    -- Filter candidates
    for _, value in ipairs(candidates) do
        local low_value = value:lower()
        if value:sub(1,8) == "https://" and 
           (low_value:find("%.m3u8") or low_value:find("%.flv")) and
           not low_value:find("only_audio=1") then
            URL = value
            break
        end
    end
end

if URL == "" then
    io.stderr:write(emit_json("false", "yt-dlp", USERNAME, "", FORMAT, "could not extract HTTPS video URL", TIMESTAMP, "offline") .. "\n")
    os.exit(1)
end

if JSON_FLAG == "--json" then
    print(emit_json("true", "yt-dlp", USERNAME, URL, FORMAT, "", TIMESTAMP, "live"))
else
    print(URL)
end
