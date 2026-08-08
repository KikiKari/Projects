#!/bin/bash
# __init__.py — portiert nach shell
# Quelle: python, Projects@MCP-Server-Monitor:mcpmon/__init__.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# MCP-Server-Monitor — Zustand fremder MCP-Server feststellen.
#
# Nur Standardbibliothek. Kein pip, kein Framework, keine Pflicht-Zugangsdaten.

__version__="0.1.0"

# In Bash gibt es kein direktes Äquivalent zu __all__, aber wir können
# die relevanten Module/Dateien als Array defininierten, falls benötigt.
# modules=("discovery" "state" "config" "report")
