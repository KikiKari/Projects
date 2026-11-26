<?php
// abstraction-provenance: {"artifact_sha256": "aa173e468fa00e854493f081090a03ea168caf05fef8aa2e1835df9bb76d31fe", "source_sha256": "42646f32f72b1ca4e041673cd4a65a4b6611379252e110d53df9fb001a5ba6de", "target_language": "php"}
// git_source_inventory.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/git_source_inventory.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Git tree inventory and batched selected-blob loading.
 */

class GitSourceInventory {
    
    public static function write_private($path, $data) {
        $fd = fopen($path, 'x');
        if ($fd === false) {
            throw new Exception("Failed to open file for writing: $path");
        }
        fwrite($fd, $data);
        fclose($fd);
        chmod($path, 0600);
    }
    
    public static function snapshot($manager, $run_id, $run_attempt, $workflow_sha) {
        $repositories = [];
        
        foreach ($manager->QUELLEN as $source) {
            $name = (string)$source['repo'];
            $mirror = $manager->QUELLEN_DIR . '/' . $name . '.git';
            
            $git = function(...$args) use ($mirror) {
                $command = ['git', '-C', $mirror];
                $command = array_merge($command, $args);
                $process = proc_open(
                    implode(' ', array_map('escapeshellarg', $command)),
                    [
                        0 => ['pipe', 'r'],
                        1 => ['pipe', 'w'],
                        2 => ['pipe', 'w']
                    ],
                    $pipes
                );
                
                if (!is_resource($process)) {
                    throw new Exception('Failed to start git process');
                }
                
                fclose($pipes[0]);
                $output = stream_get_contents($pipes[1]);
                $error = stream_get_contents($pipes[2]);
                fclose($pipes[1]);
                fclose($pipes[2]);
                
                $return_code = proc_close($process);
                if ($return_code !== 0) {
                    throw new Exception("Git command failed: $error");
                }
                
                return $output;
            };
            
            $refs_output = $git('for-each-ref', '--format=%(refname:strip=2)%00%(objectname)', 'refs/heads');
            $refs = explode("\n", trim($refs_output));
            $selected = [];
            
            foreach ($refs as $line) {
                if (empty($line)) continue;
                $parts = explode("\0", $line);
                $branch_bytes = $parts[0];
                $commit = $parts[1];
                $branch = $branch_bytes;
                
                if ($source['branches'] === 'alle' || in_array($branch, $source['branches'])) {
                    $selected[] = [$branch, $commit];
                }
            }
            
            $branches = [];
            foreach ($selected as $item) {
                list($branch, $commit) = $item;
                $ls_tree_output = $git('ls-tree', '-r', '-z', '--full-tree', $commit);
                $entries = explode("\0", $ls_tree_output);
                $paths = [];
                
                foreach ($entries as $entry) {
                    if (empty($entry)) continue;
                    $parts = explode("\t", $entry, 2);
                    $meta = $parts[0];
                    $path = $parts[1];
                    $meta_parts = explode(' ', $meta);
                    
                    if ($meta_parts[1] === 'blob') {
                        $pathinfo = pathinfo($path);
                        $extension = isset($pathinfo['extension']) ? '.' . strtolower($pathinfo['extension']) : '';
                        if (array_key_exists($extension, $manager->QUELLSPRACHEN)) {
                            $paths[] = $path;
                        }
                    }
                }
                
                $branches[$branch] = ['commit' => $commit, 'paths' => $paths];
            }
            
            if (empty($branches) || ($source['branches'] !== 'alle' && array_diff(array_keys($branches), $source['branches']))) {
                throw new Exception('incomplete source branches');
            }
            
            $repositories[$name] = $branches;
        }
        
        return [
            'version' => 1,
            'run_id' => $run_id,
            'run_attempt' => $run_attempt,
            'workflow_sha' => $workflow_sha,
            'repositories' => $repositories
        ];
    }
    
