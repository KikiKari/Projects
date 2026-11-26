#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "cc4fa528a2f8040068a4ab6432a882bbaa3fd6ff701bf16909a9b30b24b77263", "source_sha256": "8d48f51942bb1c171bbd41e0696beb0722cb4b94d6596233f54b32928b645086", "target_language": "ruby"}
# db_maintainer.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway2:scripts/db_maintainer.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# frozen_string_literal: true

# Database Maintainer Sub-Agent
# Automated database maintenance with 30min checks, hourly backups (3 days retention),
# band tree command execution for important/openclaw-tree.txt

require 'digest'
require 'json'
require 'fileutils'
require 'pathname'
require 'securerandom'
require 'open3'

WORKSPACE = Pathname.new(ENV.fetch('OPENCLAW_WORKSPACE', File.expand_path('..', __dir__)))
DB_DIR = WORKSPACE
BACKUP_DIR = WORKSPACE / 'db' / 'backups'
LOG_DIR = WORKSPACE / 'logs' / 'db-maintainer'
IMPORTANT_DIR = WORKSPACE / 'important'

# Verzeichnisse erstellen
[BACKUP_DIR, LOG_DIR, IMPORTANT_DIR].each { |dir| FileUtils.mkdir_p(dir) }

class Logger
  # Einfacher Logger mit Datei-Ausgabe

  def initialize
    @today = Time.now.strftime('%Y-%m-%d')
    @log_file = LOG_DIR / "#{@today}.log"
  end

  def log(level, message)
    timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    line = "[#{timestamp}] [#{level}] #{message}"
    puts line
    File.open(@log_file, 'a') { |f| f.puts(line) }
  end

  def info(msg); log('INFO', msg); end
  def warn(msg); log('WARN', msg); end
  def error(msg); log('ERROR', msg); end
end

