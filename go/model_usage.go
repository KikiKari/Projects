// abstraction-provenance: {"artifact_sha256": "dfd8618dd7aea3379df4b0244f230accedc29d621a493c84e9e222abda5796f7", "source_sha256": "502dcda47466a4ab74da59badbe4b12c4782ed031c43d5038f8bd8534373cd35", "target_language": "go"}
// model_usage.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:skills/model-usage/scripts/model_usage.py
// auch in: OpenClaw@gateway2:skills/model-usage/scripts/model_usage.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

/*
Summarize CodexBar local cost usage by model.

Defaults to current model (most recent daily entry), or list all models.
*/

package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"os/exec"
	"sort"
	"strconv"
	"strings"
	"time"
)

func eprint(msg string) {
	fmt.Fprintln(os.Stderr, msg)
}

func runCodexbarCost(provider string) ([]map[string]interface{}, error) {
	cmd := exec.Command("codexbar", "cost", "--format", "json", "--provider", provider)
	output, err := cmd.Output()
	if err != nil {
		if _, ok := err.(*exec.Error); ok {
			return nil, fmt.Errorf("codexbar not found on PATH. Install CodexBar CLI first.")
		}
		if exitErr, ok := err.(*exec.ExitError); ok {
			return nil, fmt.Errorf("codexbar cost failed (exit %d).", exitErr.ExitCode())
		}
		return nil, err
	}

	var payload []map[string]interface{}
	err = json.Unmarshal(output, &payload)
	if err != nil {
		return nil, fmt.Errorf("failed to parse codexbar JSON output: %v", err)
	}
	return payload, nil
}

func loadPayload(inputPath *string, provider string) (map[string]interface{}, error) {
	var data interface{}
	
	if inputPath != nil {
		var raw []byte
		if *inputPath == "-" {
			raw, _ = io.ReadAll(os.Stdin)
		} else {
			content, err := os.ReadFile(*inputPath)
			if err != nil {
				return nil, err
			}
			raw = content
		}
		err := json.Unmarshal(raw, &data)
		if err != nil {
			return nil, err
		}
	} else {
		payload, err := runCodexbarCost(provider)
		if err != nil {
			return nil, err
		}
		data = payload
	}

	if m, ok := data.(map[string]interface{}); ok {
		return m, nil
	}

	if arr, ok := data.([]interface{}); ok {
		for _, entry := range arr {
			if m, ok := entry.(map[string]interface{}); ok {
				if p, ok := m["provider"]; ok && p == provider {
					return m, nil
				}
			}
		}
		return nil, fmt.Errorf("provider '%s' not found in codexbar payload", provider)
	}

	return nil, fmt.Errorf("unsupported JSON input format")
}

type ModelCost struct {
	Model string
	Cost  float64
}

func parseDailyEntries(payload map[string]interface{}) []map[string]interface{} {
	daily, exists := payload["daily"]
	if !exists {
		return []map[string]interface{}{}
	}
	
	if arr, ok := daily.([]interface{}); ok {
		result := make([]map[string]interface{}, 0)
		for _, entry := range arr {
			if m, ok := entry.(map[string]interface{}); ok {
				result = append(result, m)
			}
		}
		return result
	}
	return []map[string]interface{}{}
}

func parseDate(value string) *time.Time {
	t, err := time.Parse("2006-01-02", value)
	if err != nil {
		return nil
	}
	return &t
}

func filterByDays(entries []map[string]interface{}, days *int) []map[string]interface{} {
	if days == nil {
		return entries
	}
	
	cutoff := time.Now().AddDate(0, 0, -(days-1))
	filtered := make([]map[string]interface{}, 0)
	
	for _, entry := range entries {
		day, exists := entry["date"]
		if !exists {
			continue
		}
		
		if dayStr, ok := day.(string); ok {
			parsed := parseDate(dayStr)
			if parsed != nil && !parsed.Before(cutoff) {
				filtered = append(filtered, entry)
			}
		}
	}
	return filtered
}

func aggregateCosts(entries []map[string]interface{}) map[string]float64 {
	totals := make(map[string]float64)
	
	for _, entry := range entries {
		breakdowns, exists := entry["modelBreakdowns"]
		if !exists {
			continue
		}
		
		if arr, ok := breakdowns.([]interface{}); ok {
			for _, item := range arr {
				if m, ok := item.(map[string]interface{}); ok {
					modelName, modelNameOk := m["modelName"]
					cost, costOk := m["cost"]
					
					if modelNameOk && costOk {
						if modelStr, ok := modelName.(string); ok {
							if costFloat, ok := cost.(float64); ok {
								totals[modelStr] += costFloat
							} else if costInt, ok := cost.(int); ok {
								totals[modelStr] += float64(costInt)
							}
						}
					}
				}
			}
		}
	}
	return totals
}