    public static function prepare_git_sources($manager, $directory, $state, $priority, $count, $run_id, $run_attempt, $workflow_sha) {
        $manager->QUELLEN_DIR = $manager->QUELLEN_DIR ?? '/tmp';
        
        if (!file_exists($manager->QUELLEN_DIR)) {
            mkdir($manager->QUELLEN_DIR, 0755, true);
        }
        
        foreach ($manager->QUELLEN as $source) {
            $repo = (string)$source['repo'];
            $mirror = $manager->QUELLEN_DIR . '/' . $repo . '.git';
            
            if (file_exists($mirror)) {
                $result = $manager->_git('remote', 'update', '--prune', ['verzeichnis' => $mirror]);
            } else {
                $url = "https://github.com/{$manager->GITHUB_BENUTZER}/{$repo}.git";
                $result = $manager->_git('clone', '--mirror', '--filter=blob:none', $url, $mirror);
            }
            
            if ($result['returncode'] !== 0) {
                throw new Exception("$repo: Quellspiegel nicht verfuegbar");
            }
        }
        
        $index = self::snapshot($manager, $run_id, $run_attempt, $workflow_sha);
        $sources = [];
        
        $list_branch = function($item) use ($manager) {
            list($repo, $branch, $commit) = $item;
            $mirror = $manager->QUELLEN_DIR . '/' . $repo . '.git';
            
            $git = function(...$args) use ($mirror) {
                $command = ['git', '-C', $mirror];
                $command = array_merge($command, $args);
                $process = proc_open(
                    implode(' ', array_map('escapeshellarg', $command)),
                    [
                        0 => ['pipe', 'r'],
                        1 => ['pipe', 'w'],
                        2 => ['pipe', 'w']
                    ],
                    $pipes
                );
                
                if (!is_resource($process)) {
                    throw new Exception('Failed to start git process');
                }
                
                fclose($pipes[0]);
                $output = stream_get_contents($pipes[1]);
                $error = stream_get_contents($pipes[2]);
                fclose($pipes[1]);
                fclose($pipes[2]);
                
                $return_code = proc_close($process);
                if ($return_code !== 0) {
                    throw new Exception("Git command failed: $error");
                }
                
                return $output;
            };
            
            $ls_tree_output = $git('ls-tree', '-r', '-z', '--full-tree', $commit);
            $items = explode("\0", $ls_tree_output);
            $records = [];
            
            foreach ($items as $item_str) {
                if (empty($item_str)) continue;
                $parts = explode("\t", $item_str, 2);
                $metadata = $parts[0];
                $raw_path = $parts[1];
                $metadata_parts = explode(' ', $metadata);
                
                if (count($metadata_parts) < 3) continue;
                
                $mode = $metadata_parts[0];
                $kind = $metadata_parts[1];
                $oid = $metadata_parts[2];
                
                if ($kind !== 'blob' || !in_array($mode, ['100644', '100755'])) {
                    continue;
                }
                
                $path = str_replace('\\\\', '/', $raw_path);
                $pathinfo = pathinfo($path);
                $extension = isset($pathinfo['extension']) ? '.' . strtolower($pathinfo['extension']) : '';
                $language = $manager->QUELLSPRACHEN[$extension] ?? null;
                
                $exclude = false;
                foreach ($manager->AUSSCHLUSS as $pattern) {
                    if (strpos('/' . $path, $pattern) !== false) {
                        $exclude = true;
                        break;
                    }
                }
                
                if ($language === null || $exclude) {
                    continue;
                }
                
                if (!preg_match('/^[0-9a-f]{40}$/', $oid)) {
                    throw new Exception('invalid Git blob identity');
                }
                
                $records[] = [$repo, $branch, $commit, $path, $language, $oid];
            }
            
            return $records;
        };
        
        $branches = [];
        foreach ($index['repositories'] as $repo => $details) {
            foreach ($details as $branch => $data) {
                $branches[] = [$repo, $branch, $data['commit']];
            }
        }
        
        $results = [];
        foreach ($branches as $branch_item) {
            $results[] = $list_branch($branch_item);
        }
        
        foreach ($results as $records) {
            foreach ($records as $record) {
                $sources[] = $record;
            }
        }
        
        $grouped = [];
        foreach ($sources as $source) {
            list($repo, $branch, $commit, $path, $language, $oid) = $source;
            $origin = "$repo@$branch:$path";
            
            if (!isset($grouped[$oid])) {
                $grouped[$oid] = [
                    'blob' => $oid,
                    'repo' => $repo,
                    'commit' => $commit,
                    'path' => $path,
                    'sprache' => $language,
                    'herkunft' => [],
                    'prioritaet' => $manager->_prioritaet($path, $language)
                ];
            }
            
            $grouped[$oid]['herkunft'][] = $origin;
        }
        
        $rank = ['high' => 0, 'medium' => 1, 'low' => 2];
        $candidates = [];
        
        foreach ($grouped as $item) {
            if ($priority === 'alle' || $item['prioritaet'] === $priority) {
                $candidates[] = $item;
            }
        }
        
        usort($candidates, function($a, $b) use ($rank) {
            $priority_rank_a = $rank[$a['prioritaet']] ?? 999;
            $priority_rank_b = $rank[$b['prioritaet']] ?? 999;
            
            if ($priority_rank_a !== $priority_rank_b) {
                return $priority_rank_a - $priority_rank_b;
            }
            
            return strcmp(basename($a['path']), basename($b['path']));
        });
        
        $cursor = null;
        if (isset($state['auswahl_blob_cursor'][$priority])) {
            $cursor = $state['auswahl_blob_cursor'][$priority];
        }
        
        if ($cursor) {
            $pos = null;
            foreach ($candidates as $i => $item) {
                if ($item['blob'] === $cursor) {
                    $pos = $i;
                    break;
                }
            }
            
            if ($pos !== null) {
                $candidates = array_merge(
                    array_slice($candidates, $pos + 1),
                    array_slice($candidates, 0, $pos + 1)
                );
            }
        }
        
        $selected = array_slice($candidates, 0, $count);
        $by_repo = [];
        
        foreach ($selected as $item) {
            if (!isset($by_repo[$item['repo']])) {
                $by_repo[$item['repo']] = [];
            }
            $by_repo[$item['repo']][] = $item;
        }
        
        $read_blobs = function($pair) use ($manager) {
            list($repo, $items) = $pair;
            $mirror = $manager->QUELLEN_DIR . '/' . $repo . '.git';
            
            $requested = '';
            foreach ($items as $item) {
                $requested .= $item['blob'] . "\n";
            }
            
            $git_batch_check = function($data) use ($mirror) {
                $command = ['git', '-C', $mirror, 'cat-file', '--batch-check=%(objectname) %(objecttype) %(objectsize)'];
                $process = proc_open(
                    implode(' ', array_map('escapeshellarg', $command)),
                    [
                        0 => ['pipe', 'r'],
                        1 => ['pipe', 'w'],
                        2 => ['pipe', 'w']
                    ],
                    $pipes
                );
                
                if (!is_resource($process)) {
                    throw new Exception('Failed to start git process');
                }
                
                fwrite($pipes[0], $data);
                fclose($pipes[0]);
                $output = stream_get_contents($pipes[1]);
                $error = stream_get_contents($pipes[2]);
                fclose($pipes[1]);
                fclose($pipes[2]);
                
                $return_code = proc_close($process);
                if ($return_code !== 0) {
                    throw new Exception("Git command failed: $error");
                }
                
                return $output;
            };
            
            $checks_output = $git_batch_check($requested);
            $checks = explode("\n", trim($checks_output));
            
            if (count($checks) !== count($items)) {
                throw new Exception('incomplete Git blob metadata');
            }
            
            $eligible = [];
            foreach ($items as $i => $item) {
                $line = $checks[$i];
                $fields = explode(' ', $line);
                
                if (count($fields) !== 3 || $fields[0] !== $item['blob'] || $fields[1] !== 'blob') {
                    throw new Exception('invalid Git blob metadata');
                }
                
                if ((int)$fields[2] <= $manager->MAX_BYTES) {
                    $eligible[] = [$item, (int)$fields[2]];
                }
            }
            
            if (empty($eligible)) {
                return [];
            }
            
            $wanted = '';
            foreach ($eligible as $elig) {
                list($item, $size) = $elig;
                $wanted .= $item['blob'] . "\n";
            }
            
            $git_batch = function($data) use ($mirror) {
                $command = ['git', '-C', $mirror, 'cat-file', '--batch'];
                $process = proc_open(
                    implode(' ', array_map('escapeshellarg', $command)),
                    [
                        0 => ['pipe', 'r'],
                        1 => ['pipe', 'w'],
                        2 => ['pipe', 'w']
                    ],
                    $pipes
                );
                
                if (!is_resource($process)) {
                    throw new Exception('Failed to start git process');
                }
                
                fwrite($pipes[0], $data);
                fclose($pipes[0]);
                $output = stream_get_contents($pipes[1]);
                $error = stream_get_contents($pipes[2]);
                fclose($pipes[1]);
                fclose($pipes[2]);
                
                $return_code = proc_close($process);
                if ($return_code !== 0) {
                    throw new Exception("Git command failed: $error");
                }
                
                return $output;
            };
            
            $output_data = $git_batch($wanted);
            $output = fopen('php://memory', 'r+');
            fwrite($output, $output_data);
            rewind($output);
            
            $result = [];
            foreach ($eligible as $elig) {
                list($item, $size) = $elig;
                $header_line = fgets($output);
                $header = explode(' ', rtrim($header_line, "\n"));
                
                if (count($header) !== 3 || $header[0] !== $item['blob'] || $header[1] !== 'blob' || (int)$header[2] !== $size) {
                    throw new Exception('invalid Git blob response');
                }
                
                $raw = fread($output, $size);
                $newline = fread($output, 1);
                
                if (strlen($raw) !== $size || $newline !== "\n") {
                    throw new Exception('incomplete Git blob response');
                }
                
                $result[] = [$item, $raw];
            }
            
            fclose($output);
            return $result;
        };
        
        $loaded = [];
        foreach ($by_repo as $repo => $items) {
            $result = $read_blobs([$repo, $items]);
            foreach ($result as $res) {
                list($item, $raw) = $res;
                $loaded[$item['blob']] = $raw;
            }
        }
        
        $source_dir = $directory . '/sources';
        if (!file_exists($source_dir)) {
            mkdir($source_dir, 0700, true);
        }
        
        $inventory = [];
        foreach ($selected as $item) {
            $raw = $loaded[$item['blob']] ?? null;
            
            if ($raw === null || trim($raw) === '' || $manager->enthaelt_zugangsdaten($raw)) {
                continue;
            }
            
            $digest = hash('sha256', $raw);
            $target = $source_dir . '/' . $digest;
            
            if (!file_exists($target)) {
                self::write_private($target, $raw);
            }
            
            $source_path_parts = pathinfo($item['path']);
            $inventory[] = [
                'hash' => substr($digest, 0, 16),
                'name' => $source_path_parts['basename'] ?? '',
                'stamm' => $source_path_parts['filename'] ?? '',
                'sprache' => $item['sprache'],
                'bytes' => strlen($raw),
                'pfad' => $target,
                'herkunft' => $item['herkunft'],
                'prioritaet' => $item['prioritaet'],
                'css_only' => false,
                'source_blob' => $item['blob'],
                'source_repo' => $item['repo'],
                'source_commit' => $item['commit'],
                'source_path' => $item['path'],
                'source_sha256' => $digest
            ];
        }
        
        $last_blob = null;
        if (!empty($selected)) {
            $last_blob = end($selected)['blob'];
        }
        
        return [$index, $inventory, $last_blob];
    }
}
