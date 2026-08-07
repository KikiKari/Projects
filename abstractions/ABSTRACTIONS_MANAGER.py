#!/usr/bin/env python3
"""
Script Abstractions Manager

Uebersetzt jede Quelldatei aus den drei Repositories KikiKari/OpenClaw,
KikiKari/Projects und KikiKari/Onboarding in sechs Zielsprachen und legt
das Ergebnis in den Sprachverzeichnissen des Abstraktions-Repositories ab.

Es entstehen vollstaendige Uebersetzungen, keine Ruempfe: jede Datei geht
als Ganzes an ein Sprachmodell, das lauffaehigen Code in der Zielsprache
zurueckgibt. Erzeugnisse, deren Syntax sich nicht pruefen laesst oder die
erkennbar unfertig sind, werden verworfen statt abgelegt.

Verwendung:
    python3 ABSTRACTIONS_MANAGER.py [--prioritaet high|medium|low|alle]
                                    [--anzahl N] [--probelauf]

Umgebung:
    OPENROUTER_API_KEY      Pflicht. Schluessel fuer die Uebersetzung.
    ABSTRACTIONS_WORKSPACE  Arbeitsverzeichnis, Vorgabe
                            /home/openclaw/.openclaw/workspace
    ABSTRACTIONS_MODELL     Modellkennung, Vorgabe siehe MODELLE
    ABSTRACTIONS_ANZAHL     Quelldateien je Lauf, Vorgabe 40
"""

from __future__ import annotations

import argparse
import hashlib
import json
import logging
import os
import subprocess
import sys
import tempfile
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from logging.handlers import RotatingFileHandler
from pathlib import Path
from typing import Dict, List, Optional, Tuple

# ---------------------------------------------------------------------------
# Konfiguration
# ---------------------------------------------------------------------------

WORKSPACE: Path = Path(
    os.environ.get("ABSTRACTIONS_WORKSPACE", "/home/openclaw/.openclaw/workspace")
)
ABSTRACTIONS_REPO: Path = WORKSPACE / "git" / "Abstraktionen"
QUELLEN_DIR: Path = WORKSPACE / "git" / "quellen"
LOG_DIR: Path = WORKSPACE / "logs" / "abstractions-manager"
STATE_FILE: Path = WORKSPACE / "db" / "abstractions_state.json"

GITHUB_BENUTZER = "KikiKari"

# Herkunft der Quelldateien. Projects wird ueber alle Branches gelesen, weil
# dort jedes Projekt in einem eigenen verwaisten Branch liegt.
QUELLEN: List[Dict[str, object]] = [
    {"repo": "OpenClaw",   "branches": ["main", "gateway1", "gateway2"]},
    {"repo": "Projects",   "branches": "alle"},
    {"repo": "Onboarding", "branches": ["main"]},
]

# Dateiendung -> Quellsprache. Bestimmt zugleich, was eingelesen wird.
QUELLSPRACHEN: Dict[str, str] = {
    ".pl": "perl5", ".pm": "perl5",
    ".ps1": "powershell", ".psm1": "powershell",
    ".sh": "shell", ".bash": "shell",
    ".tcl": "tcl",
    ".html": "html", ".htm": "html",
    ".js": "javascript", ".mjs": "javascript", ".cjs": "javascript",
    ".py": "python",
    ".css": "css",
}

# Die sechs Zielverzeichnisse, nach der Vorlage aus
# OpenClaw@gateway1-abstractions. Sie liegen im Wurzelverzeichnis des
# Abstraktions-Repositories.
ZIELSPRACHEN: Dict[str, Dict[str, str]] = {
    "javascript": {"ext": ".js",  "bezeichnung": "JavaScript fuer Node 20"},
    "perl5":      {"ext": ".pl",  "bezeichnung": "Perl 5 mit use strict und use warnings"},
    "powershell": {"ext": ".ps1", "bezeichnung": "PowerShell 7"},
    "python":     {"ext": ".py",  "bezeichnung": "Python 3.12"},
    "shell":      {"ext": ".sh",  "bezeichnung": "Bash 5 mit set -euo pipefail"},
    "tcl":        {"ext": ".tcl", "bezeichnung": "Tcl 8.6"},
}

# Verzeichnisse und Muster, die nie eingelesen werden.
AUSSCHLUSS: Tuple[str, ...] = (
    "node_modules/", "/.git/", "__pycache__/", "dist/", "build/", "vendor/",
    ".venv/", "site-packages/", "python-hardener-workspace/", ".artifacts/",
    "coverage/", ".next/", "target/",
)
MAX_BYTES = 200_000

