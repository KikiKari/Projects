#!/usr/bin/env ruby
# abstraction-provenance: {"artifact_sha256": "02c65930ebd5eb46638099964cd088751633475e193ad1e9fcc045c62fe17e63", "source_sha256": "42646f32f72b1ca4e041673cd4a65a4b6611379252e110d53df9fb001a5ba6de", "target_language": "ruby"}
# git_source_inventory.py — portiert nach ruby
# Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/git_source_inventory.py
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

# Git tree inventory and batched selected-blob loading.
require 'pathname'
require 'fileutils'
require 'digest'
require 'thread'
require 'open3'

def write_private(path, data)
  File.open(path, File::CREAT | File::EXCL | File::WRONLY, 0600) do |file|
    file.write(data)
  end
end

def snapshot(manager, run_id, run_attempt, workflow_sha)
  repository_index = lambda do |source|
    name = source['repo'].to_s
    mirror = manager.QUELLEN_DIR / "#{name}.git"

    git = lambda do |*args|
      stdin, stdout, stderr, wait_thr = Open3.popen3('git', '-C', mirror.to_s, *args)
      stdin.close
      result = stdout.read
      stdout.close
      stderr.close
      raise "Git command failed" unless wait_thr.value.success?
      result
    end

    refs_output = git.call('for-each-ref', '--format=%(refname:strip=2)%00%(objectname)', 'refs/heads')
    refs = refs_output.split("\n")
    selected = []
    
    refs.each do |line|
      branch_bytes, commit = line.split("\0", 2)
      branch = branch_bytes.force_encoding('UTF-8')
      if source['branches'] == 'alle' || source['branches'].include?(branch)
        selected.push([branch, commit])
      end
    end

    branch_index = lambda do |item|
      branch, commit = item
      paths = []
      ls_tree_output = git.call('ls-tree', '-r', '-z', '--full-tree', commit)
      ls_tree_output.split("\0").each do |entry|
        next if entry.empty?
        meta, path = entry.split("\t", 2)
        text = path.force_encoding('UTF-8')
        if meta.split(' ')[1] == 'blob' && manager.QUELLSPRACHEN.include?(Pathname.new(text).extname.downcase)
          paths.push(text)
        end
      end
      [branch, {'commit' => commit, 'paths' => paths}]
    end

    threads = []
    branch_results = {}
    selected.each do |item|
      threads << Thread.new do
        result = branch_index.call(item)
        branch_results[result[0]] = result[1]
      end
    end
    threads.each(&:join)

    branches = branch_results
    if branches.empty? || (source['branches'] != 'alle' && branches.keys.to_set != source['branches'].to_set)
      raise 'incomplete source branches'
    end
    [name, branches]
  end

  threads = []
  repo_results = {}
  manager.QUELLEN.each do |source|
    threads << Thread.new do
      result = repository_index.call(source)
      repo_results[result[0]] = result[1]
    end
  end
  threads.each(&:join)

  repositories = repo_results
  {
    'version' => 1,
    'run_id' => run_id,
    'run_attempt' => run_attempt,
    'workflow_sha' => workflow_sha,
    'repositories' => repositories
  }
end

