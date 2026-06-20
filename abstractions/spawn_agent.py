"""
spawn_agent.py — Sicherer Sub-Agenten-Starter für den Abstractions Manager.

Startet einen KI-Sub-Agenten für komplexe Script-Portierungsaufgaben.
Alle Eingaben werden vor der Ausführung validiert, um Shell-Injection
und andere Angriffsvektoren zu verhindern.

Sicherheitsmaßnahmen:
    - subprocess.run() mit Liste (kein shell=True) verhindert Shell-Injection
    - Allowlist für Modell-Namen verhindert unerlaubte Modell-Strings
    - Allowlist für Zielsprachen
    - Timeout-Validierung verhindert Denial-of-Service

Verwendung (CLI)::

    python3 spawn_agent.py \\
        --task "Port db_maintainer.py to Go with full error handling" \\
        --model openrouter/anthropic/claude-3-5-sonnet-20241022 \\
        --timeout 1800

Verwendung (programmatisch)::

    from spawn_agent import spawn_portation_agent
    result = spawn_portation_agent(
        task_description="Port json_processor.py to Perl 5",
        ai_model_name="openrouter/anthropic/claude-3-5-sonnet-20241022",
        timeout_seconds=1800,
    )

Author: OpenClaw Team
Version: 1.0.0
"""

import argparse
import logging
import subprocess
import sys
from pathlib import Path

from dotenv import load_dotenv

from exceptions import ValidationError, ApiKeyError, AbstractionsManagerError
from validators import (
    validate_task_description,
    validate_ai_model_name,
    validate_timeout_seconds,
    load_and_validate_api_key,
)
from logger import configure_application_logging

# .env laden — muss vor allen anderen Importen liegen die os.environ nutzen
load_dotenv()

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Pfade
# ---------------------------------------------------------------------------

_WORKSPACE_BASE = Path("/home/openclaw/.openclaw/workspace")
_LOG_DIRECTORY = _WORKSPACE_BASE / "logs" / "abstractions-manager"
_AGENT_RUNNER_SCRIPT = _WORKSPACE_BASE / "skills" / "sub-agents-utils" / "scripts" / "agent_runner.py"


# ---------------------------------------------------------------------------
# Kern-Funktion
# ---------------------------------------------------------------------------

def spawn_portation_agent(
    task_description: str,
    ai_model_name: str,
    timeout_seconds: int,
    agent_runner_path: Path = _AGENT_RUNNER_SCRIPT,
    dry_run: bool = False,
) -> subprocess.CompletedProcess:
    """Startet einen Sub-Agenten für eine Script-Portierungsaufgabe.

    Validiert alle Eingaben, baut den Prozess-Aufruf sicher als Liste
    auf (kein ``shell=True``) und startet den Agent-Runner-Prozess.

    Args:
        task_description: Natürlichsprachige Beschreibung der Portierungsaufgabe.
            Darf nur alphanumerische Zeichen und ausgewählte Satzzeichen enthalten.
        ai_model_name: Name des zu verwendenden KI-Modells.
            Muss in der Allowlist in ``validators.py`` enthalten sein.
        timeout_seconds: Maximale Laufzeit des Agenten in Sekunden (1–7200).
        agent_runner_path: Pfad zum Agent-Runner-Script.
            Standard: Workspace-Standard-Pfad.
        dry_run: Wenn ``True``, wird der Befehl nur geloggt aber nicht
            ausgeführt. Nützlich für Tests. Standard: ``False``.

    Returns:
        ``CompletedProcess``-Objekt mit ``returncode``, ``stdout``, ``stderr``.
        Bei ``dry_run=True`` wird ein Mock-Objekt mit ``returncode=0``
        zurückgegeben.

    Raises:
        ValidationError: Bei ungültigen Eingabeparametern.
        ApiKeyError: Wenn der API-Schlüssel fehlt oder ungültig ist.
        FileNotFoundError: Wenn ``agent_runner_path`` nicht existiert.
        subprocess.TimeoutExpired: Wenn der Agent den Timeout überschreitet.

    Example:
        >>> result = spawn_portation_agent(
        ...     task_description="Port db_maintainer.py to Go",
        ...     ai_model_name="openrouter/anthropic/claude-3-5-sonnet-20241022",
        ...     timeout_seconds=1800,
        ... )
        >>> print("Exit-Code:", result.returncode)
    """
    # Eingaben validieren (wirft ValidationError bei Problemen)
    validated_task = validate_task_description(task_description)
    validated_model = validate_ai_model_name(ai_model_name)
    validated_timeout = validate_timeout_seconds(timeout_seconds)

    # API-Schlüssel prüfen
    provider_name = _extract_provider_name(validated_model)
    load_and_validate_api_key(provider_name)

    # Agent-Script prüfen
    if not agent_runner_path.is_file():
        raise FileNotFoundError(
            f"Agent-Runner-Script nicht gefunden: {agent_runner_path}"
        )

    # Befehl als Liste aufbauen (KEIN shell=True → kein Shell-Injection-Risiko)
    command = [
        sys.executable,
        str(agent_runner_path),
        "--task", validated_task,
        "--model", validated_model,
        "--timeout", str(validated_timeout),
    ]

    logger.info(
        "Starte Sub-Agenten",
        extra={
            "model": validated_model,
            "timeout_seconds": validated_timeout,
            "task_preview": validated_task[:80],
            "dry_run": dry_run,
        },
    )

    if dry_run:
        logger.info("Dry-Run: Befehl würde lauten: %s", " ".join(command))
        # Mock-Objekt zurückgeben
        return subprocess.CompletedProcess(
            args=command, returncode=0, stdout="[dry-run]", stderr=""
        )

    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            timeout=validated_timeout + 60,  # Puffer für Shutdown
            check=False,  # Fehler manuell prüfen
        )

        if result.returncode == 0:
            logger.info(
                "Sub-Agent erfolgreich beendet",
                extra={"returncode": result.returncode},
            )
        else:
            logger.error(
                "Sub-Agent mit Fehler beendet",
                extra={
                    "returncode": result.returncode,
                    "stderr_preview": result.stderr[:200] if result.stderr else "",
                },
            )

        return result

    except subprocess.TimeoutExpired as timeout_error:
        logger.error(
            "Sub-Agent Timeout nach %ds — wird abgebrochen",
            validated_timeout,
        )
        raise


