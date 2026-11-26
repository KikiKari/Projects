// abstraction-provenance: {"artifact_sha256": "6d09b932620ff53f2fb30cc40fc51de669662d428df0d47265e38a71c8e3ec88", "source_sha256": "40b902ee3739509c4b2ef72ed57b4d983e5b509f6e446d20ab14d630d9773322", "target_language": "go"}
// json_batch_processor.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:skills/json-utils/scripts/json_batch_processor.py
// auch in: OpenClaw@gateway2:skills/json-utils/scripts/json_batch_processor.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py


package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"sync"
)

// JSONProcessingError represents a custom error for JSON processing issues
type JSONProcessingError struct {
	Message string
}

func (e *JSONProcessingError) Error() string {
	return e.Message
}

// BatchResult represents the result of a batch processing operation
type BatchResult struct {
	Index   int         `json:"index"`
	Source  string      `json:"source"`
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Error   *string     `json:"error,omitempty"`
}

// ToMap converts BatchResult to map[string]interface{}
func (br *BatchResult) ToMap() map[string]interface{} {
	result := map[string]interface{}{
		"index":   br.Index,
		"source":  br.Source,
		"success": br.Success,
	}
	
	if br.Data != nil {
		result["data"] = br.Data
	}
	
	if br.Error != nil {
		result["error"] = *br.Error
	}
	
	return result
}

// readJSONL reads JSON-Lines (NDJSON) file line by line
func readJSONL(filePath string) ([]interface{}, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}
	defer file.Close()

	var results []interface{}
	scanner := bufio.NewScanner(file)
	lineNum := 0
	
	for scanner.Scan() {
		lineNum++
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}
		
		var data interface{}
		err := json.Unmarshal([]byte(line), &data)
		if err != nil {
			errorMsg := fmt.Sprintf("JSON decode error: %v", err)
			results = append(results, &BatchResult{
				Index:   lineNum,
				Source:  fmt.Sprintf("%s:%d", filePath, lineNum),
				Success: false,
				Error:   &errorMsg,
			})
		} else {
			results = append(results, data)
		}
	}
	
	return results, scanner.Err()
}

// parseJSON parses JSON string with optional repair
func parseJSON(content string, repair bool) (interface{}, error) {
	var data interface{}
	err := json.Unmarshal([]byte(content), &data)
	if err != nil && repair {
		// Simple repair attempt - remove trailing commas
		repaired := strings.ReplaceAll(content, ",}", "}")
		repaired = strings.ReplaceAll(repaired, ",]", "]")
		err = json.Unmarshal([]byte(repaired), &data)
	}
	
	if err != nil {
		return nil, &JSONProcessingError{Message: err.Error()}
	}
	
	return data, nil
}

// processBatch processes a list of inputs in parallel
func processBatch(inputs []string, processor func(string, int) *BatchResult, maxWorkers int) []*BatchResult {
	results := make([]*BatchResult, len(inputs))
	
	// Create worker pool
	numWorkers := maxWorkers
	if numWorkers <= 0 {
		numWorkers = runtime.NumCPU()
	}
	
	type workItem struct {
		input string
		index int
	}
	
	workQueue := make(chan workItem, len(inputs))
	resultQueue := make(chan *BatchResult, len(inputs))
	
	var wg sync.WaitGroup
	
	// Start workers
	for i := 0; i < numWorkers; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for work := range workQueue {
				result := processor(work.input, work.index)
				resultQueue <- result
			}
		}()
	}
	
	// Send work
	go func() {
		for i, input := range inputs {
			workQueue <- workItem{input: input, index: i}
		}
		close(workQueue)
	}()
	
	// Close result queue when all workers are done
	go func() {
		wg.Wait()
		close(resultQueue)
	}()
	
	// Collect results
	collected := 0
	for result := range resultQueue {
		results[result.Index] = result
		collected++
	}
	
	// Handle any missing results (shouldn't happen with proper synchronization)
	for i, result := range results {
		if result == nil {
			errorMsg := "Processing was cancelled"
			results[i] = &BatchResult{
				Index:   i,
				Source:  inputs[i],
				Success: false,
				Error:   &errorMsg,
			}
		}
	}
	
	return results
}

// processFileBatch processes multiple JSON files in batch
func processFileBatch(filePaths []string, repair bool, maxWorkers int) []*BatchResult {
	processor := func(path string, idx int) *BatchResult {
		content, err := ioutil.ReadFile(path)
		if err != nil {
			errorMsg := err.Error()
			return &BatchResult{
				Index:   idx,
				Source:  path,
				Success: false,
				Error:   &errorMsg,
			}
		}
		
		data, err := parseJSON(string(content), repair)
		if err != nil {
			errorMsg := err.Error()
			return &BatchResult{
				Index:   idx,
				Source:  path,
				Success: false,
				Error:   &errorMsg,
			}
		}
		
		return &BatchResult{
			Index:   idx,
			Source:  path,
			Success: true,
			Data:    data,
		}
	}
	
	return processBatch(filePaths, processor, maxWorkers)
}

