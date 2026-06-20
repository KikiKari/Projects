"""
logger.py — Zentrales Logging-Setup für den Abstractions Manager.

Richtet strukturiertes JSON-Logging (Produktion) und lesbares
Text-Logging (Entwicklung) ein. Alle anderen Module verwenden
``logging.getLogger(__name__)`` und profitieren automatisch von
dieser Konfiguration.

Verwendung:
    Am Programm-Start (vor allen anderen Imports) aufrufen::

        from logger import configure_application_logging
        from pathlib import Path

        configure_application_logging(
            log_directory=Path("/home/openclaw/.openclaw/workspace/logs/abstractions-manager"),
        )

Umgebungsvariablen:
    ABSTRACTIONS_LOG_LEVEL: Log-Level (DEBUG/INFO/WARNING/ERROR/CRITICAL).
        Standard: INFO.
    ABSTRACTIONS_JSON_LOGGING: "1" für JSON-Format, "0" für Text.
        Standard: "1" (JSON).

Author: OpenClaw Team
Version: 1.0.0
"""

import json
import logging
import logging.handlers
import os
import sys
from datetime import datetime, timezone
from pathlib import Path


# ---------------------------------------------------------------------------
# JSON-Formatter
# ---------------------------------------------------------------------------

class JsonFormatter(logging.Formatter):
    """Formatiert Log-Einträge als maschinenlesbares JSON.

    Jeder Eintrag enthält: ``timestamp``, ``level``, ``logger``,
    ``message``, ``module``, ``function``, ``line``. Bei Exceptions
    wird zusätzlich ``exception`` gesetzt.

    Example Output::

        {
          "timestamp": "2026-05-26T10:00:00+00:00",
          "level": "INFO",
          "logger": "abstractions_manager",
          "message": "Portierung abgeschlossen: db_maintainer.py → perl5",
          "module": "abstractions_manager",
          "function": "run_portation_cycle",
          "line": 142
        }
    """

    def format(self, record: logging.LogRecord) -> str:
        """Konvertiert einen LogRecord in einen JSON-String.

        Args:
            record: Der zu formatierende Log-Eintrag.

        Returns:
            Einzeiliger JSON-String des Log-Eintrags.
        """
        log_entry: dict = {
            "timestamp": datetime.fromtimestamp(
                record.created, tz=timezone.utc
            ).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }

        if record.exc_info:
            log_entry["exception"] = self.formatException(record.exc_info)

        # Zusätzliche Felder aus extra={} übernehmen
        for key, value in record.__dict__.items():
            if key not in (
                "name", "msg", "args", "created", "levelname", "levelno",
                "pathname", "filename", "module", "exc_info", "exc_text",
                "stack_info", "lineno", "funcName", "msecs", "relativeCreated",
                "thread", "threadName", "processName", "process", "message",
            ):
                if not key.startswith("_"):
                    log_entry[key] = value

        return json.dumps(log_entry, ensure_ascii=False, default=str)


# ---------------------------------------------------------------------------
# Text-Formatter (Entwicklung)
# ---------------------------------------------------------------------------

_TEXT_FORMAT = (
    "%(asctime)s | %(levelname)-8s | %(name)s:%(lineno)d | %(message)s"
)
_DATE_FORMAT = "%Y-%m-%d %H:%M:%S"


# ---------------------------------------------------------------------------
# Haupt-Konfigurationsfunktion
# ---------------------------------------------------------------------------

def configure_application_logging(
    log_directory: Path,
    log_level: str | None = None,
    use_json_format: bool | None = None,
    max_log_file_bytes: int = 10 * 1024 * 1024,
    backup_log_count: int = 7,
) -> logging.Logger:
    """Konfiguriert das zentrale Logging-System der Anwendung.

    Richtet einen Konsolen-Handler und einen rotierenden Datei-Handler ein.
    Log-Level und Format werden bevorzugt aus Umgebungsvariablen gelesen,
    können aber durch Parameter überschrieben werden.

    Args:
        log_directory: Verzeichnis für Log-Dateien. Wird automatisch
            erstellt wenn nicht vorhanden.
        log_level: Log-Level als String. Wenn ``None``, wird
            ``ABSTRACTIONS_LOG_LEVEL`` aus der Umgebung gelesen
            (Standard: ``"INFO"``).
        use_json_format: ``True`` für JSON-Format (Produktion),
            ``False`` für Text (Entwicklung). Wenn ``None``, wird
            ``ABSTRACTIONS_JSON_LOGGING`` aus der Umgebung gelesen
            (Standard: ``True``).
        max_log_file_bytes: Maximale Dateigröße vor Rotation.
            Standard: 10 MB.
        backup_log_count: Anzahl rotierter Log-Dateien.
            Standard: 7 (eine Woche).

    Returns:
        Konfigurierter Root-Logger.

    Raises:
        ValueError: Wenn ``log_level`` kein gültiges Level ist.
        OSError: Wenn das Log-Verzeichnis nicht erstellt werden kann.

    Example:
        >>> from pathlib import Path
        >>> configure_application_logging(
        ...     log_directory=Path("/var/log/abstractions"),
        ...     log_level="DEBUG",
        ...     use_json_format=False,
        ... )
    """
    # Werte aus Umgebung lesen wenn nicht explizit gesetzt
    resolved_log_level = log_level or os.environ.get(
        "ABSTRACTIONS_LOG_LEVEL", "INFO"
    ).upper()

    resolved_use_json = use_json_format if use_json_format is not None else (
        os.environ.get("ABSTRACTIONS_JSON_LOGGING", "1") == "1"
    )

    # Log-Level validieren
    numeric_level = getattr(logging, resolved_log_level, None)
    if not isinstance(numeric_level, int):
        raise ValueError(
            f"Ungültiges Log-Level: '{resolved_log_level}'. "
            f"Erlaubt: DEBUG, INFO, WARNING, ERROR, CRITICAL"
        )

    # Log-Verzeichnis sicherstellen
    log_directory.mkdir(parents=True, exist_ok=True)

    # Root-Logger konfigurieren
    root_logger = logging.getLogger()
    root_logger.setLevel(numeric_level)

    # Bestehende Handler entfernen (verhindert Doppel-Logging bei Re-Calls)
    root_logger.handlers.clear()

    # Formatter wählen
    formatter: logging.Formatter = (
        JsonFormatter()
        if resolved_use_json
        else logging.Formatter(fmt=_TEXT_FORMAT, datefmt=_DATE_FORMAT)
    )

    # Konsolen-Handler (stdout)
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    console_handler.setLevel(numeric_level)
    root_logger.addHandler(console_handler)

    # Rotierender Datei-Handler
    log_file_path = log_directory / "abstractions_manager.log"
    file_handler = logging.handlers.RotatingFileHandler(
        filename=log_file_path,
        maxBytes=max_log_file_bytes,
        backupCount=backup_log_count,
        encoding="utf-8",
    )
    file_handler.setFormatter(formatter)
    file_handler.setLevel(numeric_level)
    root_logger.addHandler(file_handler)

    root_logger.info(
        "Logging initialisiert",
        extra={
            "log_level": resolved_log_level,
            "log_file": str(log_file_path),
            "json_format": resolved_use_json,
        },
    )

    return root_logger
