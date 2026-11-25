// abstraction-provenance: {"artifact_sha256": "e998f46b45d7cd5128120b8e30503fb7445845b4e9b22f6b1fd267ab1551d003", "source_sha256": "5d90ebcd250a3cb80a0de664d94397af7ec03343d9d9fa64a28a9a11ad880754", "target_language": "go"}
// check_conflicts.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:skills/sync-utils/scripts/check_conflicts.py
// auch in: OpenClaw@gateway2:skills/sync-utils/scripts/check_conflicts.py
// Erzeugt: 2026-11-25 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"crypto/sha256"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const (
	CLAWHUB_DIR = "/home/openclaw/.openclaw/workspace/skills"
	GIT_DIR     = "/home/openclaw/.openclaw/workspace/git/skills"
)

type FileConflict struct {
	File             string
	ClawHubModified  string
	GitModified      string
	Newer            string
}

type SkillConflict struct {
	Skill     string
	Conflicts []FileConflict
}

// getFileHash berechnet den SHA256-Hash einer Datei
func getFileHash(filePath string) (string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return "", err
	}
	defer file.Close()

	hash := sha256.New()
	if _, err := io.Copy(hash, file); err != nil {
		return "", err
	}

	return fmt.Sprintf("%x", hash.Sum(nil)), nil
}

// checkConflicts prüft auf Konflikte zwischen ClawHub und Git
func checkConflicts() {
	conflicts := []SkillConflict{}

	// Hole alle Skills aus beiden Verzeichnissen
	clawhubSkills := make(map[string]bool)
	gitSkills := make(map[string]bool)

	// Prüfe ob beide Verzeichnisse existieren
	if _, err := os.Stat(CLAWHUB_DIR); os.IsNotExist(err) {
		fmt.Println("ClawHub-Verzeichnis nicht gefunden")
		return
	}
	if _, err := os.Stat(GIT_DIR); os.IsNotExist(err) {
		fmt.Println("Git-Verzeichnis nicht gefunden")
		return
	}

	// Sammle ClawHub Skills
	err := filepath.Walk(CLAWHUB_DIR, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() && path != CLAWHUB_DIR {
			relPath, _ := filepath.Rel(CLAWHUB_DIR, path)
			if !strings.Contains(relPath, ".git") {
				clawhubSkills[filepath.Base(path)] = true
			}
			return filepath.SkipDir
		}
		return nil
	})
	if err != nil {
		fmt.Printf("Fehler beim Durchsuchen von ClawHub: %v\n", err)
		return
	}

	// Sammle Git Skills
	err = filepath.Walk(GIT_DIR, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() && path != GIT_DIR {
			relPath, _ := filepath.Rel(GIT_DIR, path)
			if !strings.Contains(relPath, ".git") {
				gitSkills[filepath.Base(path)] = true
			}
			return filepath.SkipDir
		}
		return nil
	})
	if err != nil {
		fmt.Printf("Fehler beim Durchsuchen von Git: %v\n", err)
		return
	}

	// Finde gemeinsame Skills
	commonSkills := []string{}
	for skill := range clawhubSkills {
		if gitSkills[skill] {
			commonSkills = append(commonSkills, skill)
		}
	}

	fmt.Printf("Prüfe %d Skills auf Konflikte...\n\n", len(commonSkills))

	// Prüfe jeden gemeinsamen Skill
	for _, skill := range commonSkills {
		clawhubPath := filepath.Join(CLAWHUB_DIR, skill)
		gitPath := filepath.Join(GIT_DIR, skill)

		skillConflicts := []FileConflict{}

		// Sammle ClawHub Dateien
		clawhubFiles := make(map[string]string)
		err := filepath.Walk(clawhubPath, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}
			if info.IsFile() && !strings.Contains(path, ".git") {
				relPath, _ := filepath.Rel(clawhubPath, path)
				clawhubFiles[relPath] = path
			}
			return nil
		})
		if err != nil {
			fmt.Printf("Fehler beim Durchsuchen von ClawHub-Skill %s: %v\n", skill, err)
			continue
		}

		// Sammle Git Dateien
		gitFiles := make(map[string]string)
		err = filepath.Walk(gitPath, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return err
			}
			if info.IsFile() && !strings.Contains(path, ".git") {
				relPath, _ := filepath.Rel(gitPath, path)
				gitFiles[relPath] = path
			}
			return nil
		})
		if err != nil {
			fmt.Printf("Fehler beim Durchsuchen von Git-Skill %s: %v\n", skill, err)
			continue
		}

		// Vergleiche gemeinsame Dateien
		for relPath := range clawhubFiles {
			if gitFilePath, exists := gitFiles[relPath]; exists {
				clawhubFile := clawhubFiles[relPath]
				
				clawhubHash, err1 := getFileHash(clawhubFile)
				gitHash, err2 := getFileHash(gitFilePath)

				if err1 != nil || err2 != nil {
					fmt.Printf("Fehler beim Hash-Berechnung für %s: %v, %v\n", relPath, err1, err2)
					continue
				}

				if clawhubHash != gitHash {
					// Hole Modifikationszeiten
					clawhubStat, _ := os.Stat(clawhubFile)
					gitStat, _ := os.Stat(gitFilePath)

					clawhubMtime := clawhubStat.ModTime()
					gitMtime := gitStat.ModTime()

					newer := "git"
					if clawhubMtime.After(gitMtime) {
						newer = "clawhub"
					}

					skillConflicts = append(skillConflicts, FileConflict{
						File:            relPath,
						ClawHubModified: clawhubMtime.Format("2006-01-02 15:04:05"),
						GitModified:     gitMtime.Format("2006-01-02 15:04:05"),
						Newer:           newer,
					})
				}
			}
		}

		if len(skillConflicts) > 0 {
			conflicts = append(conflicts, SkillConflict{
				Skill:     skill,
				Conflicts: skillConflicts,
			})
		}
	}

	// Ausgabe
	if len(conflicts) > 0 {
		fmt.Println("⚠️  KONFLIKTE GEFUNDEN:")
		fmt.Println(strings.Repeat("=", 80))

		for _, conflict := range conflicts {
			fmt.Printf("\n📦 Skill: %s\n", conflict.Skill)
			fmt.Println(strings.Repeat("-", 40))

			for _, fileConflict := range conflict.Conflicts {
				fmt.Printf("  📄 %s\n", fileConflict.File)
				fmt.Printf("     ClawHub: %s\n", fileConflict.ClawHubModified)
				fmt.Printf("     Git:     %s\n", fileConflict.GitModified)
				fmt.Printf("     Neuer:   %s\n", strings.ToUpper(fileConflict.Newer))
				fmt.Println()
			}
		}

		fmt.Println(strings.Repeat("=", 80))
		fmt.Printf("Gesamt: %d Skills mit Konflikten\n", len(conflicts))
		fmt.Println("\nNutze 'sync_utils/scripts/resolve_conflict.py' zum Auflösen.")
	} else {
		fmt.Println("✅ Keine Konflikte gefunden!")
		fmt.Println("Alle gemeinsamen Skills sind synchron.")
	}
}

func main() {
	checkConflicts()
}
