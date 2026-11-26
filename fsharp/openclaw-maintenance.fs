// abstraction-provenance: {"artifact_sha256": "4df502a92cea9a26f2594d06700aa0482f1a339e17ee467b5d193a88b7416baa", "source_sha256": "2a9ca592fdc915cfb281aa77dde9f07ffd3de83ce5abb8d87c77d46668d75dd6", "target_language": "fsharp"}
// openclaw-maintenance.sh — portiert nach fsharp
// Quelle: shell, OpenClaw@gateway1:scripts/openclaw-maintenance.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

// === 1. Service-/Config-Drift ===
openclaw doctor

// === 2. Plugin-Stage (aktive Varianten, NICHT plugins doctor) ===
openclaw plugins registry --refresh
openclaw plugins update --all

// === 3. Tasks ===
openclaw tasks maintenance --apply

// === 4. Sessions – alle Agents auf einmal ===
openclaw sessions cleanup --enforce --all-agents

// === 5. Memory – status/index decken alle Agents ab ===
openclaw memory status --deep --fix
openclaw memory index --force

// === 6. Memory promote – MUSS pro Agent ===
["main"; "knecht"; "docs"; "ops-hub"; "cron"]
|> List.iter (fun agent -> 
    openclaw memory promote --apply --agent agent)

// === 7. Secrets ===
openclaw secrets reload
