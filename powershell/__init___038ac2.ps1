#!/usr/bin/env pwsh
# __init__.py — portiert nach powershell
# Quelle: python, Projects@MCP-Server-Monitor:mcpmon/__init__.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

<#
.SYNOPSIS
MCP-Server-Monitor — Zustand fremder MCP-Server feststellen.

.DESCRIPTION
Nur Standardbibliothek. Kein pip, kein Framework, keine Pflicht-Zugangsdaten.
#>

# Skriptweite Variablen definieren
$script:__version__ = "0.1.0"
$script:__all__ = @("discovery", "state", "config", "report")
