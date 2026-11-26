<?php
// abstraction-provenance: {"artifact_sha256": "257328082e843bbb9ce7be5b2fa195d9867f5bb64686970582190358293d42f7", "source_sha256": "dfe62418dcbef9ea8aa7f18ada4f57d0ef73593432b7c7cefd85ee87eee622b4", "target_language": "php"}
// github_publisher.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/github_publisher.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Publish queued, provenance-checked artifacts without staging unrelated files.
 */

const LANGUAGES = ["perl5", "powershell", "perl6", "tcl", "javascript", "ruby", "python", "lua", "shell", "go", "java", "c", "cpp", "php", "fsharp", "css"];

function synchronize_checkout($root, $remote = "https://github.com/KikiKari/OpenClaw.git", $branch = "gateway1-abstractions") {
    $root = realpath($root);
    if ($root === false) {
        throw new Exception("Invalid root path");
    }
    
    $tmp = tempnam(sys_get_temp_dir(), "abstractions-snapshot-");
    unlink($tmp);
    mkdir($tmp);
    
    try {
        $snapshot = $tmp . "/repo";
        
        $clone_process = proc_open(
            ["git", "clone", "--quiet", "--depth=1", "--single-branch", "--branch", $branch, "--", $remote, $snapshot],
            [
                0 => ["pipe", "r"],
                1 => ["pipe", "w"],
                2 => ["pipe", "w"]
            ],
            $pipes
        );
        
        if (!is_resource($clone_process)) {
            throw new Exception("Failed to start git clone process");
        }
        
        $status = proc_get_status($clone_process);
        $start_time = time();
        
        while ($status['running']) {
            if (time() - $start_time > 300) {
                proc_terminate($clone_process);
                throw new Exception("Git clone timed out");
            }
            usleep(100000); // 0.1 second
            $status = proc_get_status($clone_process);
        }
        
        $exit_code = proc_close($clone_process);
        if ($exit_code !== 0) {
            throw new Exception("Git clone failed with exit code: " . $exit_code);
        }
        
        // Get revision
        $revision_process = proc_open(
            ["git", "-C", $snapshot, "rev-parse", "HEAD"],
            [
                0 => ["pipe", "r"],
                1 => ["pipe", "w"],
                2 => ["pipe", "w"]
            ],
            $pipes
        );
        
        if (!is_resource($revision_process)) {
            throw new Exception("Failed to start git rev-parse process");
        }
        
        $start_time = time();
        $status = proc_get_status($revision_process);
        while ($status['running']) {
            if (time() - $start_time > 30) {
                proc_terminate($revision_process);
                throw new Exception("Git rev-parse timed out");
            }
            usleep(100000); // 0.1 second
            $status = proc_get_status($revision_process);
        }
        
        $revision = stream_get_contents($pipes[1]);
        fclose($pipes[1]);
        proc_close($revision_process);
        $revision = trim($revision);
        
        $counts = [];
        foreach (LANGUAGES as $language) {
            $source = $snapshot . "/" . $language;
            $target = $root . "/" . $language;
            
            if (is_link($source) || is_link($target)) {
                throw new Exception("Language directory is a symlink");
            }
            
            if (file_exists($source) && !is_dir($source)) {
                throw new Exception("Invalid remote language directory");
            }
            
            if (!file_exists($target)) {
                mkdir($target, 0755, true);
            } elseif (!is_dir($target)) {
                throw new Exception("Target exists but is not a directory");
            }
            
            $known = [];
            $files_in_target = scandir($target);
            foreach ($files_in_target as $file) {
                if ($file === '.' || $file === '..') continue;
                $full_path = $target . "/" . $file;
                if (is_file($full_path) && !is_link($full_path)) {
                    $known[hash_file('sha256', $full_path)] = true;
                }
            }
            
            $files = [];
            if (file_exists($source)) {
                $source_files = scandir($source);
                foreach ($source_files as $file) {
                    if ($file === '.' || $file === '..') continue;
                    $full_path = $source . "/" . $file;
                    if (is_link($full_path) || !is_file($full_path)) {
                        throw new Exception("Invalid remote abstraction");
                    }
                    $files[] = $full_path;
                }
            }
            
            usort($files, function($a, $b) {
                return strcmp(basename($a), basename($b));
            });
            
            $counts[$language] = count($files);
            
            foreach ($files as $item) {
                $data = file_get_contents($item);
                $digest = hash('sha256', $data);
                
                if (isset($known[$digest])) {
                    continue;
                }
                
                $destination = $target . "/" . basename($item);
                if (file_exists($destination) || is_link($destination)) {
                    $pathinfo = pathinfo($item);
                    $destination = $target . "/" . $pathinfo['filename'] . "__pool_" . $digest . (isset($pathinfo['extension']) ? "." . $pathinfo['extension'] : "");
                }
                
                if (file_exists($destination) || is_link($destination)) {
                    if (is_link($destination) || !is_file($destination) || file_get_contents($destination) !== $data) {
                        throw new Exception("Local abstraction conflict");
                    }
                } else {
                    file_put_contents($destination, $data, LOCK_EX);
                }
                
                $known[$digest] = true;
            }
        }
        
        return [$revision, $counts];
    } finally {
        // Clean up temporary directory
        if (file_exists($tmp)) {
            $iterator = new RecursiveIteratorIterator(
                new RecursiveDirectoryIterator($tmp, RecursiveDirectoryIterator::SKIP_DOTS),
                RecursiveIteratorIterator::CHILD_FIRST
            );
            
            foreach ($iterator as $file) {
                if ($file->isDir()) {
                    rmdir($file->getPathname());
                } else {
                    unlink($file->getPathname());
                }
            }
            rmdir($tmp);
        }
    }
}

