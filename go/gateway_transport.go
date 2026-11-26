// abstraction-provenance: {"artifact_sha256": "6bc85b981b5e050c20d32ac25e6b02313379354e335afca8283ce01ee65ebe28", "source_sha256": "12c3ea0e67b1e873ac253df6f3f06d5ed42b603005d56186c531d8a5b0d7f377", "target_language": "go"}
// gateway_transport.py — portiert nach go
// Quelle: python, OpenClaw@gateway1:skills/script-abstractions-manager/scripts/gateway_transport.py
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py


// Gateway-authenticated transport with manager-owned attempt records.
//
// An attempt is saved before submission. If its outcome is uncertain, subsequent
// calls only query the same node and attempt; they do not submit it again.

package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"
)

type TransportUnresolved struct {
	message string
	err     error
}

func (e *TransportUnresolved) Error() string {
	if e.err != nil {
		return fmt.Sprintf("%s: %v", e.message, e.err)
	}
	return e.message
}

func (e *TransportUnresolved) Unwrap() error {
	return e.err
}

func gatewayToken() string {
	token := strings.TrimSpace(os.Getenv("OPENCLAW_GATEWAY_TOKEN"))
	if token != "" {
		return token
	}
	configPath := os.Getenv("OPENCLAW_CONFIG_PATH")
	if configPath == "" {
		homeDir, err := os.UserHomeDir()
		if err != nil {
			return ""
		}
		configPath = filepath.Join(homeDir, ".openclaw", "openclaw.json")
	}
	data, err := os.ReadFile(configPath)
	if err != nil {
		return ""
	}
	var config map[string]interface{}
	if err := json.Unmarshal(data, &config); err != nil {
		return ""
	}
	gateway, ok := config["gateway"].(map[string]interface{})
	if !ok {
		return ""
	}
	auth, ok := gateway["auth"].(map[string]interface{})
	if !ok {
		return ""
	}
	tokenVal, ok := auth["token"].(string)
	if !ok || strings.HasPrefix(tokenVal, "${") {
		return ""
	}
	return strings.TrimSpace(tokenVal)
}

type GatewayTransport struct {
	state   map[string]interface{}
	save    func(map[string]interface{})
	url     string
	token   string
	timeout time.Duration
	interval time.Duration
	client  *http.Client
	clock   func() time.Time
	sleep   func(time.Duration)
}

func NewGatewayTransport(state map[string]interface{}, save func(map[string]interface{}), urlStr, token string, timeout, interval int, client *http.Client) (*GatewayTransport, error) {
	parsed, err := url.Parse(urlStr)
	if err != nil {
		return nil, fmt.Errorf("invalid Gateway URL: %v", err)
	}
	if parsed.Scheme != "http" && parsed.Scheme != "https" {
		return nil, fmt.Errorf("invalid Gateway URL")
	}
	if parsed.Scheme == "http" && parsed.Hostname() != "127.0.0.1" && parsed.Hostname() != "localhost" && parsed.Hostname() != "::1" {
		return nil, fmt.Errorf("unencrypted Gateway must use loopback")
	}
	if strings.TrimSpace(token) == "" || timeout <= 0 || interval <= 0 {
		return nil, fmt.Errorf("Gateway token and positive timeouts required")
	}
	
	if client == nil {
		client = &http.Client{}
	}
	
	return &GatewayTransport{
		state:   state,
		save:    save,
		url:     urlStr,
		token:   strings.TrimSpace(token),
		timeout: time.Duration(timeout) * time.Second,
		interval: time.Duration(interval) * time.Second,
		client:  client,
		clock:   time.Now,
		sleep:   time.Sleep,
	}, nil
}

func (gt *GatewayTransport) _request(node string, request map[string]interface{}, deviceID interface{}) (map[string]interface{}, error) {
	payloadData := map[string]interface{}{
		"node":      node,
		"device_id": deviceID,
		"request":   request,
	}
	payloadBytes, err := json.Marshal(payloadData)
	if err != nil {
		return nil, &TransportUnresolved{"failed to marshal request", err}
	}
	
	req, err := http.NewRequest("POST", gt.url, bytes.NewBuffer(payloadBytes))
	if err != nil {
		return nil, &TransportUnresolved{"failed to create request", err}
	}
	req.Header.Set("Authorization", "Bearer "+gt.token)
	req.Header.Set("Content-Type", "application/json")
	
	ctxTimeout := 40 * time.Second
	if node == "node4" {
		ctxTimeout = 150 * time.Second
	}
	ctx, cancel := context.WithTimeout(context.Background(), ctxTimeout)
	defer cancel()
	req = req.WithContext(ctx)
	
	resp, err := gt.client.Do(req)
	if err != nil {
		return nil, &TransportUnresolved{"Gateway request failed", err}
	}
	defer resp.Body.Close()
	
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 4000001))
	if err != nil {
		return nil, &TransportUnresolved{"failed to read response", err}
	}
	if len(raw) > 4000000 {
		return nil, &TransportUnresolved{"response too large", nil}
	}
	
	var data map[string]interface{}
	if err := json.Unmarshal(raw, &data); err != nil {
		return nil, &TransportUnresolved{"invalid gateway response", err}
	}
	
	if _, ok := data["result"]; !ok {
		return nil, &TransportUnresolved{"invalid gateway response", nil}
	}
	
	if deviceID != nil {
		if respDeviceID, ok := data["device_id"]; !ok || respDeviceID != deviceID {
			return nil, &TransportUnresolved{"gateway device identity mismatch", nil}
		}
	}
	
	result, ok := data["result"].(map[string]interface{})
	if !ok {
		return nil, &TransportUnresolved{"invalid gateway response format", nil}
	}
	
	return result, nil
}

