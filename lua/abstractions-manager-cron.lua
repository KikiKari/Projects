#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "328223cfee1c2cc3623966dda7e418d92f367dd6f983455cafe67264b76e33c4", "source_sha256": "1b01ca0f5943b16d3905faf557953600ee54f15ecf1dc18c1461585eba94d376", "target_language": "lua"}
-- abstractions-manager-cron.sh — portiert nach lua
-- Quelle: shell, OpenClaw@gateway1:scripts/abstractions-manager-cron.sh
-- Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

-- Set the PATH environment variable
os.setenv("PATH", "/home/openclaw/.local/bin:/usr/local/bin:/usr/bin:/bin")

-- Load environment variables from .env file
local env_file = io.open("/home/openclaw/.openclaw/.env", "r")
if env_file then
    for line in env_file:lines() do
        local key, value = line:match("^([^=]+)=(.*)$")
        if key and value then
            os.setenv(key, value)
        end
    end
    env_file:close()
end

-- Check if OPENROUTER_API_KEY is set
if not os.getenv("OPENROUTER_API_KEY") then
    error("OPENROUTER_API_KEY fehlt")
end

-- Set GITHUB_TOKEN with fallbacks
local github_token = os.getenv("GITHUB_TOKEN") or os.getenv("GH_TOKEN") or os.getenv("GH_ACCESS_TOKEN") or 
os.setenv("GITHUB_TOKEN", github_token)

-- Function to check if a file is locked
local function is_locked(lock_file)
    local fd = io.open(lock_file, "r")
    if fd then
        fd:close()
        return true
    else
        return false
    end
end

-- Attempt to acquire lock
local lock_file = "/home/openclaw/.openclaw/locks/abstractions-manager.lock"
if not is_locked(lock_file) then
    local fd = io.open(lock_file, "w")
    if fd then
        fd:close()

        -- Execute the Python script
        local command = string.format("/usr/bin/python3/home/openclaw/.openclaw/workspace/skills/script-abstractions-manager/scripts/ABSTRACTIONS_MANAGER.py %s", table.concat(arg, " "))
        os.execute(command)

        -- Release the lock
        os.remove(lock_file)
    else
        print("Could not acquire lock")
    end
else
    print("Lock already held by another process")
end
