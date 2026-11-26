#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "8089d1c0dbf87aeec960efddbed78af1173bcc686bc0ca2dcbfe08c264c350a9", "source_sha256": "0a55a33f11db266892b50c887fd8d01783f387e3072c8c5b9ed86ca6788a8c52", "target_language": "ruby"}
# gen_tree.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway2:scripts/gen_tree.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Replicates `tree -a -L 6` output for /workspace into important/openclaw-tree.txt
# (used because the `tree` binary is unavailable in this sandbox).

ROOT = "/workspace"
OUT = "/workspace/important/openclaw-tree.txt"
MAX_DEPTH = 6

def collect(path, prefix = "", depth = 1)
  lines = []
  begin
    entries = Dir.entries(path).reject { |e| e == '.' || e == '..' }.sort
  rescue Errno::EACCES, Errno::ENOENT
    return lines
  end
  total = entries.length
  entries.each_with_index do |name, i|
    is_last = (i == total - 1)
    connector = is_last ? "\u2514\u2500\u2500 " : "\u251c\u2500\u2500 "
    lines << prefix + connector + name
    full = File.join(path, name)
    if depth < MAX_DEPTH && File.directory?(full) && !File.symlink?(full)
      next_prefix = prefix + (is_last ? "    " : "\u2502   ")
      lines.concat(collect(full, next_prefix, depth + 1))
    end
  end
  lines
end

body = collect(ROOT)
header = <<~HEADER
  # OpenClaw Workspace Tree
  # Generiert: #{Time.now.iso8601}
  # Befehl: tree -a -L 6 #{ROOT} (emuliert via gen_tree.rb)
  # Diese Datei wird automatisch von db-maintainer aktualisiert

  HEADER

content = header + ".\n" + body.join("\n") + "\n"

File.open(OUT, "w", encoding: "utf-8") do |f|
  f.write(content)
end

puts "written #{OUT}: #{body.length + 1} lines, #{content.bytesize} bytes"