func (gt *GatewayTransport) Available() (map[string]interface{}, error) {
	result, err := gt._request("node1", map[string]interface{}{"operation": "availability"}, nil)
	if err != nil {
		return nil, err
	}
	
	if _, ok := result.(map[string]interface{}); !ok {
		return nil, &TransportUnresolved{"invalid node availability", nil}
	}
	
	return result, nil
}

func (gt *GatewayTransport) _release(original map[string]interface{}, entry map[string]interface{}) {
	if released, ok := entry["released"].(bool); ok && released {
		return
	}
	
	defer func() {
		// Retry cleanup later; the result is durable in manager state.
		if r := recover(); r != nil {
			// Ignore panic
		}
	}()
	
	result, err := gt._request(
		original["selected_node"].(string),
		map[string]interface{}{
			"operation":  "release",
			"job_id":      original["job_id"],
			"attempt_id":  original["attempt_id"],
		},
		original["selected_device_id"],
	)
	
	if err != nil {
		return // Retry cleanup later
	}
	
	if status, ok := result["status"].(string); ok && status == "released" {
		match := true
		for _, key := range []string{"job_id", "attempt_id", "selected_node", "target_language"} {
			if result[key] != original[key] {
				match = false
				break
			}
		}
		if match {
			entry["released"] = true
			gt.save(gt.state)
		}
	}
}

func (gt *GatewayTransport) ReleasePending() {
	auftraege, ok := gt.state["auftraege"].(map[string]interface{})
	if !ok {
		return
	}
	
	for _, v := range auftraege {
		entry, ok := v.(map[string]interface{})
		if !ok {
			continue
		}
		
		status, ok := entry["status"].(string)
		if !ok || (status != "completed" && status != "rejected" && status != "failed") {
			continue
		}
		
		job, ok := entry["job"].(map[string]interface{})
		if !ok {
			continue
		}
		
		gt._release(job, entry)
	}
}

func (gt *GatewayTransport) Reject(job map[string]interface{}, reason string) {
	sourceSHA256, ok1 := job["source_sha256"].(string)
	targetLanguage, ok2 := job["target_language"].(string)
	if !ok1 || !ok2 {
		return
	}
	
	key := sourceSHA256 + ":" + targetLanguage
	auftraege, ok := gt.state["auftraege"].(map[string]interface{})
	if !ok {
		return
	}
	
	entry, ok := auftraege[key].(map[string]interface{})
	if !ok || entry["status"] != "completed" {
		return
	}
	
	entryJob, ok := entry["job"].(map[string]interface{})
	if !ok {
		return
	}
	
	attemptID1, ok1 := entryJob["attempt_id"]
	attemptID2, ok2 := job["attempt_id"]
	if !ok1 || !ok2 || attemptID1 != attemptID2 {
		panic(&TransportUnresolved{"rejected attempt identity mismatch", nil})
	}
	
	entry["status"] = "rejected"
	if len(reason) > 500 {
		reason = reason[:500]
	}
	entry["validation_error"] = reason
	gt.save(gt.state)
}

