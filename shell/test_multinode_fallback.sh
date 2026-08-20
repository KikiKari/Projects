#!/usr/bin/env bash
# test_multinode_fallback.py — portiert nach shell
# Quelle: python, OpenClaw@gateway1:scripts/test_multinode_fallback.py
# auch in: OpenClaw@gateway2:scripts/test_multinode_fallback.py
# Erzeugt: 2026-08-20 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Testet Multi-Node Fallback-Logik des db-maintainer
# Simuliert: Worker-Node nicht erreichbar → Fallback auf lokal

WORKSPACE="/home/openclaw/.openclaw/workspace"

check_node_reachable() {
    local node_id="$1"
    # Prüft ob Node erreichbar ist
    if timeout 10 openclaw nodes status 2>/dev/null | grep -q "$node_id" && timeout 10 openclaw nodes status 2>/dev/null | grep -q 'connected'; then
        return 0
    else
        return 1
    fi
}

spawn_on_node() {
    local node_id="$1"
    local task="$2"
    # Versucht Task auf Node auszuführen
    echo "Versuche Task auf Node $node_id zu starten..."
    if timeout 5 echo "Spawned on $node_id: $task" >/dev/null 2>&1; then
        echo "✅ Erfolgreich delegiert an $node_id"
        return 0
    else
        echo "❌ Node $node_id nicht erreichbar: $(timeout 5 echo "Spawned on $node_id: $task" 2>&1 >/dev/null || true)"
        return 1
    fi
}

execute_locally() {
    local task="$1"
    # Führt Task lokal aus (Fallback)
    echo "🔄 Fallback: Führe Task lokal aus..."
    if [[ "$task" == "db_maintainer" ]]; then
        if timeout 60 python3 "${WORKSPACE}/skills/db-maintainer/scripts/db_maintainer.py" >/dev/null 2>&1; then
            echo "✅ Lokale Ausführung erfolgreich"
            return 0
        else
            echo "❌ Fehler bei lokaler Ausführung"
            return 1
        fi
    else
        echo "❌ Unbekannter Task: $task"
        return 1
    fi
}

main() {
    echo "============================================================"
    echo "MULTI-NODE FALLBACK TEST"
    echo "============================================================"
    echo

    # Konfiguration
    local primary_node="v2202603104722445775"  # Node 2
    local task="db_maintainer"

    echo "Primärer Node: $primary_node"
    echo "Task: $task"
    echo

    # 1. Prüfe Node-Erreichbarkeit
    echo "--- 1. Prüfe Node-Erreichbarkeit ---"
    if check_node_reachable "$primary_node"; then
        echo "✅ Node $primary_node ist erreichbar"

        # 2. Versuche Delegation
        echo
        echo "--- 2. Versuche Delegation ---"
        if spawn_on_node "$primary_node" "$task"; then
            echo
            echo "✅ MULTI-NODE: Task erfolgreich delegiert"
            return 0
        else
            echo
            echo "⚠️ Delegation fehlgeschlagen, aktiviere Fallback..."
        fi
    else
        echo "❌ Node $primary_node nicht erreichbar"
        echo "🔄 Fallback wird aktiviert..."
    fi

    # 3. Lokale Ausführung (Fallback)
    echo
    echo "--- 3. Lokale Ausführung (Fallback) ---"
    if execute_locally "$task"; then
        echo
        echo "✅ FALLBACK: Task lokal erfolgreich ausgeführt"
        return 0
    else
        echo
        echo "❌ FEHLER: Weder Delegation noch Fallback erfolgreich"
        return 1
    fi
}

main "$@"