function update_status_counts($path, $revision, $counts) {
    $text = file_get_contents($path);
    if ($text === false) {
        throw new Exception("Could not read STATUS.md file");
    }
    
    $rows = ["## Bestand", "", "GitHub-Stand: `{$revision}`", "", "| Zielsprache | Dateien |", "|---|---:|"];
    
    foreach (LANGUAGES as $language) {
        $rows[] = "| {$language} | {$counts[$language]} |";
    }
    
    $rows[] = "| **gesamt** | **" . array_sum($counts) . "** |";
    $rows[] = "";
    $rows[] = "";
    
    $updated = preg_replace('/(?ms)^## Bestand\n.*?(?=^## Quellen\n)/', implode("\n", $rows), $text, 1, $count);
    
    if ($count !== 1) {
        throw new Exception("Status inventory section missing");
    }
    
    file_put_contents($path, $updated);
}

function queue_artifact(&$state, $root, $path) {
    $root = realpath($root);
    if ($root === false) {
        throw new Exception("Invalid root path");
    }
    
    if (is_link($path)) {
        throw new Exception("Artifact must not be a symlink");
    }
    
    $real_path = realpath($path);
    if ($real_path === false) {
        throw new Exception("Path does not exist");
    }
    
    $relative = str_replace('\\', '/', substr($real_path, strlen($root) + 1));
    
    if ($relative !== 'STATUS.md' && (!explode('/', $relative)[0] || !in_array(explode('/', $relative)[0], LANGUAGES))) {
        throw new Exception("Artifact is outside a language directory");
    }
    
    if (!isset($state["ausstehende_veroeffentlichungen"])) {
        $state["ausstehende_veroeffentlichungen"] = [];
    }
    
    $state["ausstehende_veroeffentlichungen"][$relative] = hash_file('sha256', $path);
}

