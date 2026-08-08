#!/usr/bin/env tclsh
# __init__.py — portiert nach tcl
# Quelle: python, Projects@MCP-Server-Monitor:mcpmon/__init__.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# MCP-Server-Monitor — Zustand fremder MCP-Server feststellen.
# 
# Nur Standardbibliothek. Kein pip, kein Framework, keine Pflicht-Zugangsdaten.

package provide mcp_server_monitor 0.1.0

namespace eval ::mcp_server_monitor {
    variable version "0.1.0"
    
    # Define the public API components
    namespace export discovery state config report
}
