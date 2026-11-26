#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "0d469be51334d897c2034972990731b8b14a80313cc55fb7c77317057e44ff17", "source_sha256": "8621f6f7e524474de82b3d877ee62bbcbd9fa3b247b69c437b063b71fa995f5a", "target_language": "ruby"}
# ops-hub-heartbeat.js — portiert nach ruby
# Quelle: javascript, OpenClaw@gateway1:scripts/ops-hub-heartbeat.js
# auch in: OpenClaw@gateway2:scripts/ops-hub-heartbeat.js
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# frozen_string_literal: true

require 'fileutils'
require 'pathname'

# Aktualisiere den Statusbericht mit aktueller Zeit
status_path = File.join(File.dirname(__FILE__), '../docs/ops-hub/status.md')

def update_heartbeat(status_path)
  content = nil
  begin
    content = File.read(status_path, encoding: 'UTF-8')
  rescue => e
    puts "❌ Konnte status.md nicht lesen: #{e.message}"
    return
  end

  now = Time.now.localtime('+01:00').strftime('%d.%m.%Y, %H:%M:%S')
  updated = content.gsub(/(Letzter Heartbeat:) [^\n]*/, "\\1 #{now}")

  begin
    File.write(status_path, updated, encoding: 'UTF-8')
    puts "✅ Heartbeat aktualisiert: #{now}"
  rescue => e
    puts "❌ Konnte status.md nicht schreiben: #{e.message}"
  end
end

update_heartbeat(status_path)