def prepare_git_sources(manager, directory, state, priority, count, run_id, run_attempt, workflow_sha)
  # Index pinned Git trees and materialize only selected source blobs.
  
  git = lambda do |mirror, *args, data: nil|
    stdin, stdout, stderr, wait_thr = Open3.popen3('git', '-C', mirror.to_s, *args)
    if data
      stdin.write(data)
    end
    stdin.close
    result = stdout.read
    stdout.close
    stderr.close
    raise "Git command failed" unless wait_thr.value.success?
    result
  end

  FileUtils.mkdir_p(manager.QUELLEN_DIR, mode: 0755)

  update = lambda do |source|
    repo = source['repo'].to_s
    mirror = manager.QUELLEN_DIR / "#{repo}.git"
    if mirror.exist?
      result = manager._git('remote', 'update', '--prune', verzeichnis: mirror)
    else
      url = "https://github.com/#{manager.GITHUB_BENUTZER}/#{repo}.git"
      result = manager._git('clone', '--mirror', '--filter=blob:none', url, mirror.to_s)
    end
    raise "#{repo}: Quellspiegel nicht verfuegbar" unless result.success?
  end

  threads = []
  manager.QUELLEN.each do |source|
    threads << Thread.new { update.call(source) }
  end
  threads.each(&:join)

  index = snapshot(manager, run_id, run_attempt, workflow_sha)
  sources = []

  list_branch = lambda do |item|
    repo, branch, commit = item
    mirror = manager.QUELLEN_DIR / "#{repo}.git"
    records = []
    ls_tree_output = git.call(mirror, 'ls-tree', '-r', '-z', '--full-tree', commit)
    ls_tree_output.split("\0").each do |entry|
      next if entry.empty?
      metadata, raw_path = entry.split("\t", 2)
      mode, kind, oid = metadata.split(' ', 3)
      next if kind != 'blob' || !['100644', '100755'].include?(mode)
      path = raw_path.force_encoding('UTF-8').gsub('\\\\', '/')
      language = manager.QUELLSPRACHEN[Pathname.new(path).extname.downcase]
      next if language.nil? || manager.AUSSCHLUSS.any? { |pattern| "/#{path}".include?(pattern) }
      raise 'invalid Git blob identity' unless oid.match?(/[0-9a-f]{40}/)
      records.push([repo, branch, commit, path, language, oid])
    end
    records
  end

  branches = []
  index['repositories'].each do |repo, details|
    details.each do |branch, data|
      branches.push([repo, branch, data['commit']])
    end
  end

  threads = []
  branch_results = []
  branches.each do |branch_item|
    threads << Thread.new do
      result = list_branch.call(branch_item)
      branch_results.push(result)
    end
  end
  threads.each(&:join)

  branch_results.each do |records|
    sources.concat(records)
  end

  grouped = {}
  sources.each do |repo, branch, commit, path, language, oid|
    origin = "#{repo}@#{branch}:#{path}"
    item = grouped[oid]
    if item.nil?
      item = {
        'blob' => oid,
        'repo' => repo,
        'commit' => commit,
        'path' => path,
        'sprache' => language,
        'herkunft' => [],
        'prioritaet' => manager._prioritaet(path, language)
      }
      grouped[oid] = item
    end
    item['herkunft'].push(origin)
  end

  rank = {'high' => 0, 'medium' => 1, 'low' => 2}
  candidates = grouped.values.select do |item|
    priority == 'alle' || item['prioritaet'] == priority
  end.sort_by do |item|
    [rank[item['prioritaet']], Pathname.new(item['path']).basename.to_s]
  end

  cursor = state.dig('auswahl_blob_cursor', priority)
  if cursor
    pos = candidates.find_index { |item| item['blob'] == cursor }
    if pos
      candidates = candidates[pos + 1..-1] + candidates[0..pos]
    end
  end

  selected = candidates.first(count)
  by_repo = {}
  selected.each do |item|
    repo_list = by_repo[item['repo']] || []
    repo_list.push(item)
    by_repo[item['repo']] = repo_list
  end

  read_blobs = lambda do |pair|
    repo, items = pair
    mirror = manager.QUELLEN_DIR / "#{repo}.git"
    requested = items.map { |item| "#{item['blob']}\n" }.join
    checks_output = git.call(mirror, 'cat-file', '--batch-check=%(objectname) %(objecttype) %(objectsize)', data: requested)
    checks = checks_output.split("\n")
    raise 'incomplete Git blob metadata' if checks.length != items.length
    
    eligible = []
    items.zip(checks).each do |item, line|
      fields = line.split
      raise 'invalid Git blob metadata' if fields.length != 3 || fields[0] != item['blob'] || fields[1] != 'blob'
      if fields[2].to_i <= manager.MAX_BYTES
        eligible.push([item, fields[2].to_i])
      end
    end
    
    return [] if eligible.empty?
    
    wanted = eligible.map { |item, _| "#{item['blob']}\n" }.join
    output = StringIO.new(git.call(mirror, '--batch', data: wanted))
    result = []
    
    eligible.each do |item, size|
      header_line = output.gets.chomp
      header = header_line.split
      raise 'invalid Git blob response' if header.length != 3 || header[0] != item['blob'] || header[1] != 'blob' || header[2].to_i != size
      
      raw = output.read(size)
      raise 'incomplete Git blob response' if raw.length != size || output.read(1) != "\n"
      result.push([item, raw])
    end
    result
  end

  loaded = {}
  threads = []
  read_results = []
  by_repo.each do |repo, items|
    threads << Thread.new do
      result = read_blobs.call([repo, items])
      read_results.push(result)
    end
  end
  threads.each(&:join)

  read_results.each do |result_array|
    result_array.each do |item, raw|
      loaded[item['blob']] = raw
    end
  end

  source_dir = Pathname.new(directory) / 'sources'
  FileUtils.mkdir_p(source_dir, mode: 0700)
  inventory = []
  
  selected.each do |item|
    raw = loaded[item['blob']]
    next if raw.nil? || raw.strip.empty? || manager.enthaelt_zugangsdaten(raw)
    
    digest = Digest::SHA256.hexdigest(raw)
    target = source_dir / digest
    write_private(target, raw) unless target.exist?
    
    source_path = Pathname.new(item['path'])
    inventory.push({
      'hash' => digest[0..15],
      'name' => source_path.basename.to_s,
      'stamm' => source_path.stem.to_s,
      'sprache' => item['sprache'],
      'bytes' => raw.length,
      'pfad' => target.to_s,
      'herkunft' => item['herkunft'],
      'prioritaet' => item['prioritaet'],
      'css_only' => false,
      'source_blob' => item['blob'],
      'source_repo' => item['repo'],
      'source_commit' => item['commit'],
      'source_path' => item['path'],
      'source_sha256' => digest
    })
  end
  
  last_blob = selected.empty? ? nil : selected.last['blob']
  [index, inventory, last_blob]
end