func (gt *GatewayTransport) Call(job map[string]interface{}) (map[string]interface{}, error) {
	sourceSHA256, ok1 := job["source_sha256"].(string)
	targetLanguage, ok2 := job["target_language"].(string)
	selectedDeviceID, ok3 := job["selected_device_id"]
	
	if !ok1 || !ok2 || !ok3 {
		return nil, fmt.Errorf("missing source identity")
	}
	
	key := sourceSHA256 + ":" + targetLanguage
	auftraege, ok := gt.state["auftraege"].(map[string]interface{})
	if !ok {
		auftraege = make(map[string]interface{})
		gt.state["auftraege"] = auftraege
	}
	
	var entry map[string]interface{}
	var fresh bool
	
	if existingEntry, exists := auftraege[key]; exists {
		if entryMap, ok := existingEntry.(map[string]interface{}); ok && entryMap["status"] == "rejected" {
			jobMap, ok := entryMap["job"].(map[string]interface{})
			if ok {
				gt._release(jobMap, entryMap)
				
				if released, ok := entryMap["released"].(bool); !ok || !released {
					return nil, &TransportUnresolved{"rejected attempt release is unresolved", nil}
				}
				
				previous := entryMap
				original := make(map[string]interface{})
				for k, v := range job {
					original[k] = v
				}
				original["attempt_id"] = uuid.New().String()
				
				entry = map[string]interface{}{
					"job": original,
					"status": "submitted",
				}
				
				if prevAttempts, ok := previous["previous_attempts"].([]interface{}); ok {
					newAttempts := make([]interface{}, len(prevAttempts))
					copy(newAttempts, prevAttempts)
					newAttempt := map[string]interface{}{
						"job_id":         getMapValue(getMapValue(previous, "job"), "job_id"),
						"attempt_id":     getMapValue(getMapValue(previous, "job"), "attempt_id"),
						"selected_node":  getMapValue(getMapValue(previous, "job"), "selected_node"),
						"validation_error": previous["validation_error"],
					}
					entry["previous_attempts"] = append(newAttempts, newAttempt)
				} else {
					entry["previous_attempts"] = []interface{}{
						map[string]interface{}{
							"job_id":         getMapValue(getMapValue(previous, "job"), "job_id"),
							"attempt_id":     getMapValue(getMapValue(previous, "job"), "attempt_id"),
							"selected_node":  getMapValue(getMapValue(previous, "job"), "selected_node"),
							"validation_error": previous["validation_error"],
						},
					}
				}
				
				auftraege[key] = entry
				gt.save(gt.state)
				fresh = true
			}
		} else {
			entry = entryMap
			fresh = false
		}
	} else {
		original := make(map[string]interface{})
		for k, v := range job {
			original[k] = v
		}
		original["attempt_id"] = uuid.New().String()
		
		entry = map[string]interface{}{
			"job":    original,
			"status": "submitted",
		}
		
		auftraege[key] = entry
		// If this write fails there must be no remote submission.
		gt.save(gt.state)
		fresh = true
	}
	
	if entry == nil {
		return nil, fmt.Errorf("entry is nil")
	}
	
	original, ok := entry["job"].(map[string]interface{})
	if !ok {
		return nil, fmt.Errorf("invalid job data")
	}
	
	// The dispatcher verifies the job object after transport returns.
	for k, v := range original {
		job[k] = v
	}
	
	if response, ok := entry["response"]; ok && response != nil {
		gt._release(original, entry)
		return response.(map[string]interface{}), nil
	}
	
	if status, ok := entry["status"].(string); ok && status == "failed" {
		return nil, &TransportUnresolved{"attempt requires reconciliation", nil}
	}
	
	var status map[string]interface{}
	var err error
	
	if fresh {
		defer func() {
			if r := recover(); r != nil {
				// The request may have been accepted. Query, never resend.
			}
		}()
		
		status, err = gt._request(
			original["selected_node"].(string),
			map[string]interface{}{
				"operation": "execute",
				"job":       original,
			},
			original["selected_device_id"],
		)
		
		if err != nil {
			status = nil // The request may have been accepted. Query, never resend.
		}
	}
	
	deadline := gt.clock().Add(gt.timeout)
	
	for {
		if status == nil {
			status, err = gt._request(
				original["selected_node"].(string),
				map[string]interface{}{
					"operation":  "status",
					"job_id":     original["job_id"],
					"attempt_id": original["attempt_id"],
				},
				original["selected_device_id"],
			)
			
			if err != nil {
				return nil, err
			}
		}
		
		if _, ok := status.(map[string]interface{}); !ok {
			return nil, &TransportUnresolved{"attempt is not known by the node", nil}
		}
		
		mismatch := false
		for _, k := range []string{"job_id", "attempt_id", "selected_node", "target_language"} {
			if status[k] != original[k] {
				mismatch = true
				break
			}
		}
		if mismatch {
			return nil, &TransportUnresolved{"status identity mismatch", nil}
		}
		
		state, ok := status["status"].(string)
		if !ok {
			return nil, &TransportUnresolved{"invalid status", nil}
		}
		
		if state == "completed" {
			response, ok := status["response"].(map[string]interface{})
			if !ok {
				return nil, &TransportUnresolved{"invalid translation result", nil}
			}
			
			responseStatus, ok := response["status"].(string)
			if !ok || responseStatus != "ok" {
				return nil, &TransportUnresolved{"invalid translation result", nil}
			}
			
			for _, k := range []string{"job_id", "selected_node", "target_language"} {
				if response[k] != original[k] {
					return nil, &TransportUnresolved{"invalid translation result", nil}
				}
			}
			
			code, ok := response["code"].(string)
			if !ok || strings.TrimSpace(code) == "" {
				return nil, &TransportUnresolved{"invalid translation result", nil}
			}
			
			entry["response"] = response
			entry["status"] = "completed"
			gt.save(gt.state)
			gt._release(original, entry)
			return response, nil
		}
		
		if state == "failed" || state == "unknown" {
			entry["status"] = state
			gt.save(gt.state)
			if state == "failed" {
				gt._release(original, entry)
			}
			return nil, &TransportUnresolved{"attempt requires reconciliation", nil}
		}
		
		if state != "running" || gt.clock().After(deadline) {
			return nil, &TransportUnresolved{"attempt is unresolved", nil}
		}
		
		gt.sleep(gt.interval)
		status = nil
	}
}

func getMapValue(m map[string]interface{}, key string) interface{} {
	if m == nil {
		return nil
	}
	return m[key]
}

func main() {
	// This would be the entry point if this were a standalone program
	// Since this is a library module, main is empty
}
