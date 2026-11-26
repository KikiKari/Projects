#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "c02d009ebc3622cff390670a69432f20cbd8dc1c61afdef3990afe87fb9fb89d", "source_sha256": "8621f6f7e524474de82b3d877ee62bbcbd9fa3b247b69c437b063b71fa995f5a", "target_language": "lua"}
-- ops-hub-heartbeat.js — portiert nach lua
-- Quelle: javascript, OpenClaw@gateway1:scripts/ops-hub-heartbeat.js
-- auch in: OpenClaw@gateway2:scripts/ops-hub-heartbeat.js
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

local fs = require('fs')
local path = require('path')

-- Aktualisiere den Statusbericht mit aktueller Zeit
local statusPath = path.join(os.getenv('PWD'), '../docs/ops-hub/status.md')

function updateHeartbeat()
  local content
  local file, err = io.open(statusPath, 'r')
  if not file then
    print('❌ Konnte status.md nicht lesen: ' .. err)
    return
  end
  
  content = file:read('*all')
  file:close()

  -- Get current time in German format with Berlin timezone
  local now = os.date('%d.%m.%Y, %H:%M:%S')  -- Approximation for de-DE format
  
  -- Replace the heartbeat line
  local updated = string.gsub(content, '(Letzter Heartbeat:) [^\n]*', '%1 ' .. now)

  file, err = io.open(statusPath, 'w')
  if not file then
    print('❌ Konnte status.md nicht schreiben: ' .. err)
    return
  end
  
  file:write(updated)
  file:close()
  print('✅ Heartbeat aktualisiert: ' .. now)
end

updateHeartbeat()