# ---------------------------------------------------------------------------
# Hilfsfunktionen
# ---------------------------------------------------------------------------

def _extract_provider_name(model_name: str) -> str:
    """Extrahiert den Provider-Namen aus einem Modell-String.

    Args:
        model_name: Modell-String im Format ``provider/model`` oder
            ``router/provider/model``.

    Returns:
        Provider-Name in Großbuchstaben (z. B. ``"ANTHROPIC"``).

    Example:
        >>> _extract_provider_name("openrouter/anthropic/claude-3-5-sonnet")
        'ANTHROPIC'
    """
    parts = model_name.split("/")
    # Format: openrouter/anthropic/model → Provider = anthropic (Index 1)
    provider = parts[1] if len(parts) >= 3 else parts[0]
    return provider.upper()


# ---------------------------------------------------------------------------
# CLI-Einstiegspunkt
# ---------------------------------------------------------------------------

def _build_argument_parser() -> argparse.ArgumentParser:
    """Erstellt den CLI-Argument-Parser.

    Returns:
        Konfigurierter ``ArgumentParser``.
    """
    parser = argparse.ArgumentParser(
        description="Startet einen KI-Sub-Agenten für Script-Portierungen.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Beispiele:
  python3 spawn_agent.py \\
      --task "Port db_maintainer.py to Go" \\
      --model openrouter/anthropic/claude-3-5-sonnet-20241022 \\
      --timeout 1800

  python3 spawn_agent.py --task "Port json_processor.py to Perl 5" --dry-run
        """,
    )
    parser.add_argument(
        "--task",
        required=True,
        help="Beschreibung der Portierungsaufgabe (max. 500 Zeichen).",
    )
    parser.add_argument(
        "--model",
        required=True,
        help="KI-Modell-Name (muss in der Allowlist sein).",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=1800,
        help="Maximale Laufzeit in Sekunden (Standard: 1800).",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        default=False,
        help="Zeigt den Befehl nur an ohne ihn auszuführen.",
    )
    parser.add_argument(
        "--log-level",
        default=None,
        choices=["DEBUG", "INFO", "WARNING", "ERROR"],
        help="Log-Level (Standard: aus .env oder INFO).",
    )
    return parser


def main() -> int:
    """CLI-Hauptfunktion für spawn_agent.py.

    Returns:
        Exit-Code: 0 bei Erfolg, 1 bei Fehler.
    """
    configure_application_logging(log_directory=_LOG_DIRECTORY)
    parser = _build_argument_parser()
    args = parser.parse_args()

    try:
        result = spawn_portation_agent(
            task_description=args.task,
            ai_model_name=args.model,
            timeout_seconds=args.timeout,
            dry_run=args.dry_run,
        )
        return result.returncode

    except (ValidationError, ApiKeyError) as user_error:
        logger.error("Eingabefehler: %s", user_error)
        print(f"Fehler: {user_error}", file=sys.stderr)
        return 1

    except FileNotFoundError as not_found_error:
        logger.error("Datei nicht gefunden: %s", not_found_error)
        print(f"Fehler: {not_found_error}", file=sys.stderr)
        return 1

    except subprocess.TimeoutExpired:
        logger.error("Timeout abgelaufen — Agent wurde abgebrochen.")
        print("Fehler: Agent-Timeout abgelaufen.", file=sys.stderr)
        return 1

    except AbstractionsManagerError as app_error:
        logger.error("Anwendungsfehler: %s", app_error, exc_info=True)
        print(f"Fehler: {app_error}", file=sys.stderr)
        return 1

    except Exception as unexpected_error:
        logger.critical(
            "Unerwarteter Fehler: %s", unexpected_error, exc_info=True
        )
        print(f"Unerwarteter Fehler: {unexpected_error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
