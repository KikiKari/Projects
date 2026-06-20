#!/usr/bin/env python3
"""
Script Abstractions Manager - Multi-Node Edition

Portiert OpenClaw-Scripts automatisch in Zielsprachen und verwaltet
den Verarbeitungsstatus über ein JSON-State-File. Läuft per Cron (alle 6h).

Verwendung:
    python3 ABSTRACTIONS_MANAGER.py

Konfiguration:
    Alle Pfade und Einstellungen werden über Umgebungsvariablen aus der
    Der Workspace-Pfad ist hardcoded: /home/openclaw/.openclaw/workspace
"""

import os
import sys
import json
import logging
import subprocess
import tempfile
from pathlib import Path
from datetime import datetime
from typing import Dict, List, Optional
from logging.handlers import RotatingFileHandler

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

WORKSPACE: Path = Path("/home/openclaw/.openclaw/workspace")
ABSTRACTIONS_REPO: Path = WORKSPACE / "git" / "Abstraktionen"
LOG_DIR: Path = WORKSPACE / "logs" / "abstractions-manager"
STATE_FILE: Path = WORKSPACE / "db" / "abstractions_state.json"

NODES: Dict[str, Dict] = {
    "node1": {"always_available": True,  "capacity": "medium", "priority": 2},
    "node2": {"always_available": True,  "capacity": "medium", "priority": 3},
    "node3": {"always_available": False, "capacity": "medium", "priority": 4},
    "node5": {"always_available": False, "capacity": "low",    "priority": 5,
               "device": "Redmi Note 11S", "condition": "mobile_internet"},
    "node7": {"always_available": True,  "capacity": "high",   "priority": 1},
}

AVAILABLE_MODELS: List[str] = [
    "openrouter/moonshotai/kimi-k2.5",
    "openrouter/openai/gpt-4o",
    "openrouter/anthropic/claude-3-5-sonnet-20241022",
    "openrouter/google/gemini-2.0-flash-001",
    "openrouter/nvidia/llama-3.3-nemotron-super-49b-v1",
    "openrouter/qwen/qwen-2.5-coder-32b-instruct",
]

TARGET_LANGUAGES: Dict[str, Dict[str, str]] = {
    "perl5": {
        "ext": ".pl",
        "shebang": "#!/usr/bin/env perl",
        "header": "use strict;\nuse warnings;\n",
        "main_block": (
            "sub main {{\n"
            "    # TODO: Implementiere {source_lang} Funktionalität in Perl 5\n"
            "}}\n\n"
            "main();\n"
        ),
    },
    "perl6": {
        "ext": ".raku",
        "shebang": "#!/usr/bin/env raku",
        "header": "use v6;\n",
        "main_block": (
            "sub MAIN() {{\n"
            "    # TODO: Implementiere {source_lang} Funktionalität in Raku\n"
            "}}\n"
        ),
    },
    "javascript": {
        "ext": ".js",
        "shebang": "#!/usr/bin/env node",
        "header": "'use strict';\n",
        "main_block": (
            "function main() {{\n"
            "    // TODO: Implementiere {source_lang} Funktionalität in JavaScript\n"
            "}}\n\n"
            "main();\n"
        ),
    },
    "python": {
        "ext": ".py",
        "shebang": "#!/usr/bin/env python3",
        "header": "",
        "main_block": (
            "def main():\n"
            "    # TODO: Implementiere {source_lang} Funktionalität in Python\n"
            "    pass\n\n\n"
            "if __name__ == '__main__':\n"
            "    main()\n"
        ),
    },
    "shell": {
        "ext": ".sh",
        "shebang": "#!/bin/bash",
        "header": "set -euo pipefail\n",
        "main_block": (
            "main() {{\n"
            "    # TODO: Implementiere {source_lang} Funktionalität in Bash\n"
            "}}\n\n"
            "main \"$@\"\n"
        ),
    },
    "powershell": {
        "ext": ".ps1",
        "shebang": "#!/usr/bin/env pwsh",
        "header": "#Requires -Version 7\n",
        "main_block": (
            "function Main {{\n"
            "    # TODO: Implementiere {source_lang} Funktionalität in PowerShell\n"
            "}}\n\n"
            "Main\n"
        ),
    },
    "tcl": {
        "ext": ".tcl",
        "shebang": "#!/usr/bin/env tclsh",
        "header": "package require Tcl 8.6\n",
        "main_block": (
            "proc main {{}} {{\n"
            "    # TODO: Implementiere {source_lang} Funktionalität in Tcl\n"
            "}}\n\n"
            "main\n"
        ),
    },
    "ruby": {
        "ext": ".rb",
        "shebang": "#!/usr/bin/env ruby",
        "header": "# frozen_string_literal: true\nrequire 'json'\nrequire 'fileutils'\n",
        "main_block": (
            "def main\n"
            "  # TODO: Implementiere {source_lang} Funktionalität in Ruby\n"
            "end\n\n"
            "main if __FILE__ == $PROGRAM_NAME\n"
        ),
    },
    "lua": {
        "ext": ".lua",
        "shebang": "#!/usr/bin/env lua",
        "header": "",
        "main_block": (
            "local function main()\n"
            "    -- TODO: Implementiere {source_lang} Funktionalität in Lua\n"
            "end\n\n"
            "main()\n"
        ),
    },
    "go": {
        "ext": ".go",
        "shebang": "// +build ignore",
        "header": "package main\n\nimport \"fmt\"\n",
        "main_block": (
            "func main() {{\n"
            "    // TODO: Implementiere {source_lang} Funktionalität in Go\n"
            "    _ = fmt.Println\n"
            "}}\n"
        ),
    },
}

