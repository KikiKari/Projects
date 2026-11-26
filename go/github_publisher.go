// abstraction-provenance: {"artifact_sha256": "6c538706d203ccb2128fa423bd1d20d1f718de0e8b7ca95ecb12203c8b9c9a87", "source_sha256": "dfe62418dcbef9ea8aa7f18ada4f57d0ef73593432b7c7cefd85ee87eee622b4", "target_language": "go"}
// github_publisher.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/github_publisher.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"bytes"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"
)

var LANGUAGES = map[string]bool{
	"perl5":      true,
	"powershell": true,
	"perl6":      true,
	"tcl":        true,
	"javascript": true,
	"ruby":       true,
	"python":     true,
	"lua":        true,
	"shell":      true,
	"go":         true,
	"java":       true,
	"c":          true,
	"cpp":        true,
	"php":        true,
	"fsharp":     true,
	"css":        true,
}

func resolvePath(path string) (string, error) {
	abs, err := filepath.Abs(path)
	if err != nil {
		return "", err
	}
	resolved, err := filepath.EvalSymlinks(abs)
	if err != nil {
		return "", err
	}
	return resolved, nil
}

func synchronizeCheckout(root string, remote string, branch string) (string, map[string]int, error) {
	if remote == "" {
		remote = "https://github.com/KikiKari/OpenClaw.git"
	}
	if branch == "" {
		branch = "gateway1-abstractions"
	}

	root, err := resolvePath(root)
	if err != nil {
		return "", nil, err
	}

	tmpDir, err := ioutil.TempDir("", "abstractions-snapshot-*")
	if err != nil {
		return "", nil, err
	}
	defer os.RemoveAll(tmpDir)

	snapshot := filepath.Join(tmpDir, "repo")

	ctx, cancel := time.WithTimeout(context.Background(), 300*time.Second)
	defer cancel()

	cmd := exec.CommandContext(ctx, "git", "clone", "--quiet", "--depth=1", "--single-branch",
		"--branch", branch, "--", remote, snapshot)
	cmd.Stdout = nil
	cmd.Stderr = nil
	err = cmd.Run()
	if err != nil {
		return "", nil, err
	}

	ctx, cancel2 := time.WithTimeout(context.Background(), 30*time.Second)
	defer cancel2()

	revisionBytes, err := exec.CommandContext(ctx, "git", "-C", snapshot, "rev-parse", "HEAD").Output()
	if err != nil {
		return "", nil, err
	}
	revision := strings.TrimSpace(string(revisionBytes))

	counts := make(map[string]int)

	for _, language := range sortedKeys(LANGUAGES) {
		source := filepath.Join(snapshot, language)
		target := filepath.Join(root, language)

		if info, err := os.Lstat(source); err == nil && info.Mode()&os.ModeSymlink != 0 {
			return "", nil, fmt.Errorf("language directory is a symlink")
		}
		if info, err := os.Lstat(target); err == nil && info.Mode()&os.ModeSymlink != 0 {
			return "", nil, fmt.Errorf("language directory is a symlink")
		}

		if _, err := os.Stat(source); err == nil {
			if !isDir(source) {
				return "", nil, fmt.Errorf("invalid remote language directory")
			}
		}

		err = os.MkdirAll(target, 0755)
		if err != nil {
			return "", nil, err
		}

		known := make(map[string]bool)
		targetFiles, _ := ioutil.ReadDir(target)
		for _, p := range targetFiles {
			if p.IsDir() || p.Mode()&os.ModeSymlink != 0 {
				continue
			}
			data, err := ioutil.ReadFile(filepath.Join(target, p.Name()))
			if err != nil {
				continue
			}
			hash := fmt.Sprintf("%x", sha256.Sum256(data))
			known[hash] = true
		}

		var files []string
		if _, err := os.Stat(source); err == nil {
			sourceFiles, _ := ioutil.ReadDir(source)
			for _, p := range sourceFiles {
				if p.Mode()&os.ModeSymlink != 0 || !p.Mode().IsRegular() {
					return "", nil, fmt.Errorf("invalid remote abstraction")
				}
				files = append(files, filepath.Join(source, p.Name()))
			}
		}

		sort.Strings(files)
		counts[language] = len(files)

		for _, item := range files {
			data, err := ioutil.ReadFile(item)
			if err != nil {
				return "", nil, err
			}
			digest := fmt.Sprintf("%x", sha256.Sum256(data))
			if known[digest] {
				continue
			}

			itemName := filepath.Base(item)
			destination := filepath.Join(target, itemName)
			ext := filepath.Ext(itemName)
			stem := strings.TrimSuffix(itemName, ext)

			if _, err := os.Stat(destination); err == nil || os.IsExist(err) {
				destination = filepath.Join(target, stem+"__pool_"+digest+ext)
			}

			outFile, err := os.OpenFile(destination, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0644)
			if err != nil {
				if os.IsExist(err) {
					existingData, readErr := ioutil.ReadFile(destination)
					if readErr != nil || bytes.Compare(existingData, data) != 0 {
						return "", nil, fmt.Errorf("local abstraction conflict")
					}
				} else {
					return "", nil, err
				}
			} else {
				_, writeErr := outFile.Write(data)
				outFile.Close()
				if writeErr != nil {
					return "", nil, writeErr
				}
			}
			known[digest] = true
		}
	}

	return revision, counts, nil
}

