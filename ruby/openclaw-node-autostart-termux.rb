#!/data/data/com.termux/files/usr/bin/ruby
# abstraction-provenance: {"artifact_sha256": "ea40bee7b89104bbd2d8c579abe8ef88d49f6cf3825bc96a1c7ab6889d07167a", "source_sha256": "dd115a5287b5db772bd4af098a6620a66b294c0e327633048101753a48a3976b", "target_language": "ruby"}
# openclaw-node-autostart-termux.sh — portiert nach ruby
# Quelle: shell, OpenClaw@gateway1:scripts/openclaw-node-autostart-termux.sh
# auch in: OpenClaw@gateway2:scripts/openclaw-node-autostart-termux.sh
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# OpenClaw Node Mode Autostart für Termux (Node 5 - Redmi Note 11)
# Installiert nach: ~/.termux/boot/openclaw-node.rb
# Getestet mit: Termux + Android + OpenClaw

SESSION = "openclaw-node"
LOGFILE = "#{ENV['HOME']}/.openclaw/node.log"
GATEWAY = "10.10.0.1"
PORT = "18789"

# Log-Verzeichnis erstellen
Dir.mkdir("#{ENV['HOME']}/.openclaw", mode: 0755) unless Dir.exist?("#{ENV['HOME']}/.openclaw")

# Prüfen ob tmux Session bereits läuft
def session_exists?(session_name)
  system("tmux has-session -t #{session_name} >/dev/null 2>&1")
end

# In Ruby gibt es kein direktes Equivalent zu tee, daher schreiben wir eine Hilfsfunktion
def log_message(message, logfile)
  timestamped_message = "[#{Time.now}] #{message}"
  puts timestamped_message
  File.open(logfile, 'a') { |f| f.puts timestamped_message }
end

if session_exists?(SESSION)
  log_message("OpenClaw Node läuft bereits in tmux Session '#{SESSION}'", LOGFILE)
  exit 0
end

# Neue tmux Session erstellen und OpenClaw starten
script = <<~SCRIPT
  while true; do
    echo '[#{Time.now}] Starting OpenClaw Node Mode...' | tee -a '#{LOGFILE}'
    
    # Prüfe WireGuard Verbindung
    if ! ping -c 1 -W 3 #{GATEWAY} >/dev/null 2>&1; then
      echo '[#{Time.now}] FEHLER: WireGuard Gateway #{GATEWAY} nicht erreichbar!' | tee -a '#{LOGFILE}'
      echo '[#{Time.now}] Warte 10 Sekunden...' | tee -a '#{LOGFILE}'
      sleep 10
      continue
    fi
    
    # OpenClaw Node Mode starten
    openclaw node run --host #{GATEWAY} --port #{PORT} 2>&1 | tee -a '#{LOGFILE}'
    
    # Wenn der Prozess endet, warte und neustarten
    echo '[#{Time.now}] OpenClaw beendet. Neustart in 5 Sekunden...' | tee -a '#{LOGFILE}'
    sleep 5
  done
SCRIPT

system("tmux", "new-session", "-d", "-s", SESSION, "-n", "node", script)

log_message("OpenClaw Node Autostart aktiviert (tmux Session: #{SESSION})", LOGFILE)

# Optional: tmux attach Hinweis falls interaktiv gestartet
if $stdin.tty?
  puts "OpenClaw Node Mode gestartet in tmux Session '#{SESSION}'"
  puts "Zum Anschauen: tmux attach -t #{SESSION}"
  puts "Log-Datei: #{LOGFILE}"
end
