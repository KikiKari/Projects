#!/usr/bin/env node
// websearch-monitor.sh — portiert nach javascript
// Quelle: shell, OpenClaw@gateway1:scripts/websearch-monitor.sh
// auch in: OpenClaw@gateway2:scripts/websearch-monitor.sh
// Erzeugt: 2026-08-23 durch ABSTRACTIONS_MANAGER.py

// Web Search Script: Server-Monitoring mit Tavily
// Verwendung: node websearch-monitor.js [TOPIC]

import { exec } from 'child_process';
import { promisify } from 'util';
import fetch from 'node-fetch';

const execPromise = promisify(exec);

// Hilfsfunktion zur Ausführung von Shell-Befehlen
async function executeCommand(command) {
  try {
    const { stdout } = await execPromise(command);
    return stdout.trim();
  } catch (error) {
    return null;
  }
}

// Prüfe, ob ein Befehl verfügbar ist
async function isCommandAvailable(command) {
  try {
    await execPromise(`command -v ${command}`);
    return true;
  } catch {
    return false;
  }
}

// Hauptfunktion
async function main() {
  const topic = process.argv[2] || "Linux kernel security updates";
  
  console.log(`Prüfe: ${topic}`);
  
  // Versuche zuerst Tavily CLI
  if (await isCommandAvailable('tvly')) {
    try {
      const command = `tvly search "${topic}" --topic news --time-range week --max-results 5 --include-answer advanced 2>/dev/null`;
      const result = await executeCommand(command);
      
      if (result) {
        const jsonData = JSON.parse(result);
        console.log(jsonData.answer || "Keine Zusammenfassung verfügbar");
      }
    } catch (error) {
      // Fallback zu einfacher Web-Suche
      await fallbackSearch(topic);
    }
  } else {
    // Fallback zu einfacher Web-Suche
    await fallbackSearch(topic);
  }
}

// Fallback-Suchfunktion
async function fallbackSearch(topic) {
  try {
    const encodedTopic = encodeURIComponent(topic);
    const response = await fetch(`http://localhost:8888/search?q=${encodedTopic}&format=json`);
    
    if (!response.ok) {
      throw new Error('Network response was not ok');
    }
    
    const data = await response.json();
    
    if (data.results && Array.isArray(data.results)) {
      const results = data.results.slice(0, 3);
      for (const item of results) {
        console.log(`${item.title}\n${item.url}\n`);
      }
    }
  } catch (error) {
    console.log("SearXNG nicht verfügbar");
  }
}

main().catch(console.error);
