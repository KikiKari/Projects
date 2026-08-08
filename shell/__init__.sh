#!/bin/bash
# __init__.py — portiert nach shell
# Quelle: python, OpenClaw@main:openclaw/__init__.py
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# This bash script mimics the Python __init__.py functionality
# by defining version and available components as environment variables

# Version information
export GATEWAY_VERSION="0.1.0a1"

# Available components (simulating Python's __all__)
export GATEWAY_COMPONENTS="GatewayClient,ClusterManager"

# Note: In bash, we can't directly import other scripts like Python's import statements.
# The actual client and cluster functionality would need to be implemented
# as separate bash scripts or functions that are sourced when needed.