class DatabaseMaintainer
  def initialize
    @logger = Logger.new
    @state_file = DB_DIR / 'maintainer_state.json'
    @retention_days = 3 # 3 Tage Backup-Aufbewahrung
  end

  def load_state
    # Lädt letzten Check-Zustand
    if @state_file.exist?
      JSON.parse(File.read(@state_file), symbolize_names: true)
    else
      {
        last_check: nil,
        last_backup: nil,
        last_tree_update: nil,
        file_hashes: {}
      }
    end
  end

  def save_state(state)
    # Speichert aktuellen Zustand
    File.write(@state_file, JSON.pretty_generate(state))
  end

  def get_file_hash(filepath)
    # Berechnet MD5-Hash einer Datei
    Digest::MD5.file(filepath).to_s
  rescue StandardError
    nil
  end

  def python_tree_fallback(max_depth: 8)
    # Reiner Python-Fallback, falls das 'tree'-Binary fehlt (z.B. Sandbox).
    root = WORKSPACE
    lines = [root.to_s]

    walk = lambda do |dirpath, prefix, depth|
      return if depth > max_depth

      begin
        entries = dirpath.children.sort_by { |p| [p.directory? ? 0 : 1, p.basename.to_s] }
      rescue StandardError
        return
      end

      entries.each_with_index do |entry, i|
        connector = (i == entries.length - 1) ? '└── ' : '├── '
        lines << "#{prefix}#{connector}#{entry.basename}"

        if entry.directory? && !entry.symlink?
          extension = (i == entries.length - 1) ? '    ' : '│   '
          walk.call(entry, "#{prefix}#{extension}", depth + 1)
        end
      end
    end

    walk.call(root, '', 1)
    lines.join("\n") + "\n"
  end

  def run_tree_command
    # Führt tree -a -L 8 auf workspace aus und gibt Ergebnis zurück
    stdout, stderr, status = Open3.capture3('tree', '-a', '-L', '8', WORKSPACE.to_s)
    if status.success?
      @logger.info('tree -a -L 8 erfolgreich ausgeführt')
      stdout
    else
      @logger.warn("tree command fehlgeschlagen: #{stderr.strip} – nutze Python-Fallback")
      python_tree_fallback
    end
  rescue Errno::ENOENT
    @logger.warn('tree-Binary nicht installiert – nutze Python-Fallback')
    python_tree_fallback
  rescue StandardError => e
    @logger.error("tree command Exception: #{e}")
    nil
  end

  def update_tree_file(tree_output)
    # Schreibt tree-output in important/openclaw-tree.txt
    return false unless tree_output

    tree_file = IMPORTANT_DIR / 'openclaw-tree.txt'

    # Header mit Timestamp
    header = <<~HEADER
      # OpenClaw Workspace Tree
      # Generiert: #{Time.now.iso8601}
      # Befehl: tree -a -L 8 #{WORKSPACE}
      # Diese Datei wird automatisch von db-maintainer aktualisiert

    HEADER

    File.write(tree_file, header + tree_output)
    @logger.info("openclaw-tree.txt aktualisiert: #{tree_file}")
    true
  rescue StandardError => e
    @logger.error("Fehler beim Schreiben von openclaw-tree.txt: #{e}")
    false
  end

  def scan_documentations
    # Scannt alle .md Dateien auf Änderungen
    docs = []

    ['*.md', '**/*.md'].each do |pattern|
      Dir.glob(WORKSPACE / pattern).each do |md_file|
        path = Pathname.new(md_file)
        next unless path.file? && !path.symlink?

        relative_path = path.relative_path_from(WORKSPACE).to_s
        next if relative_path.include?('db/backups') || relative_path.include?('node_modules')

        docs << {
          path: relative_path,
          hash: get_file_hash(path),
          mtime: path.mtime.to_f
        }
      end
    end

    docs
  end

  def check_for_changes
    # Prüft auf Änderungen seit letztem Lauf
    state = load_state
    current_docs = scan_documentations

    changes = []
    current_hashes = {}

    current_docs.each do |doc|
      path = doc[:path]
      current_hashes[path] = doc[:hash]

      if state[:file_hashes][path].nil?
        changes << "NEW: #{path}"
      elsif state[:file_hashes][path] != doc[:hash]
        changes << "CHANGED: #{path}"
      end
    end

    # Prüfe auf gelöschte Dateien
    (state[:file_hashes].keys - current_hashes.keys).each do |old_path|
      changes << "DELETED: #{old_path}"
    end

    [changes, current_hashes]
  end

  def update_databases
    # Führt DB-Update-Scripts aus
    stdout, stderr, status = Open3.capture3('python3', (WORKSPACE / 'scripts' / 'update_docs_db.py').to_s)
    if status.success?
      @logger.info('docs.db aktualisiert')
      true
    else
      @logger.error("DB-Update fehlgeschlagen: #{stderr}")
      false
    end
  rescue StandardError => e
    @logger.error("DB-Update Exception: #{e}")
    false
  end

  def update_tree_db_v2
    # Führt tree_indexer_v2.py aus
    stdout, stderr, status = Open3.capture3('python3', (WORKSPACE / 'scripts' / 'tree_indexer_v2.py').to_s)
    if status.success?
      @logger.info('tree.db v2 aktualisiert')
      true
    else
      @logger.error("Tree-DB v2 fehlgeschlagen: #{stderr}")
      false
    end
  rescue StandardError => e
    @logger.error("Tree-DB v2 Exception: #{e}")
    false
  end

  def create_backup
    # Erstellt Backup beider Datenbanken
    timestamp = Time.now.strftime('%Y-%m-%d_%H-%M')

    %w[docs.db tree.db].each do |db_name|
      source = DB_DIR / db_name
      next unless source.exist?

      backup_name = "#{timestamp}_#{db_name}.bak"
      backup_path = BACKUP_DIR / backup_name
      FileUtils.cp(source, backup_path)
      @logger.info("Backup erstellt: #{backup_name}")
    end

    timestamp
  end

  def cleanup_old_backups
    # Löscht Backups älter als 3 Tage
    cutoff = Time.now - (@retention_days * 24 * 60 * 60)
    deleted = 0

    %w[docs.db tree.db].each do |db_name|
      Dir.glob(BACKUP_DIR / "*_#{db_name}.bak").each do |backup_path|
        backup = Pathname.new(backup_path)
        # Extrahiere Datum aus filename (Format: YYYY-MM-DD_HH-MM)
        begin
          parts = backup.basename.to_s.split('_')
          date_str = parts[0]
          time_str = parts[1]
          backup_time = Time.strptime("#{date_str}_#{time_str}", '%Y-%m-%d_%H-%M')

          if backup_time < cutoff
            backup.delete
            deleted += 1
            @logger.info("Altes Backup gelöscht: #{backup.basename}")
          end
        rescue StandardError
          @logger.warn("Konnte Backup-Datum nicht parsen: #{backup.basename}")
        end
      end
    end

    if deleted.zero?
      @logger.info('Keine alten Backups zum Löschen')
    else
      @logger.info("#{deleted} alte Backups gelöscht (< 3 Tage)")
    end
  end

  def run_cycle
    # Ein kompletter Wartungszyklus
    @logger.info('=' * 60)
    @logger.info('DB MAINTAINER CYCLE START')
    @logger.info('=' * 60)

    state = load_state

    # 1. Tree-Befehl ausführen und in openclaw-tree.txt schreiben
    @logger.info('Führe tree -a -L 8 aus...')
    tree_output = run_tree_command
    if tree_output
      update_tree_file(tree_output)
      state[:last_tree_update] = Time.now.iso8601
    end

    # 2. tree.db aktualisieren (intern v2)
    @logger.info('Aktualisiere tree.db v2...')
    update_tree_db_v2

    # 3. Änderungen prüfen
    @logger.info('Prüfe auf Dokumentations-Änderungen...')
    changes, current_hashes = check_for_changes

    if changes.any?
      @logger.info("#{changes.length} Änderungen gefunden:")
      changes.first(10).each { |change| @logger.info("  - #{change}") }
      @logger.info("  ... und #{changes.length - 10} weitere") if changes.length > 10

      # 4. docs.db aktualisieren
      @logger.info('Aktualisiere docs.db...')
      if update_databases
        state[:last_check] = Time.now.iso8601
        state[:file_hashes] = current_hashes
      end
    else
      @logger.info('Keine Dokumentations-Änderungen gefunden')
    end

    # 5. Prüfe ob Backup fällig (stündlich)
    last_backup = state[:last_backup]

    do_backup = if last_backup
                   last_backup_time = Time.iso8601(last_backup)
                   Time.now - last_backup_time >= 3600 # 1 hour in seconds
                 else
                   true
                 end

    if do_backup
      @logger.info('Erstelle stündliches Backup...')
      timestamp = create_backup
      state[:last_backup] = Time.now.iso8601

      # 6. Alte Backups aufräumen (3 Tage Retention)
      @logger.info('Räume alte Backups auf (3 Tage Retention)...')
      cleanup_old_backups
    else
      @logger.info('Backup nicht nötig (letztes < 1h)')
    end

    save_state(state)

    @logger.info('=' * 60)
    @logger.info('DB MAINTAINER CYCLE END')
    @logger.info('=' * 60)
  end
end

def main
  # Hauptfunktion
  maintainer = DatabaseMaintainer.new

  begin
    maintainer.run_cycle
  rescue StandardError => e
    maintainer.logger.error("CRITICAL ERROR: #{e}")
    exit(1)
  end
end

main if __FILE__ == $PROGRAM_NAME