// processJSONLFile processes a JSON-Lines file
func processJSONLFile(filePath string, repair bool) []*BatchResult {
	var results []*BatchResult
	
	file, err := os.Open(filePath)
	if err != nil {
		errorMsg := err.Error()
		return append(results, &BatchResult{
			Index:   0,
			Source:  filePath,
			Success: false,
			Error:   &errorMsg,
		})
	}
	defer file.Close()
	
	scanner := bufio.NewScanner(file)
	lineNum := 0
	
	for scanner.Scan() {
		lineNum++
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}
		
		data, err := parseJSON(line, repair)
		source := fmt.Sprintf("%s:%d", filePath, lineNum)
		
		if err != nil {
			errorMsg := err.Error()
			results = append(results, &BatchResult{
				Index:   lineNum,
				Source:  source,
				Success: false,
				Error:   &errorMsg,
			})
		} else {
			results = append(results, &BatchResult{
				Index:   lineNum,
				Source:  source,
				Success: true,
				Data:    data,
			})
		}
	}
	
	if err := scanner.Err(); err != nil {
		errorMsg := err.Error()
		results = append(results, &BatchResult{
			Index:   lineNum + 1,
			Source:  filePath,
			Success: false,
			Error:   &errorMsg,
		})
	}
	
	return results
}

// writeJSONL writes BatchResult list as JSON-Lines
func writeJSONL(results []*BatchResult, outputPath string, onlySuccessful bool) error {
	file, err := os.Create(outputPath)
	if err != nil {
		return err
	}
	defer file.Close()
	
	writer := bufio.NewWriter(file)
	defer writer.Flush()
	
	for _, result := range results {
		if onlySuccessful && !result.Success {
			continue
		}
		
		jsonData, err := json.Marshal(result.ToMap())
		if err != nil {
			return err
		}
		
		_, err = writer.WriteString(string(jsonData) + "\n")
		if err != nil {
			return err
		}
	}
	
	return nil
}

func main() {
	var (
		jsonlFlag       = flag.Bool("jsonl", false, "Treat inputs as JSON-Lines files")
		jsonlShort      = flag.Bool("l", false, "Treat inputs as JSON-Lines files (short)")
		repairFlag      = flag.Bool("repair", true, "Enable JSON repair")
		repairShort     = flag.Bool("r", true, "Enable JSON repair (short)")
		workersFlag     = flag.Int("workers", 4, "Parallel workers")
		workersShort    = flag.Int("w", 4, "Parallel workers (short)")
		outputFlag      = flag.String("output", "", "Output JSON-Lines file")
		outputShort     = flag.String("o", "", "Output JSON-Lines file (short)")
		summaryFlag     = flag.Bool("summary", false, "Show summary only")
		summaryShort   = flag.Bool("s", false, "Show summary only (short)")
	)
	
	flag.Parse()
	
	// Handle short flags
	jsonlMode := *jsonlFlag || *jsonlShort
	repair := *repairFlag || *repairShort
	workers := *workersFlag
	if *workersShort != 4 { // Only override if explicitly set
		workers = *workersShort
	}
	outputPath := *outputFlag
	if outputPath == "" && *outputShort != "" {
		outputPath = *outputShort
	}
	summaryOnly := *summaryFlag || *summaryShort
	
	inputs := flag.Args()
	if len(inputs) == 0 {
		fmt.Fprintln(os.Stderr, "Error: No input files provided")
		os.Exit(1)
	}
	
	var allResults []*BatchResult
	
	if jsonlMode {
		// JSON-Lines mode
		for _, inputPath := range inputs {
			results := processJSONLFile(inputPath, repair)
			allResults = append(allResults, results...)
		}
	} else {
		// Standard JSON batch mode
		allResults = processFileBatch(inputs, repair, workers)
	}
	
	// Calculate statistics
	successful := 0
	for _, result := range allResults {
		if result.Success {
			successful++
		}
	}
	failed := len(allResults) - successful
	
	// Output results
	if *summaryOnly {
		fmt.Printf("Processed: %d\n", len(allResults))
		fmt.Printf("Successful: %d\n", successful)
		fmt.Printf("Failed: %d\n", failed)
	} else {
		for _, result := range allResults {
			if result.Success {
				jsonData, err := json.Marshal(result.Data)
				if err != nil {
					fmt.Fprintf(os.Stderr, "ERROR [%s]: Failed to marshal data: %v\n", result.Source, err)
				} else {
					fmt.Println(string(jsonData))
				}
			} else {
				fmt.Fprintf(os.Stderr, "ERROR [%s]: %s\n", result.Source, *result.Error)
			}
		}
	}
	
	// Optional: JSONL output
	if outputPath != "" {
		err := writeJSONL(allResults, outputPath, false)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error writing to output file: %v\n", err)
		} else {
			fmt.Fprintf(os.Stderr, "\nResults written to: %s\n", outputPath)
		}
	}
	
	// Exit code
	if failed > 0 {
		os.Exit(1)
	}
}

func init() {
	// Set usage function
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: %s [options] inputs...\n", filepath.Base(os.Args[0]))
		fmt.Fprintln(os.Stderr, "Batch JSON Processor - Verarbeitet mehrere JSON-Dateien oder JSON-Lines (NDJSON).")
		fmt.Fprintln(os.Stderr, "\nOptions:")
		flag.PrintDefaults()
	}
}
