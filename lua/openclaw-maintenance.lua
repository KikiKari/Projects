#!/usr/bin/env lua
-- abstraction-provenance: {"artifact_sha256": "491493594d66abdf84466189ec091ba7f6cc4495f320c637b2b996af1d7c843b", "source_sha256": "2a9ca592fdc915cfb281aa77dde9f07ffd3de83ce5abb8d87c77d46668d75dd6", "target_language": "lua"}
-- openclaw-maintenance.sh — portiert nach lua
-- Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

-- === 1. Service-/Config-Drift ===
os.execute("openclaw doctor")

-- === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===
os.execute("openclaw plugins registry --refresh")
os.execute("openclaw plugins update --all")

-- === 3. Tasks ===
os.execute("openclaw tasks maintenance --apply")

-- === 4. Sessions – alle Agents auf einmal ===
os.execute("openclaw sessions cleanup --enforce --all-agents")

-- === 5. Memory – status/index decken alle Agents ab ===
os.execute("openclaw memory status --deep --fix")
os.execute("openclaw memory index --force")

-- === 6. Memory promote – MUSS pro Agent ===
local agents = {"main", "knecht", "docs", "ops-hub", "cron"}
for i, agent in ipairs(agents) do
  os.execute("openclaw memory promote --apply --agent " .. agent)
end

-- === 7. Secrets ===
os.execute("openclaw secrets reload")