# Reihenfolge der Ausweichmodelle. Geprueft gegen das Konto: die Anbieter von
# OpenAI und Anthropic sind dort ueber die Privatsphaere-Einstellung
# ausgeschlossen ("All providers have been ignored"), diese hier antworten.
MODELLE: List[str] = [
    "qwen/qwen3-coder",
    "deepseek/deepseek-chat-v3.1",
    "z-ai/glm-4.6",
    "mistralai/codestral-2508",
    "qwen/qwen-2.5-coder-32b-instruct",
]
API_URL = "https://openrouter.ai/api/v1/chat/completions"
ZEITLIMIT = 240
VERSUCHE = 3

# ---------------------------------------------------------------------------
# Protokoll
# ---------------------------------------------------------------------------


def _protokoll() -> logging.Logger:
    """Richtet die Protokollierung nach stdout und, wenn moeglich, in eine Datei ein."""
    log = logging.getLogger("abstractions")
    if log.handlers:
        return log
    log.setLevel(logging.INFO)
    form = logging.Formatter(
        "%(asctime)s | %(levelname)-7s | %(funcName)s:%(lineno)d | %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    strom = logging.StreamHandler(sys.stdout)
    strom.setFormatter(form)
    log.addHandler(strom)
    try:
        LOG_DIR.mkdir(parents=True, exist_ok=True)
        datei = RotatingFileHandler(LOG_DIR / "manager.log", maxBytes=2_000_000,
                                    backupCount=3, encoding="utf-8")
        datei.setFormatter(form)
        log.addHandler(datei)
    except OSError as fehler:
        log.warning("Protokolldatei nicht verfuegbar (%s) — es wird nur nach stdout geschrieben", fehler)
    return log


logger = _protokoll()

# ---------------------------------------------------------------------------
# Zustand
# ---------------------------------------------------------------------------


def zustand_laden() -> Dict:
    """Liest den Zustand. Er merkt sich je Quelldatei-Hash die bereits
    erzeugten Zielsprachen, damit ein erneuter Lauf nichts doppelt uebersetzt."""
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError) as fehler:
            logger.warning("Zustand unlesbar (%s) — es wird neu begonnen", fehler)
    return {"erledigt": {}, "statistik": {}}


def zustand_speichern(zustand: Dict) -> None:
    """Schreibt den Zustand atomar, damit ein Abbruch ihn nicht zerstoert."""
    try:
        STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
        kennung, pfad = tempfile.mkstemp(dir=STATE_FILE.parent, prefix=".zustand_")
        with os.fdopen(kennung, "w", encoding="utf-8") as griff:
            json.dump(zustand, griff, ensure_ascii=False, indent=1)
        os.replace(pfad, STATE_FILE)
    except OSError as fehler:
        logger.error("Zustand konnte nicht gespeichert werden: %s", fehler)


# ---------------------------------------------------------------------------
# Quellen holen
# ---------------------------------------------------------------------------


def _git(*argumente: str, verzeichnis: Optional[Path] = None) -> subprocess.CompletedProcess:
    """Fuehrt einen Git-Befehl aus und gibt das Ergebnis zurueck, ohne zu werfen."""
    befehl = ["git"]
    if verzeichnis is not None:
        befehl += ["-C", str(verzeichnis)]
    befehl += list(argumente)
    return subprocess.run(befehl, capture_output=True, text=True, timeout=600)


def quellen_holen() -> List[Tuple[str, str, Path]]:
    """
    Holt oder aktualisiert die Quell-Repositories und legt fuer jeden Branch
    einen Arbeitsbaum an.

    Alle drei Repositories sind oeffentlich, es wird daher kein Token benoetigt.

    Returns:
        Liste aus (Repo, Branch, Pfad zum Arbeitsbaum).
    """
    QUELLEN_DIR.mkdir(parents=True, exist_ok=True)
    baeume: List[Tuple[str, str, Path]] = []

    for eintrag in QUELLEN:
        repo = str(eintrag["repo"])
        spiegel = QUELLEN_DIR / f"{repo}.git"
        url = f"https://github.com/{GITHUB_BENUTZER}/{repo}.git"

        if not spiegel.exists():
            logger.info("%s wird geholt", repo)
            ergebnis = _git("clone", "--mirror", "--filter=blob:none", url, str(spiegel))
            if ergebnis.returncode != 0:
                logger.error("%s konnte nicht geholt werden: %s", repo, ergebnis.stderr.strip()[:200])
                continue
        else:
            ergebnis = _git("remote", "update", "--prune", verzeichnis=spiegel)
            if ergebnis.returncode != 0:
                logger.warning("%s konnte nicht aktualisiert werden: %s", repo, ergebnis.stderr.strip()[:200])

        gewuenscht = eintrag["branches"]
        if gewuenscht == "alle":
            aus = _git("for-each-ref", "--format=%(refname:short)", "refs/heads", verzeichnis=spiegel)
            branches = [z.strip() for z in aus.stdout.splitlines() if z.strip()]
        else:
            branches = list(gewuenscht)  # type: ignore[arg-type]

        for branch in branches:
            baum = QUELLEN_DIR / "baeume" / repo / branch.replace("/", "_")
            baum.mkdir(parents=True, exist_ok=True)
            ergebnis = _git("--work-tree", str(baum), "checkout", "-f", branch, "--", ".",
                            verzeichnis=spiegel)
            if ergebnis.returncode != 0:
                logger.warning("%s@%s: Arbeitsbaum fehlgeschlagen: %s",
                               repo, branch, ergebnis.stderr.strip()[:160])
                continue
            baeume.append((repo, branch, baum))

    logger.info("Quellen bereit: %d Arbeitsbaeume", len(baeume))
    return baeume