function publish_pending($root, &$state, $save, $token, $opener = null, $sync = null) {
    if ($opener === null) {
        $opener = function($request, $timeout = 60) {
            $context = stream_context_create([
                'http' => [
                    'method' => $request['method'],
                    'header' => $request['headers'],
                    'content' => $request['data'] ?? '',
                    'timeout' => $timeout
                ]
            ]);
            $result = file_get_contents($request['url'], false, $context);
            return ['body' => $result, 'headers' => $http_response_header];
        };
    }
    
    $pending = isset($state["ausstehende_veroeffentlichungen"]) ? $state["ausstehende_veroeffentlichungen"] : [];
    
    if (!is_array($pending)) {
        throw new Exception("Invalid publication queue");
    }
    
    if (empty($pending) && $sync === null) {
        return true;
    }
    
    if (!$token || !trim($token)) {
        return false;
    }
    
    $root = realpath($root);
    if ($root === false) {
        throw new Exception("Invalid root path");
    }
    
    $headers = [
        "Authorization: Bearer " . trim($token),
        "Accept: application/vnd.github+json",
        "X-GitHub-Api-Version: 2022-11-28",
        "User-Agent: abstractions-manager"
    ];
    
    $success = true;
    
    // Sort entries, putting STATUS.md last
    uksort($pending, function($a, $b) {
        if ($a === 'STATUS.md') return 1;
        if ($b === 'STATUS.md') return -1;
        return strcmp($a, $b);
    });
    
    $entries = [];
    foreach ($pending as $name => $expected) {
        $entries[] = [$name, $expected];
    }
    
    $synced = false;
    
    foreach ($entries as [$name, $expected]) {
        try {
            $path = $root . "/" . str_replace('/', DIRECTORY_SEPARATOR, $name);
            
            if (is_link($path)) {
                throw new Exception("Invalid queued path");
            }
            
            $real_path = realpath($path);
            if ($real_path === false) {
                throw new Exception("Path does not exist");
            }
            
            $relative_check = str_replace('\\', '/', substr($real_path, strlen($root) + 1));
            if ($relative_check !== $name) {
                throw new Exception("Invalid queued path");
            }
            
            $data = file_get_contents($path);
            if (hash('sha256', $data) !== $expected) {
                throw new Exception("Queued artifact changed");
            }
            
            if ($name === 'STATUS.md' && $sync !== null) {
                if (!$success) {
                    throw new Exception("Artifact publication incomplete");
                }
                
                list($revision, $counts) = $sync($root);
                $synced = true;
                update_status_counts($path, $revision, $counts);
                $data = file_get_contents($path);
                $expected = hash('sha256', $data);
                $pending[$name] = $expected;
                $state["ausstehende_veroeffentlichungen"] = $pending;
                call_user_func($save, $state);
            }
            
            $lookup = function($remote_name) use ($headers, $opener) {
                $endpoint = "https://api.github.com/repos/KikiKari/OpenClaw/contents/" . rawurlencode($remote_name);
                $request = [
                    'url' => $endpoint . "?ref=gateway1-abstractions",
                    'method' => 'GET',
                    'headers' => $headers
                ];
                
                try {
                    $response = $opener($request, 60);
                    $content = json_decode($response['body'], true);
                    return [$endpoint, $content];
                } catch (Exception $error) {
                    // Check if it's a 404 error by examining response headers
                    $is_404 = false;
                    if (isset($response['headers'])) {
                        foreach ($response['headers'] as $header) {
                            if (strpos($header, '404 Not Found') !== false) {
                                $is_404 = true;
                                break;
                            }
                        }
                    }
                    
                    if ($is_404) {
                        return [$endpoint, null];
                    }
                    throw $error;
                }
            };
            
            $same = function($existing, $data) {
                if (!is_array($existing)) return false;
                if (!isset($existing["encoding"]) || $existing["encoding"] !== "base64") return false;
                if (!isset($existing["content"])) return false;
                return base64_decode($existing["content"]) === $data;
            };
            
            list($endpoint, $existing) = $lookup($name);
            
            if ($name === 'STATUS.md' && $existing !== null && !$same($existing, $data)) {
                $sha = isset($existing['sha']) ? $existing['sha'] : null;
                if (!is_string($sha) || !$sha) {
                    throw new Exception('Missing remote status version');
                }
                
                $body = json_encode([
                    'message' => 'Update abstraction status',
                    'branch' => 'gateway1-abstractions',
                    'content' => base64_encode($data),
                    'sha' => $sha
                ]);
                
                $request = [
                    'url' => $endpoint,
                    'method' => 'PUT',
                    'headers' => $headers,
                    'data' => $body
                ];
                
                $response = $opener($request, 60);
                json_decode($response['body'], true);
            } elseif ($existing !== null && !$same($existing, $data)) {
                // Independent managers can derive different results for one
                // source. Preserve both without overwriting the remote file.
                $candidate_parts = explode('/', $name);
                $candidate_filename = array_pop($candidate_parts);
                $pathinfo = pathinfo($candidate_filename);
                $alternate_filename = $pathinfo['filename'] . "_" . substr($expected, 0, 12) . (isset($pathinfo['extension']) ? "." . $pathinfo['extension'] : "");
                $alternate = implode('/', $candidate_parts);
                if ($alternate) $alternate .= '/';
                $alternate .= $alternate_filename;
                
                list($endpoint, $existing) = $lookup($alternate);
                if ($existing !== null && !$same($existing, $data)) {
                    throw new Exception("Remote artifact conflict");
                }
            }
            
            if ($existing === null) {
                $body = json_encode([
                    "message" => "Publish script abstraction",
                    "branch" => "gateway1-abstractions",
                    "content" => base64_encode($data)
                ]);
                
                $request = [
                    'url' => $endpoint,
                    'method' => 'PUT',
                    'headers' => $headers,
                    'data' => $body
                ];
                
                $response = $opener($request, 60);
                json_decode($response['body'], true);
            }
            
            unset($pending[$name]);
            $state["ausstehende_veroeffentlichungen"] = $pending;
            call_user_func($save, $state);
        } catch (Exception $e) {
            $success = false;
        }
    }
    
    if ($sync !== null && !$synced) {
        try {
            $sync($root);
        } catch (Exception $e) {
            $success = false;
        }
    }
    
    return $success;
}
?>