func pickCurrentModel(entries []map[string]interface{}) (string, string) {
	if len(entries) == 0 {
		return "", ""
	}
	
	// Sort by date
	sort.Slice(entries, func(i, j int) bool {
		dateI, iExists := entries[i]["date"]
		dateJ, jExists := entries[j]["date"]
		
		if !iExists || !jExists {
			return false
		}
		
		dateIStr, iOk := dateI.(string)
		dateJStr, jOk := dateJ.(string)
		
		if !iOk || !jOk {
			return false
		}
		
		return dateIStr < dateJStr
	})
	
	// Iterate backwards through sorted entries
	for i := len(entries) - 1; i >= 0; i-- {
		entry := entries[i]
		breakdowns, exists := entry["modelBreakdowns"]
		
		if exists {
			if arr, ok := breakdowns.([]interface{}); ok && len(arr) > 0 {
				scored := make([]ModelCost, 0)
				
				for _, item := range arr {
					if m, ok := item.(map[string]interface{}); ok {
						modelName, modelNameOk := m["modelName"]
						cost, costOk := m["cost"]
						
						if modelNameOk && costOk {
							if modelStr, ok := modelName.(string); ok {
								if costFloat, ok := cost.(float64); ok {
									scored = append(scored, ModelCost{Model: modelStr, Cost: costFloat})
								} else if costInt, ok := cost.(int); ok {
									scored = append(scored, ModelCost{Model: modelStr, Cost: float64(costInt)})
								}
							}
						}
					}
				}
				
				if len(scored) > 0 {
					sort.Slice(scored, func(i, j int) bool {
						return scored[i].Cost > scored[j].Cost
					})
					
					dateVal := ""
					if dateField, exists := entry["date"]; exists {
						if dateStr, ok := dateField.(string); ok {
							dateVal = dateStr
						}
					}
					return scored[0].Model, dateVal
				}
			}
		}
		
		modelsUsed, exists := entry["modelsUsed"]
		if exists {
			if arr, ok := modelsUsed.([]interface{}); ok && len(arr) > 0 {
				last := arr[len(arr)-1]
				if lastStr, ok := last.(string); ok {
					dateVal := ""
					if dateField, exists := entry["date"]; exists {
						if dateStr, ok := dateField.(string); ok {
							dateVal = dateStr
						}
					}
					return lastStr, dateVal
				}
			}
		}
	}
	return "", ""
}

func usd(value *float64) string {
	if value == nil {
		return "—"
	}
	return fmt.Sprintf("$%s", strconv.FormatFloat(*value, 'f', 2, 64))
}

func latestDayCost(entries []map[string]interface{}, model string) (string, *float64) {
	if len(entries) == 0 {
		return "", nil
	}
	
	// Sort by date
	sort.Slice(entries, func(i, j int) bool {
		dateI, iExists := entries[i]["date"]
		dateJ, jExists := entries[j]["date"]
		
		if !iExists || !jExists {
			return false
		}
		
		dateIStr, iOk := dateI.(string)
		dateJStr, jOk := dateJ.(string)
		
		if !iOk || !jOk {
			return false
		}
		
		return dateIStr < dateJStr
	})
	
	// Iterate backwards through sorted entries
	for i := len(entries) - 1; i >= 0; i-- {
		entry := entries[i]
		breakdowns, exists := entry["modelBreakdowns"]
		if !exists {
			continue
		}
		
		if arr, ok := breakdowns.([]interface{}); ok {
			for _, item := range arr {
				if m, ok := item.(map[string]interface{}); ok {
					if modelName, exists := m["modelName"]; exists && modelName == model {
						cost, costExists := m["cost"]
						var costValue *float64
						if costExists {
							if costFloat, ok := cost.(float64); ok {
								costValue = &costFloat
							} else if costInt, ok := cost.(int); ok {
								floatVal := float64(costInt)
								costValue = &floatVal
							}
						}
						
						day := ""
						if dateField, exists := entry["date"]; exists {
							if dateStr, ok := dateField.(string); ok {
								day = dateStr
							}
						}
						return day, costValue
					}
				}
			}
		}
	}
	return "", nil
}

func renderTextCurrent(
	provider string,
	model string,
	latestDate *string,
	totalCost *float64,
	latestCost *float64,
	latestCostDate *string,
	entryCount int,
) string {
	lines := []string{
		fmt.Sprintf("Provider: %s", provider),
		fmt.Sprintf("Current model: %s", model),
	}
	
	if latestDate != nil && *latestDate != "" {
		lines = append(lines, fmt.Sprintf("Latest model date: %s", *latestDate))
	}
	
	lines = append(lines, fmt.Sprintf("Total cost (rows): %s", usd(totalCost)))
	
	if latestCostDate != nil && *latestCostDate != "" {
		lines = append(lines, fmt.Sprintf("Latest day cost: %s (%s)", usd(latestCost), *latestCostDate))
	}
	
	lines = append(lines, fmt.Sprintf("Daily rows: %d", entryCount))
	return strings.Join(lines, "\n")
}

