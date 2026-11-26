#!/data/data/com.termux/files/usr/bin/lua
-- abstraction-provenance: {"artifact_sha256": "90d2cfcc263c8072baa89dcb40f4778649b42c6ff8399bca9861c70c0d0d81fe", "source_sha256": "dd115a5287b5db772bd4af098a6620a66b294c0e327633048101753a48a3976b", "target_language": "lua"}
-- openclaw-node-autostart-termux.sh — portiert nach lua
-- Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
-- auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
-- Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

-- OpenClaw Node Mode Autostart für Termux (Node 5 - Redmi Note 11)
-- Installiert nach: ~/.termux/boot/openclaw-node.lua
-- Getestet mit: Termux + Android + OpenClaw

local SESSION = "openclaw-node"
local LOGFILE = os.getenv("HOME") .. "/.openclaw/node.log"
local GATEWAY = "10.10.0.1"
local PORT = "18789"

-- Log-Verzeichnis erstellen
os.execute("mkdir -p " .. os.getenv("HOME") .. "/.openclaw")

-- Prüfen ob tmux Session bereits läuft
local function session_exists()
    local handle = io.popen("tmux has-session -t " .. SESSION .. " 2>/dev/null; echo $?", "r")
    local result = handle:read("*a")
    handle:close()
    return string.match(result, "0")
end

-- In Datei schreiben mit Timestamp
local function log_message(message)
    local file = io.open(LOGFILE, "a")
    if file then
        file:write("[" .. os.date() .. "] " .. message .. "\n")
        file:close()
    end
end

-- Ping prüfen
local function ping_gateway(gateway)
    local handle = io.popen("ping -c 1 -W 3 " .. gateway .. " >/dev/null 2>&1; echo $?", "r")
    local result = handle:read("*a")
    handle:close()
    return string.match(result, "0")
end

if session_exists() then
    log_message("OpenClaw Node läuft bereits in tmux Session '" .. SESSION .. "'")
    os.exit(0)
end

-- Shell script für tmux erstellen
local script_content = [[
while true; do
    echo '[$(date)] Starting OpenClaw Node Mode...' | tee -a ]] .. LOGFILE .. [[
    
    # Prüfe WireGuard Verbindung
    if ! ping -c 1 -W 3 ]] .. GATEWAY .. [[ >/dev/null 2>&1; then
        echo '[$(date)] FEHLER: WireGuard Gateway ]] .. GATEWAY .. [[ nicht erreichbar!' | tee -a ]] .. LOGFILE .. [[
        echo '[$(date)] Warte 10 Sekunden...' | tee -a ]] .. LOGFILE .. [[
        sleep 10
        continue
    fi
    
    # OpenClaw Node Mode starten
    openclaw node run --host ]] .. GATEWAY .. [[ --port ]] .. PORT .. [[ 2>&1 | tee -a ]] .. LOGFILE .. [[
    
    # Wenn der Prozess endet, warte und neustarten
    echo '[$(date)] OpenClaw beendet. Neustart in 5 Sekunden...' | tee -a ]] .. LOGFILE .. [[
    sleep 5
done
]]

-- Script temporär speichern
local tmpfile = os.tmpname()
local file = io.open(tmpfile, "w")
file:write(script_content)
file:close()

-- Neue tmux Session erstellen und OpenClaw starten
os.execute("tmux new-session -d -s " .. SESSION .. " -n node 'bash " .. tmpfile .. "'")

log_message("OpenClaw Node Autostart aktiviert (tmux Session: " .. SESSION .. ")")

-- Optional: tmux attach Hinweis falls interaktiv gestartet
if io.stdin:read(0) ~= nil then
    print("OpenClaw Node Mode gestartet in tmux Session '" .. SESSION .. "'")
    print("Zum Anschauen: tmux attach -t " .. SESSION)
    print("Log-Datei: " .. LOGFILE)
end

-- Temporäre Datei löschen
os.remove(tmpfile)
