// abstraction-provenance: {"artifact_sha256": "36e6c66db78daaa88421862bc33c7732530e18a65995af74842aff2c47933d73", "source_sha256": "77eca70a7a8f9c0ff8dc240b14d8c37999854c241e031b8167e1fcd650cbd334", "target_language": "go"}
// install_cron.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:skills/db-maintainer/scripts/install_cron.py
// auch in: OpenClaw@gateway2:skills/db-maintainer/scripts/install_cron.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/*
Installiert den DB-Maintainer als Cron-Job
*/

package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

const CRON_JOB = `# DB Maintainer - Alle 30 Minuten
*/30 * * * * cd /home/openclaw/.openclaw/workspace && python3 skills/db-maintainer/scripts/db_maintainer.py >> logs/db-maintainer/cron.log 2>&1`

func install() {
	workspace := "/home/openclaw/.openclaw/workspace"
	cronFile := filepath.Join(workspace, "crons", "db-maintainer.cron")

	// Erstelle das Verzeichnis falls es nicht existiert
	err := os.MkdirAll(filepath.Dir(cronFile), 0755)
	if err != nil {
		fmt.Printf("Fehler beim Erstellen des Verzeichnisses: %v\n", err)
		return
	}

	// Schreibe die Cron-Job-Datei
	err = os.WriteFile(cronFile, []byte(CRON_JOB), 0644)
	if err != nil {
		fmt.Printf("Fehler beim Schreiben der Cron-Datei: %v\n", err)
		return
	}

	fmt.Printf("✅ Cron-Job installiert: %s\n", cronFile)
	fmt.Println("   Füge zu crontab hinzu mit: crontab < crons/db-maintainer.cron")

	// Auch in OpenClaw cron registrieren
	jobsJSON := filepath.Join(workspace, ".openclaw", "cron", "jobs.json")
	if _, err := os.Stat(jobsJSON); err == nil {
		// Lese die bestehende jobs.json Datei
		data, err := os.ReadFile(jobsJSON)
		if err != nil {
			fmt.Printf("Fehler beim Lesen der jobs.json: %v\n", err)
			return
		}

		var jobs map[string]interface{}
		err = json.Unmarshal(data, &jobs)
		if err != nil {
			fmt.Printf("Fehler beim Parsen der jobs.json: %v\n", err)
			return
		}

		// Aktualisiere oder füge den db-maintainer Job hinzu
		jobs["db-maintainer"] = map[string]interface{}{
			"schedule": "*/30 * * * *",
			"command":  "python3 skills/db-maintainer/scripts/db_maintainer.py",
			"enabled":  true,
		}

		// Schreibe die aktualisierte jobs.json Datei
		updatedData, err := json.MarshalIndent(jobs, "", "  ")
		if err != nil {
			fmt.Printf("Fehler beim Serialisieren der jobs.json: %v\n", err)
			return
		}

		err = os.WriteFile(jobsJSON, updatedData, 0644)
		if err != nil {
			fmt.Printf("Fehler beim Schreiben der jobs.json: %v\n", err)
			return
		}

		fmt.Println("✅ In OpenClaw cron registriert")
	}
}

func main() {
	install()
}