func updateStatusCounts(path string, revision string, counts map[string]int) error {
	text, err := ioutil.ReadFile(path)
	if err != nil {
		return err
	}

	rows := []string{"## Bestand", "", fmt.Sprintf("GitHub-Stand: `%s`", revision), "",
		"| Zielsprache | Dateien |", "|---|---:|"}

	for _, language := range sortedKeys(LANGUAGES) {
		rows = append(rows, fmt.Sprintf("| %s | %d |", language, counts[language]))
	}

	total := 0
	for _, count := range counts {
		total += count
	}
	rows = append(rows, fmt.Sprintf("| **gesamt** | **%d** |", total), "", "")

	re := regexp.MustCompile(`(?ms)^## Bestand\n.*?(?=^## Quellen\n)`)
	updated := re.ReplaceAllString(string(text), strings.Join(rows, "\n"))

	if strings.Count(updated, "## Bestand") != 1 {
		return fmt.Errorf("status inventory section missing")
	}

	return ioutil.WriteFile(path, []byte(updated), 0644)
}

func queueArtifact(state map[string]interface{}, root string, path string) error {
	root, err := resolvePath(root)
	if err != nil {
		return err
	}

	pathInfo, err := os.Lstat(path)
	if err != nil {
		return err
	}
	if pathInfo.Mode()&os.ModeSymlink != 0 {
		return fmt.Errorf("artifact must not be a symlink")
	}

	absPath, err := resolvePath(path)
	if err != nil {
		return err
	}

	relPath, err := filepath.Rel(root, absPath)
	if err != nil {
		return err
	}

	relPath = filepath.ToSlash(relPath)

	if relPath != "STATUS.md" {
		parts := strings.Split(relPath, "/")
		if len(parts) == 0 || !LANGUAGES[parts[0]] {
			return fmt.Errorf("artifact is outside a language directory")
		}
	}

	data, err := ioutil.ReadFile(path)
	if err != nil {
		return err
	}

	hash := fmt.Sprintf("%x", sha256.Sum256(data))

	if state["ausstehende_veroeffentlichungen"] == nil {
		state["ausstehende_veroeffentlichungen"] = make(map[string]string)
	}
	state["ausstehende_veroeffentlichungen"].(map[string]string)[relPath] = hash

	return nil
}