# ---------------------------------------------------------------------------
# Logging-Setup (einmalig konfiguriert, nicht pro Aufruf geöffnet)
# ---------------------------------------------------------------------------

def _setup_logger() -> logging.Logger:
    """
    Konfiguriert den zentralen Logger mit RotatingFileHandler und Console-Handler.

    Returns:
        logging.Logger: Fertig konfigurierter Logger für das gesamte Modul.
    """
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    log_level_name = os.environ.get("ABSTRACTIONS_LOG_LEVEL", "INFO").upper()
    log_level = getattr(logging, log_level_name, logging.INFO)

    logger = logging.getLogger("abstractions_manager")
    logger.setLevel(log_level)

    if logger.handlers:
        return logger  # Bereits konfiguriert, Doppel-Handler verhindern

    formatter = logging.Formatter(
        fmt="%(asctime)s | %(levelname)-8s | %(funcName)s:%(lineno)d | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    log_file = LOG_DIR / f"{datetime.now().strftime('%Y-%m-%d')}.log"
    file_handler = RotatingFileHandler(
        log_file,
        maxBytes=10 * 1024 * 1024,  # 10 MB
        backupCount=7,
        encoding="utf-8",
    )
    file_handler.setFormatter(formatter)

    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)

    logger.addHandler(file_handler)
    logger.addHandler(console_handler)

    return logger


logger = _setup_logger()

# ---------------------------------------------------------------------------
# State-Management
# ---------------------------------------------------------------------------

def load_state() -> Dict:
    """
    Lädt den Verarbeitungsstatus aus dem JSON-State-File.

    Gibt einen leeren Standardzustand zurück wenn die Datei nicht existiert
    oder nicht geparst werden kann. Parse-Fehler werden geloggt.

    Returns:
        Dict: State-Dictionary mit den Schlüsseln 'processed', 'queue',
              'current_priority' und 'stats'.
    """
    default_state: Dict = {
        "processed": {},
        "queue": [],
        "current_priority": "high",
        "stats": {"total_scripts": 0, "abstractions_created": 0},
    }

    if not STATE_FILE.exists():
        return default_state

    try:
        with open(STATE_FILE, "r", encoding="utf-8") as fh:
            return json.load(fh)
    except json.JSONDecodeError as exc:
        logger.error("State-File konnte nicht geparst werden (%s): %s", STATE_FILE, exc)
    except OSError as exc:
        logger.error("State-File konnte nicht gelesen werden (%s): %s", STATE_FILE, exc)

    return default_state


