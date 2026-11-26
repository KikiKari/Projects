// abstraction-provenance: {"artifact_sha256": "2947ca1d8552e00248c6af5249ce8593cf099a0c51924faf8fd2bc58f6b35bc6", "source_sha256": "9411ee01f75190a7b3bf9f276fc6bb624d2c943629885c1ddfc9f71a0039070e", "target_language": "go"}
// gemini-ask.js — portiert nach go
// Quelle: javascript, OpenClaw@gateway1:scripts/gemini-ask.js
// auch in: OpenClaw@gateway2:scripts/gemini-ask.js
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"log"
	"os"
	"strings"

	"github.com/google/generative-ai-go/genai"
	"google.golang.org/api/option"
)

const defaultModel = "gemini-pro"

func main() {
	// Check API key
	apiKey := os.Getenv("GEMINI_API_KEY")
	if apiKey == "" {
		log.Fatal("Error: GEMINI_API_KEY environment variable is required")
	}

	// Get model name
	modelName := defaultModel
	if envModel := os.Getenv("GEMINI_MODEL"); envModel != "" {
		modelName = envModel
	}

	// Parse arguments
	var prompt string
	var systemPrompt string
	args := os.Args[1:]

	// Check for --model flag
	for i := 0; i < len(args); i++ {
		if (args[i] == "--model" || args[i] == "-m") && i+1 < len(args) {
			modelName = args[i+1]
			// Remove --model and value from args
			copy(args[i:], args[i+2:])
			args = args[:len(args)-2]
			i-- // Adjust index after removal
		}
	}

	// Check for --system flag
	for i := 0; i < len(args); i++ {
		if (args[i] == "--system" || args[i] == "-s") && i+1 < len(args) {
			systemPrompt = args[i+1]
			// Remove --system and value from args
			copy(args[i:], args[i+2:])
			args = args[:len(args)-2]
			i-- // Adjust index after removal
		}
	}

	// Check for --file flag
	fileFlagFound := false
	for i := 0; i < len(args); i++ {
		if args[i] == "--file" || args[i] == "-f" {
			if i+1 >= len(args) {
				log.Fatal("Error: No file specified")
			}
			filePath := args[i+1]
			content, err := os.ReadFile(filePath)
			if err != nil {
				log.Fatalf("Error reading file: %v", err)
			}
			prompt = string(content)
			// Remove --file and path from args
			copy(args[i:], args[i+2:])
			args = args[:len(args)-2]
			fileFlagFound = true
			break
		}
	}

	// If no file flag, use remaining args or stdin
	if !fileFlagFound {
		if len(args) > 0 {
			prompt = strings.Join(args, " ")
		} else if !isatty(os.Stdin.Fd()) {
			// Read from stdin
			reader := bufio.NewReader(os.Stdin)
			var content strings.Builder
			for {
				line, err := reader.ReadString('\n')
				content.WriteString(line)
				if err != nil {
					if err == io.EOF {
						break
					}
					log.Fatalf("Error reading stdin: %v", err)
				}
			}
			prompt = content.String()
		}
	}

	if strings.TrimSpace(prompt) == "" {
		fmt.Fprintln(os.Stderr, "Error: No prompt provided")
		fmt.Fprintln(os.Stderr, "Usage: gemini-ask \"your question\"")
		fmt.Fprintln(os.Stderr, "       gemini-ask --model gemini-pro \"your question\"")
		fmt.Fprintln(os.Stderr, "       echo \"your question\" | gemini-ask")
		os.Exit(1)
	}

	// Initialize Gemini client
	ctx := context.Background()
	client, err := genai.NewClient(ctx, option.WithAPIKey(apiKey))
	if err != nil {
		log.Fatalf("Error creating client: %v", err)
	}
	defer client.Close()

	// Configure model
	model := client.GenerativeModel(modelName)
	model.SetMaxOutputTokens(8192)
	model.SetTemperature(0.7)
	model.SetTopP(0.95)

	// Generate response
	var response *genai.GenerateContentResponse
	if systemPrompt != "" {
		// Use chat with system prompt
		session := model.StartChat()
		session.History = []*genai.Content{
			&genai.Content{
				Parts: []genai.Part{
					genai.Text(systemPrompt),
				},
				Role: "user",
			},
			&genai.Content{
				Parts: []genai.Part{
					genai.Text("Understood. I will follow that instruction."),
				},
				Role: "model",
			},
		}
		response, err = session.SendMessage(ctx, genai.Text(prompt))
	} else {
		// Direct generation
		response, err = model.GenerateContent(ctx, genai.Text(prompt))
	}

	if err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		if strings.Contains(err.Error(), "API key") {
			fmt.Fprintln(os.Stderr, "Make sure GEMINI_API_KEY is set correctly")
		}
		os.Exit(1)
	}

	// Print response
	for _, candidate := range response.Candidates {
		for _, part := range candidate.Content.Parts {
			fmt.Println(part)
		}
	}
}

func isatty(fd uintptr) bool {
	// Simple check - in a real implementation you might want to use syscall
	// This is a placeholder - Go's os.Stdin.isTTY equivalent isn't directly available
	// For this CLI tool, we'll assume it's not a TTY when there's piped input
	stat, _ := os.Stdin.Stat()
	return (stat.Mode() & os.ModeCharDevice) != 0
}
