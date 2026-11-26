#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "774f2388f5e02e63a1fe024e4c2b565bed29c0fe387b1d6aea25ea949b9cffe3", "source_sha256": "4c10c6b6fd911cb95da119f761f402073d1a836cab6b40a9f3b989536d5df5ec", "target_language": "lua"}
-- git_publish.py — portiert nach lua
-- Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
-- auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

--[[Git Publish Agent - Automatisierte Skill-Veröffentlichung]]

local argparse = require "argparse"
local json = require "cjson"

local SKILLS_DIR = os.getenv("HOME") .. "/.openclaw/workspace/skills"

local function run_command(cmd, cwd)
  local command = cmd
  if cwd then
    command = "cd " .. cwd .. " && " .. cmd
  end
  local handle = io.popen(command)
  local result = handle:read("*a")
  local success, _, code = handle:close()
  return success, result, code
end

local function git_commit(skill_path, message)
  -- Commit skill changes.
  if not message then
    local now = os.date("%Y-%m-%dT%H:%M:%S")
    message = "[skill] Auto-update " .. skill_path:match("([^/]+)$") .. " - " .. now
  end
  
  local add_success = run_command("git add " .. skill_path, SKILLS_DIR .. "/..")
  local commit_cmd = "git commit -m \"" .. message .. "\""
  local commit_success, _, code = run_command(commit_cmd, SKILLS_DIR .. "/..")
  
  return code == 0
end

local function clawhub_publish(skill_name)
  -- Publish to ClawHub.
  local skill_path = SKILLS_DIR .. "/" .. skill_name
  local publish_cmd = "clawhub publish " .. skill_path .. " --slug " .. skill_name .. " --version 1.0.0"
  local success, output, code = run_command(publish_cmd)
  
  return code == 0, output
end

local function batch_publish()
  -- Publish all changed skills with rate limiting.
  -- Check git status
  local status_cmd = "git status --short " .. SKILLS_DIR
  local _, status_output = run_command(status_cmd)
  
  local changed = {}
  for line in status_output:gmatch("[^\r\n]+") do
    if line:match("%S") and line:match("skills/") then
      local skill = line:match("skills/([^/]+)")
      if not changed[skill] then
        table.insert(changed, skill)
        changed[skill] = true
      end
    end
  end
  
  print("Changed skills: " .. table.concat(changed, ", "))
  
  -- Publish with delay
  for i, skill in ipairs(changed) do
    if i > 5 then break end -- Max 5 per batch
    if i > 1 then
      print("Waiting 15min for rate limit...")
      -- In real: os.execute("sleep 900")
    end
    
    print("Publishing " .. skill .. "...")
    local commit_ok = git_commit(SKILLS_DIR .. "/" .. skill)
    if commit_ok then
      local pub_ok, output = clawhub_publish(skill)
      print(string.format("  %s %s", pub_ok and "✓" or "✗", output))
    end
  end
end

local function main()
  local parser = argparse()
  parser:description("Git Publish Agent")
  parser:option("--skill", "Single skill to publish")
  parser:flag("--all", "Publish all changed"):action("store_true")
  parser:flag("--no-publish", "Commit only"):action("store_true")
  parser:option("--message", "Custom commit message")
  
  local args = parser:parse()
  
  if args.skill then
    local skill_path = SKILLS_DIR .. "/" .. args.skill
    if args.no_publish then
      git_commit(skill_path, args.message)
    else
      git_commit(skill_path, args.message)
      clawhub_publish(args.skill)
    end
  elseif args.all then
    batch_publish()
  else
    print("Use --skill <name> or --all")
  end
end

main()