def save_state(state: Dict) -> None:
    """
    Speichert den State atomar via temporärer Datei und os.replace().

    Schreibt zuerst in eine .tmp-Datei im selben Verzeichnis und ersetzt
    die Zieldatei atomar, sodass kein halbgeschriebener Zustand entsteht.

    Args:
        state: Das zu speichernde State-Dictionary.
    """
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)

    try:
        fd, tmp_path = tempfile.mkstemp(
            dir=STATE_FILE.parent,
            prefix=".abstractions_state_",
            suffix=".tmp",
        )
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(state, fh, indent=2, ensure_ascii=False)

        os.replace(tmp_path, STATE_FILE)
        logger.debug("State atomar gespeichert: %s", STATE_FILE)

    except OSError as exc:
        logger.error("State konnte nicht gespeichert werden: %s", exc)
        try:
            os.unlink(tmp_path)
        except OSError:
            pass

# ---------------------------------------------------------------------------
# Node-Management
# ---------------------------------------------------------------------------

def check_node_status(node_id: str) -> bool:
    """
    Prüft ob ein Node via 'openclaw nodes status' erreichbar ist.

    Bei Timeout oder Fehler fällt die Funktion auf den in NODES konfigurierten
    always_available-Wert zurück, anstatt einen Fehler zu verbergen.

    Args:
        node_id: Der Node-Bezeichner (z.B. 'node1', 'node7').

    Returns:
        bool: True wenn der Node als online gilt, False sonst.
    """
    try:
        result = subprocess.run(
            ["openclaw", "nodes", "status", node_id],
            capture_output=True,
            text=True,
            timeout=5,
        )
        stdout_lower = result.stdout.lower()
        return result.returncode == 0 and (
            "online" in stdout_lower or "active" in stdout_lower
        )
    except subprocess.TimeoutExpired:
        logger.warning("Timeout beim Status-Check von %s — verwende always_available", node_id)
    except FileNotFoundError:
        logger.warning("'openclaw'-Binary nicht gefunden — verwende always_available für %s", node_id)
    except OSError as exc:
        logger.warning("OSError beim Status-Check von %s: %s — verwende always_available", node_id, exc)

    return NODES.get(node_id, {}).get("always_available", False)


def get_job_weight(script_size: int, target_langs_count: int) -> str:
    """
    Bewertet das Gewicht eines Jobs anhand Script-Größe und Anzahl Zielsprachen.

    Args:
        script_size:        Dateigröße des Quell-Scripts in Bytes.
        target_langs_count: Anzahl der Zielsprachen für diesen Durchlauf.

    Returns:
        str: 'heavy', 'medium' oder 'light'.
    """
    total_work = script_size * target_langs_count
    if total_work > 50_000:
        return "heavy"
    if total_work > 10_000:
        return "medium"
    return "light"


def get_node_by_priority(job_weight: str = "medium") -> str:
    """
    Wählt den optimalen Node basierend auf Job-Gewicht und Node-Priorität.

    Durchläuft die bevorzugte Reihenfolge für das gegebene Job-Gewicht und
    gibt den ersten erreichbaren Node zurück. Fällt auf 'node1' zurück.

    Args:
        job_weight: 'heavy', 'medium' oder 'light'.

    Returns:
        str: Node-ID des ausgewählten Nodes.
    """
    weight_to_preference: Dict[str, List[str]] = {
        "heavy":  ["node7", "node2", "node1"],
        "medium": ["node2", "node1", "node7"],
        "light":  ["node5", "node1", "node2"],
    }
    preferred_order = weight_to_preference.get(job_weight, ["node1", "node2"])

    for node_id in preferred_order:
        if node_id not in NODES:
            continue
        node_cfg = NODES[node_id]
        if not node_cfg.get("always_available", False) and job_weight != "light":
            continue
        if check_node_status(node_id):
            logger.debug("Node %s ausgewählt für %s-Job", node_id, job_weight)
            return node_id

    logger.warning("Kein passender Node gefunden für Gewicht '%s' — Fallback node1", job_weight)
    return "node1"

