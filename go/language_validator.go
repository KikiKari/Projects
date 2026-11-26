// abstraction-provenance: {"artifact_sha256": "907a84859fd7304d10575336b9daa10331cce66747b6e9c19d5d19f7979e24f0", "source_sha256": "eb21431dabeaafc82a1e3ccf24278616e46ed082eca1de4d328c758ee82ee2c7", "target_language": "go"}
// language_validator.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:skills/scripting-utils/scripts/language_validator.py
// auch in: OpenClaw@gateway2:skills/scripting-utils/scripts/language_validator.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/*
Multi-language script validator supporting 8+ languages.
WebSearch integration for documentation lookup.
*/

package main

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

type ValidationResult struct {
	Language string
	Valid    bool
	Errors   []string
	Warnings []string
	DocURL   string
}

type LanguageConfig struct {
	Cmd    string
	Args   []string
	Linter string
}

type LanguageValidator struct {
	language     string
	useWebSearch bool
	config       LanguageConfig
}

var languages = map[string]LanguageConfig{
	"bash":       {"bash", []string{"-n"}, "shellcheck"},
	"sh":         {"sh", []string{"-n"}, "shellcheck"},
	"python":     {"python3", []string{"-m", "py_compile"}, "pylint"},
	"perl":       {"perl", []string{"-c"}, "perlcritic"},
	"raku":       {"raku", []string{"-c"}, ""},
	"powershell": {"pwsh", []string{"-Command", "Get-Command"}, ""},
	"javascript": {"node", []string{"--check"}, "eslint"},
	"tcl":        {"tclsh", []string{}, ""},
}

func NewLanguageValidator(language string, useWebSearch bool) (*LanguageValidator, error) {
	lowerLang := strings.ToLower(language)
	config, exists := languages[lowerLang]
	if !exists {
		return nil, fmt.Errorf("unsupported language: %s", language)
	}
	
	return &LanguageValidator{
		language:     lowerLang,
		useWebSearch: useWebSearch,
		config:       config,
	}, nil
}

func (lv *LanguageValidator) Validate(scriptPath string) ValidationResult {
	errors := []string{}
	warnings := []string{}
	
	// Syntax check
	cmd := exec.Command(lv.config.Cmd)
	cmd.Args = append(cmd.Args, lv.config.Args...)
	cmd.Args = append(cmd.Args, scriptPath)
	
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	
	cmd = exec.CommandContext(ctx, lv.config.Cmd)
	cmd.Args = append([]string{lv.config.Cmd}, lv.config.Args...)
	cmd.Args = append(cmd.Args, scriptPath)
	
	output, err := cmd.CombinedOutput()
	
	if ctx.Err() == context.DeadlineExceeded {
		errors = append(errors, "Validation timeout")
	} else if err != nil {
		if _, ok := err.(*exec.Error); ok {
			errors = append(errors, fmt.Sprintf("Command not found: %s", lv.config.Cmd))
			if lv.useWebSearch {
				docURL := lv.fetchDocs()
				return ValidationResult{lv.language, false, errors, warnings, docURL}
			}
		} else {
			errors = append(errors, string(output))
		}
	}
	
	// Linter check if available
	if lv.config.Linter != "" {
		linterWarnings := lv.runLinter(scriptPath)
		warnings = append(warnings, linterWarnings...)
	}
	
	valid := len(errors) == 0
	return ValidationResult{lv.language, valid, errors, warnings, ""}
}

func (lv *LanguageValidator) runLinter(scriptPath string) []string {
	warnings := []string{}
	
	switch lv.config.Linter {
	case "shellcheck":
		cmd := exec.Command("shellcheck", "-f", "gcc", scriptPath)
		output, err := cmd.Output()
		if err != nil && len(output) > 0 {
			scanner := bufio.NewScanner(strings.NewReader(string(output)))
			for scanner.Scan() {
				warnings = append(warnings, scanner.Text())
			}
		}
	case "pylint":
		cmd := exec.Command("pylint", "--output-format=parseable", scriptPath)
		output, err := cmd.Output()
		if err != nil && len(output) > 0 {
			scanner := bufio.NewScanner(strings.NewReader(string(output)))
			for scanner.Scan() {
				warnings = append(warnings, scanner.Text())
			}
		}
	default:
		if _, err := exec.LookPath(lv.config.Linter); err != nil {
			warnings = append(warnings, fmt.Sprintf("Linter not installed: %s", lv.config.Linter))
		}
	}
	
	return warnings
}

func (lv *LanguageValidator) fetchDocs() string {
	if !lv.useWebSearch {
		return ""
	}
	
	docs := map[string]string{
		"powershell": "https://docs.microsoft.com/powershell/",
		"raku":       "https://docs.raku.org/",
		"tcl":        "https://www.tcl.tk/",
	}
	
	if url, exists := docs[lv.language]; exists {
		return url
	}
	
	return ""
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: language_validator.go <script> --lang <language>")
		os.Exit(1)
	}
	
	scriptPath := ""
	language := ""
	useWebSearch := true
	
	args := os.Args[1:]
	for i := 0; i < len(args); i++ {
		arg := args[i]
		if arg == "--lang" && i+1 < len(args) {
			language = args[i+1]
			i++
		} else if arg == "--no-websearch" {
			useWebSearch = false
		} else if scriptPath == "" && !strings.HasPrefix(arg, "--") {
			scriptPath = arg
		}
	}
	
	if scriptPath == "" || language == "" {
		fmt.Println("Error: Both script path and language are required")
		os.Exit(1)
	}
	
	if _, err := os.Stat(scriptPath); os.IsNotExist(err) {
		fmt.Printf("Error: Script file does not exist: %s\n", scriptPath)
		os.Exit(1)
	}
	
	validator, err := NewLanguageValidator(language, useWebSearch)
	if err != nil {
		fmt.Printf("Error: %v\n", err)
		os.Exit(1)
	}
	
	result := validator.Validate(scriptPath)
	
	fmt.Printf("Language: %s\n", result.Language)
	fmt.Printf("Valid: %t\n", result.Valid)
	
	if len(result.Errors) > 0 {
		count := len(result.Errors)
		if count > 5 {
			count = 5
		}
		fmt.Printf("Errors: %d\n", len(result.Errors))
		for i := 0; i < count; i++ {
			fmt.Printf("  - %s\n", strings.TrimSpace(result.Errors[i]))
		}
	}
	
	if len(result.Warnings) > 0 {
		count := len(result.Warnings)
		if count > 5 {
			count = 5
		}
		fmt.Printf("Warnings: %d\n", len(result.Warnings))
		for i := 0; i < count; i++ {
			fmt.Printf("  - %s\n", strings.TrimSpace(result.Warnings[i]))
		}
	}
	
	if result.DocURL != "" {
		fmt.Printf("Docs: %s\n", result.DocURL)
	}
	
	if result.Valid {
		os.Exit(0)
	} else {
		os.Exit(1)
	}
}
