#!/usr/bin/env tclsh
# abstractions-publish-gateway.pl — portiert nach tcl
# Quelle: perl5, Projects@abstractions:perl5/abstractions-publish-gateway.pl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions-publish-gateway.sh — portiert nach perl5
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

# Workspace-visible wrapper for the gateway publish job.
exec /home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh {*}$argv