# ---------------------------------------------------------------------------
# Script-Verarbeitung
# ---------------------------------------------------------------------------

def find_scripts_in_dir(
    directory: Path,
    exclude_patterns: Optional[List[str]] = None,
) -> List[Path]:
    """
    Sucht rekursiv nach Script-Dateien in einem Verzeichnis.

    Args:
        directory:        Startverzeichnis der Suche.
        exclude_patterns: Pfad-Teilstrings, die zu einem Ausschluss führen.

    Returns:
        List[Path]: Gefundene Script-Dateien (py, js, sh, pl, rb).
    """
    if exclude_patterns is None:
        exclude_patterns = ["node_modules", ".git", "__pycache__", "dist", "build"]

    scripts: List[Path] = []
    if not directory.exists():
        logger.debug("Verzeichnis existiert nicht: %s", directory)
        return scripts

    for glob_pattern in ("*.py", "*.js", "*.sh", "*.pl", "*.rb"):
        for script_path in directory.rglob(glob_pattern):
            if not any(pattern in str(script_path) for pattern in exclude_patterns):
                scripts.append(script_path)

    return scripts


def _build_stub_content(
    script_path: Path,
    target_lang: str,
    source_lang: str,
    template: Dict[str, str],
) -> str:
    """
    Erstellt den Stub-Inhalt für eine neue Portierungs-Datei.

    Der Stub enthält Shebang, Header, einen Kommentarblock mit Referenz auf
    das Original sowie einen sprachspezifischen main()-Block.

    Args:
        script_path: Pfad zur Original-Datei.
        target_lang: Name der Zielsprache.
        source_lang: Name der Quellsprache (für Kommentare).
        template:    Eintrags-Dict aus TARGET_LANGUAGES für target_lang.

    Returns:
        str: Vollständiger Stub-Quelltext.
    """
    today = datetime.now().strftime("%Y-%m-%d")

    try:
        with open(script_path, "r", encoding="utf-8", errors="replace") as fh:
            original_lines = fh.readlines()[:15]
    except OSError as exc:
        logger.warning("Originaldatei konnte nicht gelesen werden: %s", exc)
        original_lines = []

    # Kommentarzeichen ist für alle unterstützten Sprachen '#' außer Go und JS
    comment_char = "//" if target_lang in ("go", "javascript") else "#"
    original_preview = "".join(
        f"{comment_char} {line}" for line in original_lines
    )

    main_block = template["main_block"].format(source_lang=source_lang)

    return (
        f"{template['shebang']}\n"
        f"{comment_char} {script_path.stem} - {target_lang.title()} Version\n"
        f"{comment_char} Portiert von {source_lang}\n"
        f"{comment_char} Original: {script_path}\n"
        f"{comment_char} Erstellt: {today}\n"
        f"\n"
        f"{template['header']}\n"
        f"{comment_char} Original-Code-Referenz:\n"
        f"{original_preview}\n"
        f"{main_block}"
    )


