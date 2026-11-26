<?php
// abstraction-provenance: {"artifact_sha256": "4e29260c615b3a76b9552a3178698cfddcd91c58345bc07869ce8dd35c28628c", "source_sha256": "4c10c6b6fd911cb95da119f761f402073d1a836cab6b40a9f3b989536d5df5ec", "target_language": "php"}
// git_publish.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/git-publish-agent/scripts/git_publish.py
// auch in: OpenClaw@gateway2:skills/git-publish-agent/scripts/git_publish.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py
/**
 * Git Publish Agent - Automatisierte Skill-Veröffentlichung
 */

$SKILLS_DIR = getenv('HOME') . '/.openclaw/workspace/skills';

function run_command($command, $cwd = null) {
    $descriptorspec = [
        0 => ["pipe", "r"],
        1 => ["pipe", "w"],
        2 => ["pipe", "w"]
    ];
    
    $proc = proc_open($command, $descriptorspec, $pipes, $cwd);
    
    if (is_resource($proc)) {
        fclose($pipes[0]);
        $stdout = stream_get_contents($pipes[1]);
        fclose($pipes[1]);
        $stderr = stream_get_contents($pipes[2]);
        fclose($pipes[2]);
        
        $return_value = proc_close($proc);
        return ['return_code' => $return_value, 'stdout' => $stdout, 'stderr' => $stderr];
    }
    
    return ['return_code' => -1, 'stdout' => '', 'stderr' => 'Failed to execute command'];
}

function git_commit($skill_path, $message = null) {
    global $SKILLS_DIR;
    
    if (!$message) {
        $date = date('c');
        $name = basename($skill_path);
        $message = "[skill] Auto-update {$name} - {$date}";
    }
    
    $parent_dir = dirname($SKILLS_DIR);
    run_command(['git', 'add', $skill_path], $parent_dir);
    $result = run_command(['git', 'commit', '-m', $message], $parent_dir);
    
    return $result['return_code'] === 0;
}

function clawhub_publish($skill_name) {
    global $SKILLS_DIR;
    
    $skill_path = $SKILLS_DIR . '/' . $skill_name;
    $result = run_command([
        'clawhub', 'publish', $skill_path,
        '--slug', $skill_name,
        '--version', '1.0.0'
    ]);
    
    return [$result['return_code'] === 0, $result['stdout']];
}

function batch_publish() {
    global $SKILLS_DIR;
    
    $result = run_command(['git', 'status', '--short', $SKILLS_DIR]);
    
    $changed = [];
    $lines = explode("\n", $result['stdout']);
    foreach ($lines as $line) {
        $line = trim($line);
        if ($line && strpos($line, 'skills/') !== false) {
            $parts = explode('skills/', $line);
            $skill_parts = explode('/', $parts[1]);
            $skill = $skill_parts[0];
            if (!in_array($skill, $changed)) {
                $changed[] = $skill;
            }
        }
    }
    
    echo "Changed skills: " . json_encode($changed) . "\n";
    
    // Publish with delay
    $limit = min(5, count($changed));
    for ($i = 0; $i < $limit; $i++) {
        $skill = $changed[$i];
        if ($i > 0) {
            echo "Waiting 15min for rate limit...\n";
            // In real: sleep(900);
        }
        
        echo "Publishing {$skill}...\n";
        $commit_ok = git_commit($SKILLS_DIR . '/' . $skill);
        if ($commit_ok) {
            list($pub_ok, $output) = clawhub_publish($skill);
            $symbol = $pub_ok ? '✓' : '✗';
            echo "  {$symbol} {$output}\n";
        }
    }
}

function main() {
    global $argc, $argv, $SKILLS_DIR;
    
    $options = getopt('', ['skill:', 'all', 'no-publish', 'message:']);
    
    if (isset($options['skill'])) {
        $skill_path = $SKILLS_DIR . '/' . $options['skill'];
        if (isset($options['no-publish'])) {
            git_commit($skill_path, $options['message'] ?? null);
        } else {
            git_commit($skill_path, $options['message'] ?? null);
            clawhub_publish($options['skill']);
        }
    } elseif (isset($options['all'])) {
        batch_publish();
    } else {
        echo "Use --skill <name> or --all\n";
    }
}

main();
