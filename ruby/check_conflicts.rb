#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "a4f32d5a87bf51bb9f64f5deb094c050f10b4bc618372ecf621882c7cee7d57c", "source_sha256": "5d90ebcd250a3cb80a0de664d94397af7ec03343d9d9fa64a28a9a11ad880754", "target_language": "ruby"}
# check_conflicts.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
# auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
# Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py

# Check Conflicts - Erkennt Sync-Konflikte

require 'pathname'
require 'digest'
require 'time'

# Import sync functions
$LOAD_PATH << '/home/openclaw/.openclaw/workspace/scripts'
load 'sync_clawhub_git.rb'

CLAWHUB_DIR = Pathname.new("/home/openclaw/.openclaw/workspace/skills")
GIT_DIR = Pathname.new("/home/openclaw/.openclaw/workspace/git/skills")

def get_file_hash(file_path)
  Digest::SHA256.file(file_path).hexdigest
end

def check_conflicts
  conflicts = []
  
  # Alle Skills die in beiden Orten existieren
  common_skills = []
  if CLAWHUB_DIR.exist? && GIT_DIR.exist?
    clawhub_skills = CLAWHUB_DIR.children.select(&:directory?).map(&:basename).map(&:to_s).to_set
    git_skills = GIT_DIR.children.select(&:directory?).map(&:basename).map(&:to_s).to_set
    common_skills = clawhub_skills & git_skills
  end
  
  puts "Prüfe #{common_skills.length} Skills auf Konflikte...\n"
  
  common_skills.sort.each do |skill|
    clawhub_path = CLAWHUB_DIR + skill
    git_path = GIT_DIR + skill
    
    # Alle Dateien vergleichen
    skill_conflicts = []
    
    # ClawHub Dateien
    clawhub_files = {}
    clawhub_path.find do |f|
      if f.file? && !f.to_s.include?('.git')
        rel_path = f.relative_path_from(clawhub_path).to_s
        clawhub_files[rel_path] = f
      end
    end
    
    # Git Dateien
    git_files = {}
    git_path.find do |f|
      if f.file? && !f.to_s.include?('.git')
        rel_path = f.relative_path_from(git_path).to_s
        git_files[rel_path] = f
      end
    end
    
    # Vergleiche gemeinsame Dateien
    (clawhub_files.keys & git_files.keys).each do |rel_path|
      clawhub_file = clawhub_files[rel_path]
      git_file = git_files[rel_path]
      
      if get_file_hash(clawhub_file) != get_file_hash(git_file)
        clawhub_mtime = File.mtime(clawhub_file)
        git_mtime = File.mtime(git_file)
        
        skill_conflicts.push({
          "file" => rel_path,
          "clawhub_modified" => clawhub_mtime.strftime('%Y-%m-%d %H:%M:%S'),
          "git_modified" => git_mtime.strftime('%Y-%m-%d %H:%M:%S'),
          "newer" => clawhub_mtime > git_mtime ? "clawhub" : "git"
        })
      end
    end
    
    if !skill_conflicts.empty?
      conflicts.push({
        "skill" => skill,
        "conflicts" => skill_conflicts
      })
    end
  end
  
  # Ausgabe
  if !conflicts.empty?
    puts "⚠️  KONFLIKTE GEFUNDEN:"
    puts "=" * 80
    
    conflicts.each do |conflict|
      puts "\n📦 Skill: #{conflict['skill']}"
      puts "-" * 40
      
      conflict['conflicts'].each do |file_conflict|
        puts "  📄 #{file_conflict['file']}"
        puts "     ClawHub: #{file_conflict['clawhub_modified']}"
        puts "     Git:     #{file_conflict['git_modified']}"
        puts "     Neuer:   #{file_conflict['newer'].upcase}"
        puts
      end
    end
    
    puts "=" * 80
    puts "Gesamt: #{conflicts.length} Skills mit Konflikten"
    puts "\nNutze 'sync_utils/scripts/resolve_conflict.py' zum Auflösen."
  else
    puts "✅ Keine Konflikte gefunden!"
    puts "Alle gemeinsamen Skills sind synchron."
  end
end

def main
  check_conflicts
end

main if __FILE__ == $0