def create_abstraction(script_path: Path, target_lang: str) -> bool:
    """
    Erstellt einen sprachspezifischen Stub für ein Script in der Zielsprache.

    Überspringt die Erstellung wenn die Ausgabedatei bereits existiert.
    Der generierte Stub enthält den korrekten Einstiegspunkt für jede
    Zielsprache (kein Python-Syntax für Perl, Tcl, Shell etc.).

    Args:
        script_path: Pfad zur Original-Script-Datei.
        target_lang: Schlüssel aus TARGET_LANGUAGES (z.B. 'perl5', 'go').

    Returns:
        bool: True wenn eine neue Datei erstellt wurde, False bei Überspringen
              oder Fehler.
    """
    if target_lang not in TARGET_LANGUAGES:
        logger.error("Unbekannte Zielsprache: %s", target_lang)
        return False

    template = TARGET_LANGUAGES[target_lang]
    ext_map = {"py": "Python", "js": "JavaScript", "sh": "Shell", "pl": "Perl", "rb": "Ruby"}
    source_lang = ext_map.get(script_path.suffix.lstrip("."), script_path.suffix.lstrip(".").title())

    target_dir = ABSTRACTIONS_REPO / target_lang
    try:
        target_dir.mkdir(parents=True, exist_ok=True)
    except OSError as exc:
        logger.error("Zielverzeichnis konnte nicht erstellt werden (%s): %s", target_dir, exc)
        return False

    target_file = target_dir / f"{script_path.stem}{template['ext']}"
    if target_file.exists():
        logger.debug("Bereits vorhanden, übersprungen: %s", target_file)
        return False

    content = _build_stub_content(script_path, target_lang, source_lang, template)

    try:
        # Atomisches Schreiben via temporärer Datei
        fd, tmp_path = tempfile.mkstemp(dir=target_dir, prefix=".stub_", suffix=template["ext"])
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            fh.write(content)
        os.replace(tmp_path, target_file)
        logger.info("Erstellt: %s", target_file)
        return True
    except OSError as exc:
        logger.error("Stub konnte nicht geschrieben werden (%s): %s", target_file, exc)
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        return False


def process_on_node(node_id: str, scripts: List[Path], target_langs: List[str]) -> int:
    """
    Verarbeitet eine Liste von Scripts auf einem bestimmten Node.

    Für node1 (lokal) wird direkt verarbeitet. Für andere Nodes ist der
    Remote-Dispatch noch nicht implementiert und fällt auf lokale Verarbeitung
    mit Node-Logging zurück.

    Args:
        node_id:      Ziel-Node-ID.
        scripts:      Liste der zu portierenden Script-Pfade.
        target_langs: Liste der Zielsprachen-Schlüssel.

    Returns:
        int: Anzahl neu erstellter Abstraktionen.
    """
    created = 0

    if node_id == "node1":
        for script_path in scripts:
            for lang in target_langs:
                if create_abstraction(script_path, lang):
                    created += 1
    else:
        logger.info("Dispatching %d Jobs an %s (lokaler Fallback aktiv)", len(scripts), node_id)
        # TODO: Remote-Dispatch implementieren wenn Node-Infrastruktur bereit ist
        for script_path in scripts:
            for lang in target_langs:
                if create_abstraction(script_path, lang):
                    created += 1
                    logger.debug("Verarbeitet auf %s: %s → %s", node_id, script_path.name, lang)

    return created

# ---------------------------------------------------------------------------
# Prioritäts-Verarbeitung
# ---------------------------------------------------------------------------

def process_priority_high() -> int:
    """
    Verarbeitet die Top-5-Skills mit hoher Priorität.

    Wählt für jeden Job den optimalen Node und portiert in die Sprachen
    perl5, javascript, python, shell, tcl (max. 10 Scripts pro Skill).

    Returns:
        int: Gesamtzahl neu erstellter Abstraktionen.
    """
    target_dirs = [
        ("skill-creator",   WORKSPACE / "skills" / "skill-creator"   / "scripts"),
        ("json-utils",      WORKSPACE / "skills" / "json-utils"       / "scripts"),
        ("scripting-utils", WORKSPACE / "skills" / "scripting-utils"  / "scripts"),
        ("model-usage",     WORKSPACE / "skills" / "model-usage"      / "scripts"),
        ("tiktok-live",     WORKSPACE / "skills" / "tiktok-live"      / "scripts"),
    ]
    target_langs = ["perl5", "javascript", "python", "shell", "tcl"]
    created = 0
    exclude = ["node_modules", ".git", "test", "tests"]

    for skill_name, scripts_dir in target_dirs:
        scripts = find_scripts_in_dir(scripts_dir, exclude_patterns=exclude)
        logger.info("%s: %d Scripts gefunden", skill_name, len(scripts))

        for script_path in scripts[:10]:
            script_size = script_path.stat().st_size if script_path.exists() else 0
            job_weight = get_job_weight(script_size, len(target_langs))
            selected_node = get_node_by_priority(job_weight)
            logger.info("Verarbeite %s (%s) auf %s", script_path.name, job_weight, selected_node)
            created += process_on_node(selected_node, [script_path], target_langs)

    return created


