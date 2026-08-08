#!/usr/bin/env node
// __init__.py — portiert nach javascript
// Quelle: python, Projects@MCP-Server-Monitor:mcpmon/__init__.py
// Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

/**
 * MCP-Server-Monitor — Zustand fremder MCP-Server feststellen.
 *
 * Nur Standardbibliothek. Kein pip, kein Framework, keine Pflicht-Zugangsdaten.
 */
const __version__ = "0.1.0";

// In Node.js gibt es kein direktes Äquivalent zu Python's __all__, 
// aber wir können die Module explizit exportieren
const discovery = require('./discovery');
const state = require('./state');
const config = require('./config');
const report = require('./report');

module.exports = {
  __version__,
  discovery,
  state,
  config,
  report
};