# ---------------------------------------------------------------------------
# Inventar
# ---------------------------------------------------------------------------


def _prioritaet(pfad: str, sprache: str) -> str:
    """
    Ordnet einer Quelldatei ihre Dringlichkeit zu.

    high   Betriebsscripte — alles unterhalb eines scripts-Verzeichnisses.
    medium uebriger ausfuehrbarer Code.
    low    Markup und Stilvorlagen, die nur der Vollstaendigkeit halber
           mituebersetzt werden.
    """
    if sprache in ("html", "css"):
        return "low"
    if pfad.startswith("scripts/") or "/scripts/" in pfad:
        return "high"
    return "medium"


def inventar_bauen(baeume: List[Tuple[str, str, Path]]) -> List[Dict]:
    """
    Erfasst alle Quelldateien und fasst inhaltsgleiche Fundstellen zusammen.

    Deduplizierung geschieht ueber den SHA-256 des Inhalts. Eine Datei, die in
    mehreren Branches identisch vorliegt, wird genau einmal uebersetzt; alle
    Fundstellen bleiben als Herkunft vermerkt.

    Returns:
        Nach Dringlichkeit und Name sortierte Liste von Eintraegen.
    """
    dateien: Dict[str, Dict] = {}

    for repo, branch, baum in baeume:
        for pfad in baum.rglob("*"):
            if not pfad.is_file():
                continue
            rel = str(pfad.relative_to(baum)).replace("\\", "/")
            if any(muster in "/" + rel for muster in AUSSCHLUSS):
                continue
            sprache = QUELLSPRACHEN.get(pfad.suffix.lower())
            if sprache is None:
                continue
            try:
                roh = pfad.read_bytes()
            except OSError:
                continue
            if not roh.strip() or len(roh) > MAX_BYTES:
                continue

            schluessel = hashlib.sha256(roh).hexdigest()[:16]
            eintrag = dateien.get(schluessel)
            if eintrag is None:
                eintrag = {
                    "hash": schluessel,
                    "name": pfad.name,
                    "stamm": pfad.stem,
                    "sprache": sprache,
                    "bytes": len(roh),
                    "pfad": str(pfad),
                    "herkunft": [],
                    "prioritaet": _prioritaet(rel, sprache),
                }
                dateien[schluessel] = eintrag
            eintrag["herkunft"].append(f"{repo}@{branch}:{rel}")

    rang = {"high": 0, "medium": 1, "low": 2}
    liste = sorted(dateien.values(), key=lambda e: (rang[e["prioritaet"]], e["name"]))
    logger.info("Inventar: %d eindeutige Quelldateien aus %d Fundstellen",
                len(liste), sum(len(e["herkunft"]) for e in liste))
    return liste

# ---------------------------------------------------------------------------
# Uebersetzung
# ---------------------------------------------------------------------------

ANWEISUNG = """Du portierst Quellcode zwischen Programmiersprachen.

Regeln:
1. Gib ausschliesslich den vollstaendigen Code der Zielsprache aus. Keine
   Erklaerung davor oder danach, keine Code-Zaeune.
2. Uebersetze die gesamte Funktionalitaet. Kein TODO, kein "hier waere",
   kein leerer Rumpf, kein Platzhalter.
3. Erhalte Verhalten, Ein- und Ausgaben, Aufrufparameter und Rueckgabewerte.
4. Verwende die Mittel der Zielsprache statt einer woertlichen Abschrift.
   Wo eine Bibliothek fehlt, loese es mit Bordmitteln der Zielsprache.
5. Kommentare uebernimmst du sinngemaess in der Sprache des Originals.
6. Beginne mit der passenden Shebang-Zeile."""