def process_priority_medium() -> int:
    """
    Verarbeitet Workspace-Scripts und Hilfs-Skills mit mittlerer Priorität.

    Portiert in perl5, javascript, powershell, python (max. 10 Scripts pro Quelle).

    Returns:
        int: Gesamtzahl neu erstellter Abstraktionen.
    """
    target_dirs = [
        ("workspace-scripts", WORKSPACE / "scripts"),
        ("db-maintainer",     WORKSPACE / "skills" / "db-maintainer"  / "scripts"),
        ("log-collector",     WORKSPACE / "skills" / "log-collector"   / "scripts"),
    ]
    target_langs = ["perl5", "javascript", "powershell", "python"]
    created = 0
    exclude = ["node_modules", ".git"]

    for dir_name, scripts_dir in target_dirs:
        scripts = find_scripts_in_dir(scripts_dir, exclude_patterns=exclude)

        for script_path in scripts[:10]:
            script_size = script_path.stat().st_size if script_path.exists() else 0
            job_weight = get_job_weight(script_size, len(target_langs))
            # Mittlere Priorität: schwere Jobs auf 'medium' herunterstufen
            effective_weight = "medium" if job_weight == "heavy" else job_weight
            selected_node = get_node_by_priority(effective_weight)
            logger.info("Verarbeite %s (%s) auf %s", script_path.name, job_weight, selected_node)
            created += process_on_node(selected_node, [script_path], target_langs)

    return created

# ---------------------------------------------------------------------------
# Git-Integration
# ---------------------------------------------------------------------------

def git_commit(message: str) -> None:
    """
    Fügt alle neuen Dateien im Abstractions-Repo hinzu und erstellt einen Commit.

    Verwendet 'git -C <repo>' anstatt os.chdir(), um den globalen Prozess-CWD
    nicht zu verändern. Fehler werden geloggt statt still verworfen.

    Args:
        message: Commit-Nachricht.
    """
    repo_str = str(ABSTRACTIONS_REPO)
    try:
        subprocess.run(
            ["git", "-C", repo_str, "add", "."],
            check=True,
            capture_output=True,
            text=True,
        )
        subprocess.run(
            ["git", "-C", repo_str, "commit", "-m", message],
            check=True,
            capture_output=True,
            text=True,
        )
        logger.info("Git commit erfolgreich: %s", message)
    except subprocess.CalledProcessError as exc:
        logger.warning(
            "Git-Befehl fehlgeschlagen (Exit %d): %s",
            exc.returncode,
            exc.stderr.strip() if exc.stderr else "(keine Ausgabe)",
        )
    except FileNotFoundError:
        logger.error("'git'-Binary nicht gefunden — Commit übersprungen")
    except OSError as exc:
        logger.error("OSError beim Git-Commit: %s", exc)

# ---------------------------------------------------------------------------
# Status-Report
# ---------------------------------------------------------------------------

