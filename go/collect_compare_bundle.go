// abstraction-provenance: {"artifact_sha256": "a28b0a43fba8977d376e124da8ccdac0f06a50ccbbc6a816fef657f6c5baf2ac", "source_sha256": "5aa602a80e57cbc63f54485d4cd66e205c54bd9f32bc03434218ff9bd388b3ab", "target_language": "go"}
// collect_compare_bundle.sh — portiert nach go
// Quelle: shell, OpenClaw@gateway1:scripts/collect_compare_bundle.sh
// auch in: OpenClaw@gateway2:scripts/collect_compare_bundle.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"archive/tar"
	"compress/gzip"
	"fmt"
	"io"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

const (
	root          = "/home/openclaw/.openclaw"
	outDir        = root + "/workspace/vscode/compare"
	transferDir   = outDir + "/transfer"
	mdFile        = outDir + "/local-gateway-config.md"
	treeFile      = outDir + "/tree.txt"
	backupFile    = "/home/openclaw/openclaw-backup.tar.gz"
	openclawJSON  = root + "/openclaw.json"
	execApprovals = root + "/exec-approvals.json"
	gatewayEnv    = root + "/gateway.systemd.env"
	dotEnv        = root + "/.env"
	configDir     = root + "/.config"
	agentsDir     = root + "/agents"
)

func main() {
	nowLocal := time.Now().Format("2006-01-02 15:04:05 MST")
	nowUTC := time.Now().UTC().Format("2006-01-02T15:04:05Z")
	host, _ := os.Hostname()

	os.MkdirAll(outDir, 0755)
	os.MkdirAll(transferDir, 0755)

	if _, err := exec.LookPath("tree"); err != nil {
		fmt.Fprintln(os.Stderr, "Fehler: 'tree' ist nicht installiert.")
		os.Exit(1)
	}

	md, err := os.Create(mdFile)
	if err != nil {
		panic(err)
	}
	defer md.Close()

	writeMDHeader(md, nowLocal, nowUTC, host)

	appendFileVerbatim(md, "openclaw.json", openclawJSON, "json")
	appendFileVerbatim(md, "exec-approvals.json", execApprovals, "json")
	appendFileVerbatim(md, "gateway.systemd.env", gatewayEnv, "dotenv")
	appendFileVerbatim(md, ".env", dotEnv, "dotenv")
	appendEnvVerbatim(md)
	appendDirFilesVerbatim(md, ".config (alle Dateien rekursiv)", configDir)
	appendDirFilesVerbatim(md, "agents (alle Dateien rekursiv)", agentsDir)

	createTreeFile(treeFile, root)
	createBackup()
	copyBackup()

	fmt.Println("OK")
	fmt.Printf("Erzeugt:\n- %s\n- %s\n- %s\n- %s (leer)\n", mdFile, treeFile, backupFile, transferDir)
}

func writeMDHeader(w io.Writer, nowLocal, nowUTC, host string) {
	fmt.Fprintf(w, `# Lokaler Gateway-Konfigurationsstand

Generiert: %s
UTC: %s
Host: %s

Diese Datei enthaelt den lokalen Stand mit unveraenderten Inhalten.
`, nowLocal, nowUTC, host)
}

func appendFileVerbatim(w io.Writer, label, path, lang string) {
	fmt.Fprintln(w)
	fmt.Fprintf(w, "## %s\n\n", label)
	fmt.Fprintf(w, "Pfad: `%s`\n\n", path)
	fmt.Fprintf(w, "```%s\n", lang)
	
	if content, err := os.ReadFile(path); err == nil {
		w.Write(content)
	} else {
		fmt.Fprintf(w, "[FEHLT] %s", path)
	}
	
	fmt.Fprintln(w)
	fmt.Fprintln(w, "```")
}

func appendEnvVerbatim(w io.Writer) {
	fmt.Fprintln(w)
	fmt.Fprintln(w, "## Umgebungsvariablen (env)")
	fmt.Fprintln(w)
	fmt.Fprintln(w, "```text")
	
	env := os.Environ()
	sort.Strings(env)
	for _, e := range env {
		fmt.Fprintln(w, e)
	}
	
	fmt.Fprintln(w, "```")
}

func appendDirFilesVerbatim(w io.Writer, section, dir string) {
	fmt.Fprintln(w)
	fmt.Fprintf(w, "## %s\n\n", section)
	
	if _, err := os.Stat(dir); os.IsNotExist(err) {
		fmt.Fprintf(w, "[FEHLT] %s\n", dir)
		return
	}
	
	fmt.Fprintf(w, "Basisverzeichnis: `%s`\n", dir)
	
	var files []string
	filepath.WalkDir(dir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return nil
		}
		if !d.IsDir() {
			files = append(files, path)
		}
		return nil
	})
	
	sort.Strings(files)
	
	for _, f := range files {
		fmt.Fprintln(w)
		fmt.Fprintf(w, "### Datei: `%s`\n\n", f)
		fmt.Fprintln(w, "```text")
		
		if content, err := os.ReadFile(f); err == nil {
			w.Write(content)
		}
		
		fmt.Fprintln(w)
		fmt.Fprintln(w, "```")
	}
}

func createTreeFile(file, root string) {
	cmd := exec.Command("tree", "-a", "-L", "6", root)
	out, _ := cmd.Output()
	os.WriteFile(file, out, 0644)
}

func createBackup() {
	// Create tar.gz backup
	file, _ := os.Create(backupFile)
	defer file.Close()
	
	gw := gzip.NewWriter(file)
	defer gw.Close()
	
	tw := tar.NewWriter(gw)
	defer tw.Close()
	
	// Add files to archive
	files := []string{openclawJSON, execApprovals, gatewayEnv, dotEnv}
	dirs := []string{configDir, agentsDir}
	
	for _, f := range files {
		if info, err := os.Stat(f); err == nil && !info.IsDir() {
			addFileToTar(tw, f, f)
		}
	}
	
	for _, dir := range dirs {
		if _, err := os.Stat(dir); err == nil {
			filepath.WalkDir(dir, func(path string, d fs.DirEntry, err error) error {
				if err != nil {
					return nil
				}
				if !d.IsDir() {
					addFileToTar(tw, path, strings.TrimPrefix(path, root+"/"))
				}
				return nil
			})
		}
	}
	
	// Verify backup by trying to read it
	verifyBackup()
}

func addFileToTar(tw *tar.Writer, path, name string) {
	file, _ := os.Open(path)
	defer file.Close()
	
	info, _ := file.Stat()
	header, _ := tar.FileInfoHeader(info, "")
	header.Name = name
	
	tw.WriteHeader(header)
	io.Copy(tw, file)
}

func verifyBackup() {
	file, _ := os.Open(backupFile)
	defer file.Close()
	
	gr, _ := gzip.NewReader(file)
	defer gr.Close()
	
	tr := tar.NewReader(gr)
	for {
		_, err := tr.Next()
		if err == io.EOF {
			break
		}
		if err != nil {
			panic("Backup verification failed")
		}
	}
}

func copyBackup() {
	input, _ := os.ReadFile(backupFile)
	os.WriteFile(outDir+"/openclaw-backup.tar.gz", input, 0644)
}
