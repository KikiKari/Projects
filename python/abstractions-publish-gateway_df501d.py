#!/usr/bin/env python3
# abstractions-publish-gateway.pl — portiert nach python
# Quelle: perl5, Projects@abstractions:perl5/abstractions-publish-gateway.pl
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# abstractions-publish-gateway.sh — portiert nach python3
# Quelle: shell, OpenClaw@gateway2:scripts/abstractions-publish-gateway.sh
# Erzeugt: 2026-08-07 durch ABSTRACTIONS_MANAGER.py

import sys
import os

# Workspace-visible wrapper for the gateway publish job.
os.execv('/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh', 
         ['/home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh'] + sys.argv[1:])