func renderTextAll(provider string, totals map[string]float64) string {
	lines := []string{
		fmt.Sprintf("Provider: %s", provider),
		"Models:",
	}
	
	// Create slice for sorting
	type kv struct {
		Key   string
		Value float64
	}
	
	var sorted []kv
	for k, v := range totals {
		sorted = append(sorted, kv{k, v})
	}
	
	sort.Slice(sorted, func(i, j int) bool {
		return sorted[i].Value > sorted[j].Value
	})
	
	for _, item := range sorted {
		lines = append(lines, fmt.Sprintf("- %s: %s", item.Key, usd(&item.Value)))
	}
	
	return strings.Join(lines, "\n")
}

func buildJSONCurrent(
	provider string,
	model string,
	latestDate *string,
	totalCost *float64,
	latestCost *float64,
	latestCostDate *string,
	entryCount int,
) map[string]interface{} {
	result := map[string]interface{}{
		"provider":          provider,
		"mode":              "current",
		"model":             model,
		"dailyRowCount":     entryCount,
	}
	
	if latestDate != nil {
		result["latestModelDate"] = *latestDate
	}
	
	if totalCost != nil {
		result["totalCostUSD"] = *totalCost
	}
	
	if latestCost != nil {
		result["latestDayCostUSD"] = *latestCost
	}
	
	if latestCostDate != nil {
		result["latestDayCostDate"] = *latestCostDate
	}
	
	return result
}

func buildJSONAll(provider string, totals map[string]float64) map[string]interface{} {
	type kv struct {
		Key   string
		Value float64
	}
	
	var sorted []kv
	for k, v := range totals {
		sorted = append(sorted, kv{k, v})
	}
	
	sort.Slice(sorted, func(i, j int) bool {
		return sorted[i].Value > sorted[j].Value
	})
	
	models := make([]map[string]interface{}, 0)
	for _, item := range sorted {
		models = append(models, map[string]interface{}{
			"model":        item.Key,
			"totalCostUSD": item.Value,
		})
	}
	
	return map[string]interface{}{
		"provider": provider,
		"mode":     "all",
		"models":   models,
	}
}

func main() {
	// Parse command line arguments manually since we don't have a built-in argparse equivalent
	args := os.Args[1:]
	
	provider := "codex"
	mode := "current"
	var modelArg *string
	var inputArg *string
	var daysArg *int
	format := "text"
	pretty := false
	
	for i := 0; i < len(args); i++ {
		arg := args[i]
		switch arg {
		case "--provider":
			if i+1 < len(args) {
				i++
				provider = args[i]
			}
		case "--mode":
			if i+1 < len(args) {
				i++
				mode = args[i]
			}
		case "--model":
			if i+1 < len(args) {
				i++
				modelArg = &args[i]
			}
		case "--input":
			if i+1 < len(args) {
				i++
				inputArg = &args[i]
			}
		case "--days":
			if i+1 < len(args) {
				i++
				days, err := strconv.Atoi(args[i])
				if err == nil {
					daysArg = &days
				}
			}
		case "--format":
			if i+1 < len(args) {
				i++
				format = args[i]
			}
		case "--pretty":
			pretty = true
		}
	}
	
	payload, err := loadPayload(inputArg, provider)
	if err != nil {
		eprint(err.Error())
		os.Exit(1)
	}
	
	entries := parseDailyEntries(payload)
	entries = filterByDays(entries, daysArg)
	
	if mode == "current" {
		model := ""
		var latestDate *string
		
		if modelArg != nil {
			model = *modelArg
		} else {
			modelStr, latestDateStr := pickCurrentModel(entries)
			model = modelStr
			if latestDateStr != "" {
				latestDate = &latestDateStr
			}
		}
		
		if model == "" {
			eprint("No model data found in codexbar cost payload.")
			os.Exit(2)
		}
		
		totals := aggregateCosts(entries)
		var totalCost *float64
		if val, exists := totals[model]; exists {
			totalCost = &val
		}
		
		latestCostDate, latestCost := latestDayCost(entries, model)
		
		if format == "json" {
			payloadOut := buildJSONCurrent(
				provider,
				model,
				latestDate,
				totalCost,
				latestCost,
				&latestCostDate,
				len(entries),
			)
			
			var jsonData []byte
			if pretty {
				jsonData, _ = json.MarshalIndent(payloadOut, "", "  ")
			} else {
				jsonData, _ = json.Marshal(payloadOut)
			}
			fmt.Println(string(jsonData))
		} else {
			fmt.Println(renderTextCurrent(
				provider,
				model,
				latestDate,
				totalCost,
				latestCost,
				&latestCostDate,
				len(entries),
			))
		}
		os.Exit(0)
	}
	
	totals := aggregateCosts(entries)
	if len(totals) == 0 {
		eprint("No model breakdowns found in codexbar cost payload.")
		os.Exit(2)
	}
	
	if format == "json" {
		payloadOut := buildJSONAll(provider, totals)
		var jsonData []byte
		if pretty {
			jsonData, _ = json.MarshalIndent(payloadOut, "", "  ")
		} else {
			jsonData, _ = json.Marshal(payloadOut)
		}
		fmt.Println(string(jsonData))
	} else {
		fmt.Println(renderTextAll(provider, totals))
	}
	os.Exit(0)
}
