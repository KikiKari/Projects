#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "d1a8c9733a53827b156923c74261f19a60136e9eb74f759d70a7731ddb35ed78", "source_sha256": "4c10c6b6fd911cb95da119f761f402073d1a836cab6b40a9f3b989536d5df5ec", "target_language": "ruby"}
# git_publish.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
# auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Git Publish Agent - Automatisierte Skill-Veröffentlichung

require 'optparse'
require 'pathname'
require 'date'
require 'open3'

SKILLS_DIR = Pathname.new(Dir.home) / '.openclaw' / 'workspace' / 'skills'

def git_commit(skill_path, message = nil)
  # Commit skill changes.
  unless message
    message = "[skill] Auto-update #{skill_path.basename} - #{DateTime.now.iso8601}"
  end
  
  Open3.popen3('git', 'add', skill_path.to_s, chdir: SKILLS_DIR.parent) do |stdin, stdout, stderr, wait_thr|
    wait_thr.join
  end
  
  stdout_str, stderr_str, status = Open3.capture3('git', 'commit', '-m', message, chdir: SKILLS_DIR.parent)
  status.success?
end

def clawhub_publish(skill_name)
  # Publish to ClawHub.
  skill_path = SKILLS_DIR / skill_name
  stdout_str, stderr_str, status = Open3.capture3(
    'clawhub', 'publish', skill_path.to_s,
    '--slug', skill_name,
    '--version', '1.0.0'
  )
  [status.success?, stdout_str]
end

def batch_publish
  # Publish all changed skills with rate limiting.
  # Check git status
  stdout_str, stderr_str, status = Open3.capture3(
    'git', 'status', '--short', SKILLS_DIR.to_s
  )
  
  changed = []
  stdout_str.split("\n").each do |line|
    line.strip!
    if !line.empty? && line.include?('skills/')
      skill = line.split('skills/')[-1].split('/')[0]
      unless changed.include?(skill)
        changed.push(skill)
      end
    end
  end
  
  puts "Changed skills: #{changed}"
  
  # Publish with delay
  changed.first(5).each_with_index do |skill, i| # Max 5 per batch
    if i > 0
      puts "Waiting 15min for rate limit..."
      # In real: sleep(900)
    end
    
    puts "Publishing #{skill}..."
    commit_ok = git_commit(SKILLS_DIR / skill)
    if commit_ok
      pub_ok, output = clawhub_publish(skill)
      puts "  #{pub_ok ? '✓' : '✗'} #{output}"
    end
  end
end

def main
  options = {}
  OptionParser.new do |parser|
    parser.banner = "Usage: git_publish.rb [options]"
    parser.on("--skill SKILL", "Single skill to publish") do |skill|
      options[:skill] = skill
    end
    parser.on("--all", "Publish all changed") do
      options[:all] = true
    end
    parser.on("--no-publish", "Commit only") do
      options[:no_publish] = true
    end
    parser.on("--message MESSAGE", "Custom commit message") do |message|
      options[:message] = message
    end
  end.parse!

  if options[:skill]
    skill_path = SKILLS_DIR / options[:skill]
    if options[:no_publish]
      git_commit(skill_path, options[:message])
    else
      git_commit(skill_path, options[:message])
      clawhub_publish(options[:skill])
    end
  elsif options[:all]
    batch_publish()
  else
    puts "Use --skill <name> or --all"
  end
end

main if __FILE__ == $0