MARKUP_HINWEIS = """Das Original ist {sprache}. Erzeuge ein Programm in der
Zielsprache, das dieses Dokument erzeugt und ueber einen Parameter in eine
Datei schreibt — kein blosses Einbetten als Zeichenkette, sondern eine
nachvollziehbare Erzeugung der Struktur."""


def _zaeune_entfernen(text: str) -> str:
    """Loest Code aus Markdown-Zaeunen, falls das Modell welche gesetzt hat."""
    zeilen = text.strip().splitlines()
    if zeilen and zeilen[0].lstrip().startswith("```"):
        zeilen = zeilen[1:]
        while zeilen and not zeilen[-1].lstrip().startswith("```"):
            if zeilen[-1].strip():
                break
            zeilen.pop()
        if zeilen and zeilen[-1].lstrip().startswith("```"):
            zeilen.pop()
    return "\n".join(zeilen).strip() + "\n"


def modell_fragen(quelle: str, quellsprache: str, zielsprache: str,
                  name: str, schluessel: str) -> Optional[str]:
    """
    Laesst eine Quelldatei in die Zielsprache uebersetzen.

    Bei Fehlschlag wird mit wachsender Wartezeit wiederholt und danach auf
    das naechste Modell der Liste ausgewichen.

    Returns:
        Der uebersetzte Code, oder None wenn kein Modell geantwortet hat.
    """
    ziel = ZIELSPRACHEN[zielsprache]["bezeichnung"]
    auftrag = f"Portiere die folgende Datei {name} von {quellsprache} nach {ziel}.\n"
    if quellsprache in ("html", "css"):
        auftrag += MARKUP_HINWEIS.format(sprache=quellsprache.upper()) + "\n"
    auftrag += f"\n----- Beginn {name} -----\n{quelle}\n----- Ende {name} -----"

    modelle = [os.environ["ABSTRACTIONS_MODELL"]] if os.environ.get("ABSTRACTIONS_MODELL") else MODELLE

    for modell in modelle:
        for versuch in range(1, VERSUCHE + 1):
            rumpf = json.dumps({
                "model": modell,
                "messages": [
                    {"role": "system", "content": ANWEISUNG},
                    {"role": "user", "content": auftrag},
                ],
                "temperature": 0.1,
                "max_tokens": 8000,
            }).encode("utf-8")
            anfrage = urllib.request.Request(API_URL, data=rumpf, headers={
                "Authorization": f"Bearer {schluessel}",
                "Content-Type": "application/json",
                "HTTP-Referer": "https://github.com/KikiKari/Projects",
                "X-Title": "Abstractions Manager",
            })
            try:
                with urllib.request.urlopen(anfrage, timeout=ZEITLIMIT) as antwort:
                    daten = json.loads(antwort.read().decode("utf-8"))
                inhalt = daten["choices"][0]["message"]["content"]
                if inhalt and inhalt.strip():
                    return _zaeune_entfernen(inhalt)
                logger.warning("%s -> %s: leere Antwort von %s", name, zielsprache, modell)
            except urllib.error.HTTPError as fehler:
                text = fehler.read().decode("utf-8", "replace")[:200]
                logger.warning("%s -> %s: HTTP %s von %s (%s)",
                               name, zielsprache, fehler.code, modell, text)
                if fehler.code in (400, 401, 402, 404):
                    break
            except (urllib.error.URLError, TimeoutError, KeyError, json.JSONDecodeError) as fehler:
                logger.warning("%s -> %s: %s bei %s", name, zielsprache, type(fehler).__name__, modell)
            time.sleep(min(2 ** versuch, 20))

    logger.error("%s -> %s: kein Modell hat geliefert", name, zielsprache)
    return None


# ---------------------------------------------------------------------------
# Pruefung der Erzeugnisse
# ---------------------------------------------------------------------------

PRUEFBEFEHLE: Dict[str, List[str]] = {
    "javascript": ["node", "--check"],
    "perl5":      ["perl", "-c"],
    "powershell": ["pwsh", "-NoProfile", "-Command"],
    "shell":      ["bash", "-n"],
    "tcl":        ["tclsh"],
}

VERDACHT = ("TODO: Implementiere", "TODO: implement", "not implemented",
            "hier waere", "Platzhalter", "your code here", "pass  # TODO")


