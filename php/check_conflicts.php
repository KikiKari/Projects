<?php
// abstraction-provenance: {"artifact_sha256": "d9a7f7c90e5c044ca72c309ba877485d2be2cfa8dac78bcb6f2287540f06e6cb", "source_sha256": "5d90ebcd250a3cb80a0de664d94397af7ec03343d9d9fa64a28a9a11ad880754", "target_language": "php"}
// check_conflicts.py — portiert nach php
// Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
// auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py
/**
 * Check Conflicts - Erkennt Sync-Konflikte
 */

// Pfade definieren
define('CLAWHUB_DIR', '/home/openclaw/.openclaw/workspace/skills');
define('GIT_DIR', '/home/openclaw/.openclaw/workspace/git/skills');

/**
 * Berechnet den Hash einer Datei
 * @param string $filepath Pfad zur Datei
 * @return string MD5 Hash der Datei
 */
function get_file_hash($filepath) {
    return md5_file($filepath);
}

/**
 * Prüft auf Konflikte zwischen ClawHub und Git
 */
function check_conflicts() {
    $conflicts = [];
    
    // Alle Skills die in beiden Orten existieren
    $common_skills = [];
    if (is_dir(CLAWHUB_DIR) && is_dir(GIT_DIR)) {
        $clawhub_skills = array_filter(scandir(CLAWHUB_DIR), function($d) {
            return is_dir(CLAWHUB_DIR . '/' . $d) && !in_array($d, ['.', '..']);
        });
        $git_skills = array_filter(scandir(GIT_DIR), function($d) {
            return is_dir(GIT_DIR . '/' . $d) && !in_array($d, ['.', '..']);
        });
        $common_skills = array_intersect($clawhub_skills, $git_skills);
    }
    
    echo "Prüfe " . count($common_skills) . " Skills auf Konflikte...\n\n";
    
    foreach (sort_skills($common_skills) as $skill) {
        $clawhub_path = CLAWHUB_DIR . '/' . $skill;
        $git_path = GIT_DIR . '/' . $skill;
        
        // Alle Dateien vergleichen
        $skill_conflicts = [];
        
        // ClawHub Dateien
        $clawhub_files = get_files_recursive($clawhub_path);
        
        // Git Dateien
        $git_files = get_files_recursive($git_path);
        
        // Vergleiche gemeinsame Dateien
        $common_files = array_intersect_key($clawhub_files, $git_files);
        foreach ($common_files as $rel_path => $clawhub_file) {
            $git_file = $git_files[$rel_path];
            
            if (get_file_hash($clawhub_file) !== get_file_hash($git_file)) {
                $clawhub_mtime = date('Y-m-d H:i:s', filemtime($clawhub_file));
                $git_mtime = date('Y-m-d H:i:s', filemtime($git_file));
                
                $skill_conflicts[] = [
                    "file" => $rel_path,
                    "clawhub_modified" => $clawhub_mtime,
                    "git_modified" => $git_mtime,
                    "newer" => strtotime($clawhub_mtime) > strtotime($git_mtime) ? "clawhub" : "git"
                ];
            }
        }
        
        if (!empty($skill_conflicts)) {
            $conflicts[] = [
                "skill" => $skill,
                "conflicts" => $skill_conflicts
            ];
        }
    }
    
    // Ausgabe
    if (!empty($conflicts)) {
        echo "⚠️  KONFLIKTE GEFUNDEN:\n";
        echo str_repeat("=", 80) . "\n";
        
        foreach ($conflicts as $conflict) {
            echo "\n📦 Skill: " . $conflict['skill'] . "\n";
            echo str_repeat("-", 40) . "\n";
            
            foreach ($conflict['conflicts'] as $file_conflict) {
                echo "  📄 " . $file_conflict['file'] . "\n";
                echo "     ClawHub: " . $file_conflict['clawhub_modified'] . "\n";
                echo "     Git:     " . $file_conflict['git_modified'] . "\n";
                echo "     Neuer:   " . strtoupper($file_conflict['newer']) . "\n";
                echo "\n";
            }
        }
        
        echo str_repeat("=", 80) . "\n";
        echo "Gesamt: " . count($conflicts) . " Skills mit Konflikten\n";
        echo "\nNutze 'sync_utils/scripts/resolve_conflict.py' zum Auflösen.\n";
    } else {
        echo "✅ Keine Konflikte gefunden!\n";
        echo "Alle gemeinsamen Skills sind synchron.\n";
    }
}

/**
 * Sortiert die Skills alphabetisch
 * @param array $skills Liste der Skills
 * @return array Sortierte Liste
 */
function sort_skills($skills) {
    sort($skills);
    return $skills;
}

/**
 * Rekursiv alle Dateien in einem Verzeichnis finden
 * @param string $dir Verzeichnispfad
 * @return array Assoziatives Array mit relativen Pfaden als Schlüssel und vollen Pfaden als Wert
 */
function get_files_recursive($dir) {
    $files = [];
    $iterator = new RecursiveIteratorIterator(
        new RecursiveDirectoryIterator($dir, RecursiveDirectoryIterator::SKIP_DOTS),
        RecursiveIteratorIterator::LEAVES_ONLY
    );
    
    foreach ($iterator as $file) {
        if (!$file->isFile() || strpos($file->getPathname(), '/.git/') !== false) {
            continue;
        }
        
        $relative_path = str_replace($dir . '/', '', $file->getPathname());
        $files[$relative_path] = $file->getPathname();
    }
    
    return $files;
}

/**
 * Hauptfunktion
 */
function main() {
    check_conflicts();
}

main();
?>