func publishPending(root string, state map[string]interface{}, save func(map[string]interface{}), token string, opener func(*http.Request) (*http.Response, error)) bool {
	if opener == nil {
		opener = http.DefaultClient.Do
	}

	pendingRaw, exists := state["ausstehende_veroeffentlichungen"]
	pending := make(map[string]string)
	
	if exists {
		if pendingMap, ok := pendingRaw.(map[string]interface{}); ok {
			for k, v := range pendingMap {
				if vStr, ok := v.(string); ok {
					pending[k] = vStr
				}
			}
		} else {
			fmt.Println("invalid publication queue")
			return false
		}
	}

	if len(pending) == 0 {
		return true
	}

	if token == "" || strings.TrimSpace(token) == "" {
		return false
	}

	root, err := resolvePath(root)
	if err != nil {
		return false
	}

	headers := map[string]string{
		"Authorization":           "Bearer " + strings.TrimSpace(token),
		"Accept":                  "application/vnd.github+json",
		"X-GitHub-Api-Version":    "2022-11-28",
		"User-Agent":              "abstractions-manager",
	}

	success := true
	
	entries := make([][2]string, 0, len(pending))
	for k, v := range pending {
		entries = append(entries, [2]string{k, v})
	}
	
	sort.Slice(entries, func(i, j int) bool {
		if entries[i][0] == "STATUS.md" && entries[j][0] != "STATUS.md" {
			return true
		}
		if entries[j][0] == "STATUS.md" && entries[i][0] != "STATUS.md" {
			return false
		}
		return entries[i][0] < entries[j][0]
	})

	synced := false

	for _, entry := range entries {
		name := entry[0]
		expected := entry[1]

		func() {
			defer func() {
				if r := recover(); r != nil {
					success = false
				}
			}()

			path := filepath.Join(root, filepath.FromSlash(name))
			
			if info, err := os.Lstat(path); err == nil && info.Mode()&os.ModeSymlink != 0 {
				panic("invalid queued path")
			}
			
			absPath, err := resolvePath(path)
			if err != nil {
				panic(err)
			}
			
			relPath, err := filepath.Rel(root, absPath)
			if err != nil || filepath.ToSlash(relPath) != name {
				panic("invalid queued path")
			}

			data, err := ioutil.ReadFile(path)
			if err != nil {
				panic(err)
			}

			actualHash := fmt.Sprintf("%x", sha256.Sum256(data))
			if actualHash != expected {
				panic("queued artifact changed")
			}

			if name == "STATUS.md" {
				if !success {
					panic("artifact publication incomplete")
				}
				
				revision, counts, err := synchronizeCheckout(root, "", "")
				if err != nil {
					panic(err)
				}
				synced = true
				
				err = updateStatusCounts(path, revision, counts)
				if err != nil {
					panic(err)
				}
				
				data, err = ioutil.ReadFile(path)
				if err != nil {
					panic(err)
				}
				
				newExpected := fmt.Sprintf("%x", sha256.Sum256(data))
				pending[name] = newExpected
				save(state)
			}

			lookup := func(remoteName string) (string, map[string]interface{}) {
				endpoint := "https://api.github.com/repos/KikiKari/OpenClaw/contents/" + strings.ReplaceAll(remoteName, " ", "%20")
				req, _ := http.NewRequest("GET", endpoint+"?ref=gateway1-abstractions", nil)
				for k, v := range headers {
					req.Header.Set(k, v)
				}
				
				resp, err := opener(req)
				if err != nil {
					if resp != nil && resp.StatusCode == 404 {
						resp.Body.Close()
						return endpoint, nil
					}
					if resp != nil {
						resp.Body.Close()
					}
					panic(err)
				}
				defer resp.Body.Close()
				
				var result map[string]interface{}
				json.NewDecoder(resp.Body).Decode(&result)
				return endpoint, result
			}

			same := func(existing map[string]interface{}) bool {
				if existing == nil {
					return false
				}
				if encoding, ok := existing["encoding"].(string); !ok || encoding != "base64" {
					return false
				}
				if content, ok := existing["content"].(string); ok {
					decoded, err := base64.StdEncoding.DecodeString(content)
					if err != nil {
						return false
					}
					return bytes.Equal(decoded, data)
				}
				return false
			}

			remoteName := strings.ReplaceAll(name, "\\", "/")
			endpoint, existing := lookup(remoteName)

			if name == "STATUS.md" && existing != nil && !same(existing) {
				if shaVal, ok := existing["sha"].(string); ok && shaVal != "" {
					content := map[string]interface{}{
						"message": "Update abstraction status",
						"branch":  "gateway1-abstractions",
						"content": base64.StdEncoding.EncodeToString(data),
						"sha":     shaVal,
					}
					body, _ := json.Marshal(content)
					
					req, _ := http.NewRequest("PUT", endpoint, bytes.NewReader(body))
					for k, v := range headers {
						req.Header.Set(k, v)
					}
					req.Header.Set("Content-Type", "application/json")
					
					resp, err := opener(req)
					if err != nil {
						panic(err)
					}
					resp.Body.Close()
				} else {
					panic("missing remote status version")
				}
			} else if existing != nil && !same(existing) {
				candidate := filepath.Clean(name)
				dir := filepath.Dir(candidate)
				base := filepath.Base(candidate)
				ext := filepath.Ext(base)
				stem := strings.TrimSuffix(base, ext)
				alternate := filepath.Join(dir, stem+"_"+expected[:12]+ext)
				alternate = strings.ReplaceAll(filepath.ToSlash(alternate), "\\", "/")
				
				endpoint, existing = lookup(alternate)
				if existing != nil && !same(existing) {
					panic("remote artifact conflict")
				}
			}

			if existing == nil {
				content := map[string]interface{}{
					"message": "Publish script abstraction",
					"branch":  "gateway1-abstractions",
					"content": base64.StdEncoding.EncodeToString(data),
				}
				body, _ := json.Marshal(content)
				
				req, _ := http.NewRequest("PUT", endpoint, bytes.NewReader(body))
				for k, v := range headers {
					req.Header.Set(k, v)
				}
				req.Header.Set("Content-Type", "application/json")
				
				resp, err := opener(req)
				if err != nil {
					panic(err)
				}
				resp.Body.Close()
			}

			delete(pending, name)
			save(state)
		}()
	}

	if !synced {
		func() {
			defer func() {
				if r := recover(); r != nil {
					success = false
				}
			}()
			synchronizeCheckout(root, "", "")
		}()
	}

	return success
}

func isDir(path string) bool {
	info, err := os.Stat(path)
	if err != nil {
		return false
	}
	return info.IsDir()
}

func sortedKeys(m map[string]bool) []string {
	keys := make([]string, 0, len(m))
	for k := range m {
		keys = append(keys, k)
	}
	sort.Strings(keys)
	return keys
}
