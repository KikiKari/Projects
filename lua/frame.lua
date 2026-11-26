#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "ddf66b3036dd995fb9e550267dbbd36b74564e87f66ffe645084c61df07dbd97", "source_sha256": "b339455e9e618c836ccf2e3732e4fec9897f079730d8814eadb716e2459df453", "target_language": "lua"}
-- frame.sh — portiert nach lua
-- Quelle: shell, OpenClaw@gateway1:skills/video-frames/scripts/frame.sh
-- auch in: OpenClaw@gateway2:skills/video-frames/scripts/frame.sh
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local function usage()
  io.stderr:write([[
Usage:
  frame.sh <video-file> [--time HH:MM:SS] [--index N] --out /path/to/frame.jpg

Examples:
  frame.sh video.mp4 --out /tmp/frame.jpg
  frame.sh video.mp4 --time 00:00:10 --out /tmp/frame-10s.jpg
  frame.sh video.mp4 --index 0 --out /tmp/frame0.png
]])
  os.exit(2)
end

local args = {...}
if #args == 0 or args[1] == "-h" or args[1] == "--help" then
  usage()
end

local input_file = table.remove(args, 1)

local time = ""
local index = ""
local out = ""

local i = 1
while i <= #args do
  if args[i] == "--time" then
    time = args[i + 1] or ""
    i = i + 2
  elseif args[i] == "--index" then
    index = args[i + 1] or ""
    i = i + 2
  elseif args[i] == "--out" then
    out = args[i + 1] or ""
    i = i + 2
  else
    io.stderr:write("Unknown arg: " .. args[i] .. "\n")
    usage()
  end
end

local file = io.open(input_file, "r")
if not file then
  io.stderr:write("File not found: " .. input_file .. "\n")
  os.exit(1)
end
file:close()

if out == "" then
  io.stderr:write("Missing --out\n")
  usage()
end

-- Create output directory
local out_dir = out:match("(.+)/[^/]*$")
if out_dir then
  local mkdir_cmd = "mkdir -p " .. out_dir
  local success = os.execute(mkdir_cmd)
  if not success then
    io.stderr:write("Failed to create directory: " .. out_dir .. "\n")
    os.exit(1)
  end
end

local cmd
if index ~= "" then
  cmd = string.format('ffmpeg -hide_banner -loglevel error -y -i "%s" -vf "select=eq(n\\,%s)" -vframes 1 "%s"', input_file, index, out)
elseif time ~= "" then
  cmd = string.format('ffmpeg -hide_banner -loglevel error -y -ss "%s" -i "%s" -frames:v 1 "%s"', time, input_file, out)
else
  cmd = string.format('ffmpeg -hide_banner -loglevel error -y -i "%s" -vf "select=eq(n\\,0)" -vframes 1 "%s"', input_file, out)
end

local success = os.execute(cmd)
if not success then
  os.exit(1)
end

print(out)