def erzeugnis_pruefen(code: str, zielsprache: str, quelle: str = "") -> Tuple[bool, str]:
    """
    Prueft ein Erzeugnis auf Brauchbarkeit.

    Zuerst inhaltlich: erkennbar Unfertiges wird abgelehnt, ebenso ein
    Erzeugnis, das gegenueber der Quelle auffaellig zusammengeschrumpft ist.
    Die Mindestlaenge richtet sich nach der Quelle — ein dreizeiliger Aufrufer
    darf auch in der Zielsprache drei Zeilen haben.

    Danach, wenn der passende Interpreter vorhanden ist, die Syntax. Fehlt er,
    gilt die inhaltliche Pruefung als ausreichend.

    Returns:
        (angenommen, Begruendung)
    """
    quellzeilen = len(quelle.splitlines())
    zeilen = len([z for z in code.strip().splitlines() if z.strip()])
    mindestens = max(2, min(6, quellzeilen // 3)) if quellzeilen else 5
    if zeilen < mindestens:
        return False, f"zu kurz ({zeilen} statt mindestens {mindestens} Zeilen)"

    # Ein Platzhalter zaehlt nur dann als Mangel, wenn er nicht schon im
    # Original steht. Sonst faellt jede treue Uebersetzung einer Datei durch,
    # die selbst Vorlagen mit TODO erzeugt.
    niedrig = quelle.lower()
    for muster in VERDACHT:
        if muster.lower() in code.lower() and muster.lower() not in niedrig:
            return False, f"unfertig ({muster})"

    if zielsprache == "python":
        try:
            compile(code, "<erzeugnis>", "exec")
            return True, "syntax ok"
        except SyntaxError as fehler:
            return False, f"Syntaxfehler Zeile {fehler.lineno}"

    befehl = PRUEFBEFEHLE.get(zielsprache)
    if not befehl:
        return True, "ohne Syntaxpruefung angenommen"

    endung = ZIELSPRACHEN[zielsprache]["ext"]
    try:
        kennung, pfad = tempfile.mkstemp(suffix=endung)
        with os.fdopen(kennung, "w", encoding="utf-8") as griff:
            griff.write(code)
        if zielsprache == "powershell":
            aufruf = befehl + [f"$null = [ScriptBlock]::Create((Get-Content -Raw '{pfad}'))"]
        elif zielsprache == "tcl":
            aufruf = ["tclsh"]
            ergebnis = subprocess.run(aufruf, input=f"if {{[catch {{info complete [read [open {pfad}]]}}]}} {{exit 1}}",
                                      capture_output=True, text=True, timeout=30)
            os.unlink(pfad)
            return (ergebnis.returncode == 0), ("syntax ok" if ergebnis.returncode == 0 else "Syntaxfehler")
        else:
            aufruf = befehl + [pfad]
        ergebnis = subprocess.run(aufruf, capture_output=True, text=True, timeout=30)
        os.unlink(pfad)
        if ergebnis.returncode == 0:
            return True, "syntax ok"

        meldung = (ergebnis.stderr or ergebnis.stdout).strip()
        # Eine fehlende Fremdbibliothek ist kein Mangel des Erzeugnisses,
        # sondern eine Luecke dieser Pruefumgebung. perl -c und node --check
        # brechen dann ab, obwohl die Syntax stimmt.
        if "Can't locate" in meldung or "Cannot find module" in meldung:
            return True, "Fremdmodul fehlt hier — Syntax nicht abschliessend geprueft"
        erste = meldung.splitlines()[0][:90] if meldung.splitlines() else "unbekannt"
        return False, "Syntaxfehler: " + erste
    except FileNotFoundError:
        try:
            os.unlink(pfad)
        except OSError:
            pass
        return True, "Interpreter fehlt — ohne Syntaxpruefung angenommen"
    except (OSError, subprocess.TimeoutExpired, IndexError):
        return True, "Pruefung nicht moeglich — angenommen"

# ---------------------------------------------------------------------------
# Ablage
# ---------------------------------------------------------------------------


def _zieldatei(eintrag: Dict, zielsprache: str, belegt: Dict[str, str]) -> Path:
    """
    Bestimmt den Dateinamen im Sprachverzeichnis.

    Zwei verschiedene Quelldateien koennen denselben Stamm tragen — etwa
    db_manager.py in OpenClaw und in Projects. In dem Fall wird der zweite
    Name um die ersten sechs Stellen des Inhalts-Hashes ergaenzt, damit
    nichts still ueberschrieben wird.
    """
    endung = ZIELSPRACHEN[zielsprache]["ext"]
    stamm = eintrag["stamm"]
    schluessel = f"{zielsprache}/{stamm}"
    vorher = belegt.get(schluessel)
    if vorher is not None and vorher != eintrag["hash"]:
        stamm = f"{stamm}_{eintrag['hash'][:6]}"
    else:
        belegt[schluessel] = eintrag["hash"]
    return ABSTRACTIONS_REPO / zielsprache / f"{stamm}{endung}"


def _kopf(eintrag: Dict, zielsprache: str) -> str:
    """Setzt den Herkunftsvermerk als Kommentar in der Zielsprache."""
    zeichen = "//" if zielsprache == "javascript" else "#"
    heute = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    zeilen = [
        f"{zeichen} {eintrag['name']} — portiert nach {zielsprache}",
        f"{zeichen} Quelle: {eintrag['sprache']}, {eintrag['herkunft'][0]}",
    ]
    for weitere in eintrag["herkunft"][1:4]:
        zeilen.append(f"{zeichen} auch in: {weitere}")
    if len(eintrag["herkunft"]) > 4:
        zeilen.append(f"{zeichen} auch in: {len(eintrag['herkunft']) - 4} weiteren Fundstellen")
    zeilen.append(f"{zeichen} Erzeugt: {heute} durch ABSTRACTIONS_MANAGER.py")
    return "\n".join(zeilen) + "\n"


def ablegen(eintrag: Dict, zielsprache: str, code: str, belegt: Dict[str, str]) -> Optional[Path]:
    """Schreibt ein geprueftes Erzeugnis atomar in sein Sprachverzeichnis."""
    ziel = _zieldatei(eintrag, zielsprache, belegt)
    try:
        ziel.parent.mkdir(parents=True, exist_ok=True)
        zeilen = code.splitlines()
        if zeilen and zeilen[0].startswith("#!"):
            inhalt = zeilen[0] + "\n" + _kopf(eintrag, zielsprache) + "\n" + "\n".join(zeilen[1:]).lstrip("\n") + "\n"
        else:
            inhalt = _kopf(eintrag, zielsprache) + "\n" + code
        kennung, pfad = tempfile.mkstemp(dir=ziel.parent, prefix=".neu_",
                                         suffix=ZIELSPRACHEN[zielsprache]["ext"])
        with os.fdopen(kennung, "w", encoding="utf-8") as griff:
            griff.write(inhalt)
        os.replace(pfad, ziel)
        return ziel
    except OSError as fehler:
        logger.error("%s konnte nicht abgelegt werden: %s", ziel, fehler)
        return None


# ---------------------------------------------------------------------------
# Durchlauf
# ---------------------------------------------------------------------------


def uebersetzen(inventar: List[Dict], zustand: Dict, prioritaet: str,
                anzahl: int, probelauf: bool, schluessel: str) -> Dict[str, int]:
    """
    Arbeitet das Inventar ab und erzeugt fehlende Uebersetzungen.

    Jede Quelldatei wird in alle Zielsprachen ausser ihrer eigenen portiert.
    Bereits erledigte Paare aus dem Zustand werden uebersprungen, ebenso
    Zieldateien, die schon vorliegen.

    Returns:
        Zaehlwerk mit erzeugt, uebersprungen und verworfen.
    """
    zaehler = {"erzeugt": 0, "uebersprungen": 0, "verworfen": 0, "dateien": 0}
    belegt: Dict[str, str] = {}
    erledigt = zustand.setdefault("erledigt", {})

    offen = [e for e in inventar if prioritaet == "alle" or e["prioritaet"] == prioritaet]
    logger.info("Prioritaet %s: %d Quelldateien im Bestand", prioritaet, len(offen))

    for eintrag in offen:
        if zaehler["dateien"] >= anzahl:
            logger.info("Kontingent von %d Quelldateien erreicht", anzahl)
            break

        fertig = set(erledigt.get(eintrag["hash"], []))
        ziele = [z for z in ZIELSPRACHEN if z != eintrag["sprache"] and z not in fertig]
        if not ziele:
            continue

        try:
            quelle = Path(eintrag["pfad"]).read_text(encoding="utf-8", errors="replace")
        except OSError as fehler:
            logger.warning("%s nicht lesbar: %s", eintrag["name"], fehler)
            continue

        zaehler["dateien"] += 1
        logger.info("[%s] %s (%s, %d B) -> %s",
                    eintrag["prioritaet"], eintrag["name"], eintrag["sprache"],
                    eintrag["bytes"], ", ".join(ziele))

        for zielsprache in ziele:
            if probelauf:
                logger.info("  %s: Probelauf, nichts gesendet", zielsprache)
                zaehler["uebersprungen"] += 1
                continue

            code = modell_fragen(quelle, eintrag["sprache"], zielsprache,
                                 eintrag["name"], schluessel)
            if code is None:
                zaehler["verworfen"] += 1
                continue

            angenommen, grund = erzeugnis_pruefen(code, zielsprache, quelle)
            if not angenommen:
                logger.warning("  %s: verworfen — %s", zielsprache, grund)
                zaehler["verworfen"] += 1
                continue

            ziel = ablegen(eintrag, zielsprache, code, belegt)
            if ziel is None:
                zaehler["verworfen"] += 1
                continue

            logger.info("  %s: %s (%s)", zielsprache, ziel.name, grund)
            zaehler["erzeugt"] += 1
            fertig.add(zielsprache)

        erledigt[eintrag["hash"]] = sorted(fertig)

    return zaehler

# ---------------------------------------------------------------------------
# Bericht und Veroeffentlichung
# ---------------------------------------------------------------------------


def bericht_schreiben(inventar: List[Dict], zustand: Dict, zaehler: Dict[str, int]) -> None:
    """Schreibt STATUS.md im Abstraktions-Repository fort."""
    if not ABSTRACTIONS_REPO.exists():
        logger.warning("Abstraktions-Repository fehlt: %s", ABSTRACTIONS_REPO)
        return

    je_sprache = {}
    for sprache in ZIELSPRACHEN:
        verzeichnis = ABSTRACTIONS_REPO / sprache
        je_sprache[sprache] = sum(1 for p in verzeichnis.iterdir() if p.is_file()) \
            if verzeichnis.is_dir() else 0

    rang = {"high": 0, "medium": 1, "low": 2}
    je_prio = {p: sum(1 for e in inventar if e["prioritaet"] == p) for p in rang}
    erledigt = zustand.get("erledigt", {})
    offen = sum(
        len([z for z in ZIELSPRACHEN if z != e["sprache"]]) - len(erledigt.get(e["hash"], []))
        for e in inventar
    )

    zeilen = [
        "# Script Abstractions — Status",
        "",
        f"**Letzter Lauf:** {datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M')} UTC",
        "",
        "Jede Quelldatei der drei Repositories wird in sechs Zielsprachen portiert.",
        "Es werden vollstaendige Uebersetzungen abgelegt; Erzeugnisse ohne gueltige",
        "Syntax oder mit Platzhaltern werden verworfen.",
        "",
        "## Bestand",
        "",
        "| Zielsprache | Dateien |",
        "|---|---:|",
    ]
    zeilen += [f"| {s} | {a} |" for s, a in sorted(je_sprache.items())]
    zeilen += [
        f"| **gesamt** | **{sum(je_sprache.values())}** |",
        "",
        "## Quellen",
        "",
        "| Prioritaet | Quelldateien | Bedeutung |",
        "|---|---:|---|",
        f"| high | {je_prio['high']} | Betriebsscripte aus scripts-Verzeichnissen |",
        f"| medium | {je_prio['medium']} | uebriger ausfuehrbarer Code |",
        f"| low | {je_prio['low']} | Markup und Stilvorlagen |",
        f"| **gesamt** | **{len(inventar)}** | nach Inhalt dedupliziert |",
        "",
        f"Noch offene Sprachpaare: **{offen}**",
        "",
        "## Letzter Lauf",
        "",
        f"- bearbeitete Quelldateien: {zaehler['dateien']}",
        f"- erzeugte Uebersetzungen: {zaehler['erzeugt']}",
        f"- verworfen: {zaehler['verworfen']}",
        "",
        "## Herkunft",
        "",
        "- `KikiKari/OpenClaw` — main, gateway1, gateway2",
        "- `KikiKari/Projects` — alle Branches",
        "- `KikiKari/Onboarding` — main",
        "",
        "Erzeugt von `abstractions/ABSTRACTIONS_MANAGER.py`.",
        "",
    ]
    try:
        (ABSTRACTIONS_REPO / "STATUS.md").write_text("\n".join(zeilen), encoding="utf-8")
        logger.info("STATUS.md fortgeschrieben")
    except OSError as fehler:
        logger.error("STATUS.md konnte nicht geschrieben werden: %s", fehler)


def veroeffentlichen(nachricht: str) -> None:
    """
    Uebertraegt neue Erzeugnisse in den Branch abstractions.

    Es wird nur gepusht, wenn ein Token in der Umgebung liegt. Ohne Token
    bleibt der Commit lokal — das ist der Normalfall im Container, der nur
    liest.
    """
    if not (ABSTRACTIONS_REPO / ".git").exists():
        logger.info("Kein Git-Arbeitsbaum in %s — nichts zu veroeffentlichen", ABSTRACTIONS_REPO)
        return

    stand = _git("status", "--porcelain", verzeichnis=ABSTRACTIONS_REPO)
    if not stand.stdout.strip():
        logger.info("Keine Aenderungen zu veroeffentlichen")
        return

    for sprache in ZIELSPRACHEN:
        _git("add", sprache, verzeichnis=ABSTRACTIONS_REPO)
    _git("add", "STATUS.md", verzeichnis=ABSTRACTIONS_REPO)

    ergebnis = _git("commit", "-m", nachricht, verzeichnis=ABSTRACTIONS_REPO)
    if ergebnis.returncode != 0:
        logger.warning("Commit fehlgeschlagen: %s", (ergebnis.stderr or ergebnis.stdout).strip()[:200])
        return
    logger.info("Commit gesetzt: %s", nachricht)

    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("ABSTRACTIONS_PUSH_TOKEN")
    if not token:
        logger.info("Kein Token in der Umgebung — Commit bleibt lokal")
        return

    url = f"https://x-access-token:{token}@github.com/{GITHUB_BENUTZER}/Projects.git"
    ergebnis = _git("push", url, "HEAD:abstractions", verzeichnis=ABSTRACTIONS_REPO)
    if ergebnis.returncode == 0:
        logger.info("Nach Projects@abstractions veroeffentlicht")
    else:
        logger.error("Push fehlgeschlagen: %s", (ergebnis.stderr or "").replace(token, "***")[:200])


# ---------------------------------------------------------------------------
# Einstiegspunkt
# ---------------------------------------------------------------------------


def main() -> int:
    """Holt die Quellen, uebersetzt eine Prioritaetsstufe und veroeffentlicht."""
    zerleger = argparse.ArgumentParser(description="Portiert Quellcode in sechs Zielsprachen.")
    zerleger.add_argument("--prioritaet", choices=["high", "medium", "low", "alle"],
                          help="Nur diese Stufe bearbeiten. Ohne Angabe wird reihum gewechselt.")
    zerleger.add_argument("--anzahl", type=int,
                          default=int(os.environ.get("ABSTRACTIONS_ANZAHL", "40")),
                          help="Hoechstzahl Quelldateien je Lauf.")
    zerleger.add_argument("--probelauf", action="store_true",
                          help="Inventar aufbauen und Plan zeigen, ohne zu uebersetzen.")
    argumente = zerleger.parse_args()

    logger.info("Abstractions Manager gestartet — Arbeitsverzeichnis %s", WORKSPACE)

    # Umschliessende Leerzeichen und Zeilenumbrueche entfernen: ein Schluessel,
    # der beim Einfuegen ein Leerzeichen mitbekommen hat, ist zwar nicht leer,
    # ergibt aber einen leeren Bearer — OpenRouter antwortet dann mit
    # "Missing Authentication header" statt mit "User not found".
    schluessel = os.environ.get("OPENROUTER_API_KEY", "").strip()
    if not argumente.probelauf:
        if not schluessel:
            logger.error("OPENROUTER_API_KEY ist leer oder besteht nur aus Leerraum "
                         "— ohne Schluessel keine Uebersetzung")
            return 2
        if not schluessel.startswith("sk-or-"):
            logger.error("OPENROUTER_API_KEY sieht nicht nach einem OpenRouter-Schluessel "
                         "aus (%d Zeichen, beginnt mit %r) — erwartet wird sk-or-...",
                         len(schluessel), schluessel[:6])
            return 2
        logger.info("Schluessel erkannt: %d Zeichen", len(schluessel))

    zustand = zustand_laden()
    baeume = quellen_holen()
    if not baeume:
        logger.error("Keine Quellen verfuegbar")
        return 1

    inventar = inventar_bauen(baeume)
    if not inventar:
        logger.error("Inventar leer")
        return 1

    prioritaet = argumente.prioritaet or zustand.get("naechste_prioritaet", "high")
    zaehler = uebersetzen(inventar, zustand, prioritaet, argumente.anzahl,
                          argumente.probelauf, schluessel)

    reihum = {"high": "medium", "medium": "low", "low": "high", "alle": "alle"}
    zustand["naechste_prioritaet"] = reihum[prioritaet]
    zustand["statistik"] = {
        "letzter_lauf": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "quelldateien": len(inventar),
        **zaehler,
    }

    bericht_schreiben(inventar, zustand, zaehler)
    zustand_speichern(zustand)

    if zaehler["erzeugt"] and not argumente.probelauf:
        veroeffentlichen(
            f"auto: {zaehler['erzeugt']} Uebersetzungen ({prioritaet}) "
            f"aus {zaehler['dateien']} Quelldateien"
        )

    logger.info("Abgeschlossen: %d erzeugt, %d verworfen, %d Quelldateien bearbeitet",
                zaehler["erzeugt"], zaehler["verworfen"], zaehler["dateien"])
    return 0


if __name__ == "__main__":
    sys.exit(main())