def create_status_report(state: Dict) -> None:
    """
    Erstellt eine STATUS.md im Abstractions-Repo mit aktuellem Stand.

    Zählt vorhandene Dateien pro Sprach-Unterverzeichnis und listet
    Node-Konfiguration sowie verfügbare Modelle auf.

    Args:
        state: Aktuelles State-Dictionary.
    """
    if not ABSTRACTIONS_REPO.exists():
        logger.warning("Abstractions-Repo existiert nicht: %s", ABSTRACTIONS_REPO)
        return

    lang_counts: Dict[str, int] = {}
    for lang_dir in ABSTRACTIONS_REPO.iterdir():
        if lang_dir.is_dir() and lang_dir.name in TARGET_LANGUAGES:
            lang_counts[lang_dir.name] = sum(1 for f in lang_dir.iterdir() if f.is_file())

    report_file = ABSTRACTIONS_REPO / "STATUS.md"
    try:
        with open(report_file, "w", encoding="utf-8") as fh:
            fh.write("# Script Abstractions - Status Report\n\n")
            fh.write(f"**Letzte Aktualisierung:** {datetime.now().strftime('%Y-%m-%d %H:%M')}\n\n")
            fh.write(f"- Aktuelle Priorität: {state.get('current_priority', 'high')}\n")
            fh.write(f"- Verarbeitete Scripts: {len(state.get('processed', {}))}\n")
            fh.write(f"- Abstraktionen gesamt: {state.get('stats', {}).get('abstractions_created', 0)}\n\n")

            fh.write("## Abstraktionen pro Sprache\n\n")
            for lang, count in sorted(lang_counts.items()):
                fh.write(f"- {lang}: {count}\n")

            fh.write("\n## Verfügbare Modelle\n\n")
            for model in AVAILABLE_MODELS[:3]:
                fh.write(f"- `{model}`\n")
            fh.write(f"- ... und {len(AVAILABLE_MODELS) - 3} weitere\n")

            fh.write("\n## Multi-Node Support\n\n")
            fh.write("| Node | Verfügbarkeit | Kapazität | Priorität | Gerät |\n")
            fh.write("|------|---------------|-----------|-----------|-------|\n")
            for node_id, cfg in NODES.items():
                avail = "✅ Immer" if cfg.get("always_available") else "📱 Bedingt"
                device = cfg.get("device", "Server")
                fh.write(
                    f"| {node_id} | {avail} | {cfg.get('capacity', 'unknown')} "
                    f"| {cfg.get('priority', '-')} | {device} |\n"
                )

            fh.write("\n### Job-Verteilung\n\n")
            fh.write("- **Heavy Jobs** (>50 KB × Sprachen) → Node 7 (Docker, hohe Ressourcen)\n")
            fh.write("- **Medium Jobs** → Node 2 (Stable), Node 1 (Primary)\n")
            fh.write("- **Light Jobs** → Node 5 (Redmi Note 11S, wenn verfügbar)\n")

        logger.info("Status-Report erstellt: %s", report_file)

    except OSError as exc:
        logger.error("Status-Report konnte nicht geschrieben werden: %s", exc)

# ---------------------------------------------------------------------------
# Einstiegspunkt
# ---------------------------------------------------------------------------

def main() -> None:
    """
    Hauptroutine: Lädt State, verarbeitet eine Prioritätsstufe, speichert State.

    Wechselt zyklisch zwischen 'high'- und 'medium'-Priorität. Erstellt nach
    jedem erfolgreichen Durchlauf einen Git-Commit und aktualisiert STATUS.md.
    """
    logger.info("Script Abstractions Manager (Multi-Node) gestartet")

    state = load_state()
    logger.info("State geladen: %d bereits verarbeitet", len(state.get("processed", {})))

    current_priority = state.get("current_priority", "high")
    created = 0

    if current_priority == "high":
        logger.info("Verarbeite HIGH-Priorität: Top 5 Skills")
        created = process_priority_high()
        if created > 0:
            git_commit(f"High priority: {created} abstractions")
        state["current_priority"] = "medium"

    elif current_priority == "medium":
        logger.info("Verarbeite MEDIUM-Priorität: Workspace Scripts")
        created = process_priority_medium()
        if created > 0:
            git_commit(f"Medium priority: {created} abstractions")
        state["current_priority"] = "high"  # Zyklus zurücksetzen

    state["stats"]["last_run"] = datetime.now().isoformat()
    state["stats"]["abstractions_created"] = sum(
        sum(1 for f in (ABSTRACTIONS_REPO / lang).iterdir() if f.is_file())
        for lang in TARGET_LANGUAGES
        if (ABSTRACTIONS_REPO / lang).exists()
    )

    save_state(state)
    create_status_report(state)

    logger.info("Abgeschlossen. %d neue Abstraktionen erstellt.", created)


if __name__ == "__main__":
    main()
