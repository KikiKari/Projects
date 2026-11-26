// abstraction-provenance: {"artifact_sha256": "5c81d0157ee7f1ae283563b5e4b9074742f45ff108c77f65ba22205109023eea", "source_sha256": "a137d03b3b37332439a1592831d60479ff86315c7e6d6ed7da0fb799db0f13f7", "target_language": "go"}
// find-sessions.sh — portiert nach go
// Quelle: shell, OpenClaw@gateway1:skills/tmux/scripts/find-sessions.sh
// auch in: OpenClaw@gateway2:skills/tmux/scripts/find-sessions.sh
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

var (
	socketName     string
	socketPath     string
	query          string
	scanAll        bool
	socketDir      string
	help           bool
)

func init() {
	flag.StringVar(&socketName, "L", "", "tmux socket name (passed to tmux -L)")
	flag.StringVar(&socketPath, "S", "", "tmux socket path (passed to tmux -S)")
	flag.BoolVar(&scanAll, "A", false, "scan all sockets under CLAWDBOT_TMUX_SOCKET_DIR")
	flag.StringVar(&query, "q", "", "case-insensitive substring to filter session names")
	flag.BoolVar(&scanAll, "--all", false, "scan all sockets under CLAWDBOT_TMUX_SOCKET_DIR")
	flag.StringVar(&socketName, "--socket", "", "tmux socket name (passed to tmux -L)")
	flag.StringVar(&socketPath, "--socket-path", "", "tmux socket path (passed to tmux -S)")
	flag.StringVar(&query, "--query", "", "case-insensitive substring to filter session names")
	flag.BoolVar(&help, "h", false, "show this help")
	flag.BoolVar(&help, "--help", false, "show this help")
	
	// Set default socket directory
	tmpDir := "/tmp"
	if t := os.Getenv("TMPDIR"); t != "" {
		tmpDir = t
	}
	defaultSocketDir := filepath.Join(tmpDir, "clawdbot-tmux-sockets")
	if s := os.Getenv("CLAWDBOT_TMUX_SOCKET_DIR"); s != "" {
		socketDir = s
	} else {
		socketDir = defaultSocketDir
	}
}

func usage() {
	fmt.Print(`Usage: find-sessions.sh [-L socket-name|-S socket-path|-A] [-q pattern]

List tmux sessions on a socket (default tmux socket if none provided).

Options:
  -L, --socket       tmux socket name (passed to tmux -L)
  -S, --socket-path  tmux socket path (passed to tmux -S)
  -A, --all          scan all sockets under CLAWDBOT_TMUX_SOCKET_DIR
  -q, --query        case-insensitive substring to filter session names
  -h, --help         show this help
`)
}

func checkTmuxExists() bool {
	_, err := exec.LookPath("tmux")
	return err == nil
}

func listSessions(label string, tmuxArgs ...string) int {
	tmuxCmd := append([]string{"tmux"}, tmuxArgs...)
	tmuxCmd = append(tmuxCmd, "list-sessions", "-F", "#{session_name}\t#{session_attached}\t#{session_created_string}")
	
	cmd := exec.Command(tmuxCmd[0], tmuxCmd[1:]...)
	output, err := cmd.CombinedOutput()
	
	if err != nil {
		fmt.Fprintf(os.Stderr, "No tmux server found on %s\n", label)
		return 1
	}
	
	sessions := string(output)
	if query != "" {
		lines := strings.Split(strings.TrimSpace(sessions), "\n")
		filteredLines := []string{}
		for _, line := range lines {
			if strings.Contains(strings.ToLower(line), strings.ToLower(query)) {
				filteredLines = append(filteredLines, line)
			}
		}
		sessions = strings.Join(filteredLines, "\n")
	}
	
	if sessions == "" || sessions == "\n" {
		fmt.Printf("No sessions found on %s\n", label)
		return 0
	}
	
	fmt.Printf("Sessions on %s:\n", label)
	scanner := bufio.NewScanner(strings.NewReader(sessions))
	for scanner.Scan() {
		line := scanner.Text()
		if line == "" {
			continue
		}
		parts := strings.Split(line, "\t")
		if len(parts) < 3 {
			continue
		}
		name := parts[0]
		attached := parts[1]
		created := parts[2]
		
		attachedLabel := "detached"
		if attached == "1" {
			attachedLabel = "attached"
		}
		fmt.Printf("  - %s (%s, started %s)\n", name, attachedLabel, created)
	}
	
	return 0
}

func main() {
	flag.Parse()
	
	if help {
		usage()
		os.Exit(0)
	}
	
	if scanAll && (socketName != "" || socketPath != "") {
		fmt.Fprintln(os.Stderr, "Cannot combine --all with -L or -S")
		os.Exit(1)
	}
	
	if socketName != "" && socketPath != "" {
		fmt.Fprintln(os.Stderr, "Use either -L or -S, not both")
		os.Exit(1)
	}
	
	if !checkTmuxExists() {
		fmt.Fprintln(os.Stderr, "tmux not found in PATH")
		os.Exit(1)
	}
	
	if scanAll {
		if _, err := os.Stat(socketDir); os.IsNotExist(err) {
			fmt.Fprintf(os.Stderr, "Socket directory not found: %s\n", socketDir)
			os.Exit(1)
		}
		
		entries, err := os.ReadDir(socketDir)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error reading socket directory: %s\n", err)
			os.Exit(1)
		}
		
		if len(entries) == 0 {
			fmt.Fprintf(os.Stderr, "No sockets found under %s\n", socketDir)
			os.Exit(1)
		}
		
		exitCode := 0
		for _, entry := range entries {
			sock := filepath.Join(socketDir, entry.Name())
			if info, err := os.Stat(sock); err == nil && info.Mode()&os.ModeSocket != 0 {
				if code := listSessions(fmt.Sprintf("socket path '%s'", sock), "-S", sock); code != 0 {
					exitCode = code
				}
			}
		}
		os.Exit(exitCode)
	}
	
	socketLabel := "default socket"
	tmuxArgs := []string{}
	
	if socketName != "" {
		tmuxArgs = append(tmuxArgs, "-L", socketName)
		socketLabel = fmt.Sprintf("socket name '%s'", socketName)
	} else if socketPath != "" {
		tmuxArgs = append(tmuxArgs, "-S", socketPath)
		socketLabel = fmt.Sprintf("socket path '%s'", socketPath)
	}
	
	os.Exit(listSessions(socketLabel, tmuxArgs...))
}
