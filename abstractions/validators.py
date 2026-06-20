"""
validators.py — Eingabevalidierung für den Abstractions Manager.

Alle Validierungsfunktionen sind hier zentralisiert, um konsistente
Sicherheitsprüfungen in der gesamten Codebasis zu gewährleisten.

Sicherheitsmaßnahmen:
    - Path-Traversal-Schutz via Path.resolve() + Allowlist
    - Shell-Injection-Prävention via Allowlists und Regex
    - API-Modell-Allowlist gegen unerlaubte Modell-Namen

Author: OpenClaw Team
Version: 1.0.0
"""

import re
import os
import logging
from pathlib import Path

from exceptions import ValidationError, ApiKeyError

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# Konfiguration — Allowlists
# ---------------------------------------------------------------------------

#: Erlaubte Basis-Verzeichnisse für Quelldateien (Path-Traversal-Schutz).
#: Wird aus Umgebungsvariable geladen, Fallback auf Standard-Pfad.
ALLOWED_SOURCE_DIRECTORIES: list[Path] = [
    Path(os.environ.get(
        "OPENCLAW_WORKSPACE",
        "/home/openclaw/.openclaw/workspace"
    ))
]

#: Erlaubte KI-Modell-Namen (Allowlist gegen unerlaubte Modell-Strings).
ALLOWED_AI_MODELS: frozenset[str] = frozenset({
    "openrouter/anthropic/claude-3-5-sonnet-20241022",
    "openrouter/anthropic/claude-3-haiku-20240307",
    "openrouter/anthropic/claude-opus-4",
    "openrouter/openai/gpt-4o",
    "openrouter/openai/gpt-4o-mini",
})

#: Erlaubte Zielsprachen für Script-Portierungen.
ALLOWED_TARGET_LANGUAGES: frozenset[str] = frozenset({
    "perl5", "perl6", "javascript", "python",
    "bash", "powershell", "tcl", "ruby", "lua", "go",
})

#: Regex für erlaubte Zeichen in Task-Beschreibungen.
_SAFE_TASK_PATTERN: re.Pattern = re.compile(
    r'^[a-zA-Z0-9äöüÄÖÜß .,()\[\]_\-/]+$'
)

#: Maximale Länge einer Task-Beschreibung.
MAX_TASK_DESCRIPTION_LENGTH: int = 500

#: Erlaubter Timeout-Bereich in Sekunden.
MIN_TIMEOUT_SECONDS: int = 1
MAX_TIMEOUT_SECONDS: int = 7200  # 2 Stunden


# ---------------------------------------------------------------------------
# Pfad-Validierung
# ---------------------------------------------------------------------------

def validate_source_file_path(raw_path: str) -> Path:
    """Validiert einen Quelldatei-Pfad gegen erlaubte Verzeichnisse.

    Löst symbolische Links auf und prüft, ob der resultierende Pfad
    innerhalb eines erlaubten Verzeichnisses liegt. Verhindert damit
    Path-Traversal-Angriffe (z. B. ``../../etc/passwd``).

    Args:
        raw_path: Roher Dateipfad als String (absolut oder relativ).

    Returns:
        Validierter, vollständig aufgelöster ``Path``-Objekt.

    Raises:
        FileNotFoundError: Wenn die Datei nicht existiert.
        ValidationError: Wenn der Pfad außerhalb der erlaubten
            Verzeichnisse liegt oder kein reguläres File ist.
        PermissionError: Wenn keine Leseberechtigung vorhanden ist.

    Example:
        >>> path = validate_source_file_path("/workspace/scripts/db_maintainer.py")
        >>> print(path)
        /home/openclaw/.openclaw/workspace/scripts/db_maintainer.py
    """
    resolved_path = Path(raw_path).resolve()

    if not resolved_path.exists():
        raise FileNotFoundError(
            f"Quelldatei nicht gefunden: {resolved_path}"
        )

    if not resolved_path.is_file():
        raise ValidationError(
            field_name="source_path",
            invalid_value=raw_path,
            reason=f"Pfad ist kein reguläres File: {resolved_path}",
        )

    is_within_allowed_directory = any(
        resolved_path.is_relative_to(allowed_dir.resolve())
        for allowed_dir in ALLOWED_SOURCE_DIRECTORIES
    )

    if not is_within_allowed_directory:
        logger.warning(
            "Path-Traversal-Versuch blockiert: '%s' → '%s'",
            raw_path,
            resolved_path,
        )
        raise ValidationError(
            field_name="source_path",
            invalid_value=raw_path,
            reason=(
                f"Zugriff verweigert: Pfad liegt außerhalb der erlaubten "
                f"Verzeichnisse: {[str(d) for d in ALLOWED_SOURCE_DIRECTORIES]}"
            ),
        )

    logger.debug("Quelldatei validiert: %s", resolved_path)
    return resolved_path


# ---------------------------------------------------------------------------
# Task-Beschreibung
# ---------------------------------------------------------------------------

def validate_task_description(raw_task: str) -> str:
    """Validiert eine Task-Beschreibung auf Shell-sichere Zeichen.

    Verhindert Shell-Injection durch Allowlist-basierte Zeichenprüfung.
    Erlaubt nur alphanumerische Zeichen, Leerzeichen und ausgewählte
    Satzzeichen.

    Args:
        raw_task: Rohe Task-Beschreibung vom Benutzer oder Aufrufer.

    Returns:
        Getrimmte, validierte Task-Beschreibung.

    Raises:
        ValidationError: Wenn die Beschreibung ungültige Zeichen enthält
            oder das Längenlimit überschreitet.

    Example:
        >>> validated = validate_task_description("Port db_maintainer.py to Go")
        >>> print(validated)
        Port db_maintainer.py to Go
    """
    if not isinstance(raw_task, str) or not raw_task.strip():
        raise ValidationError(
            field_name="task_description",
            invalid_value=raw_task,
            reason="Task-Beschreibung darf nicht leer sein.",
        )

    stripped_task = raw_task.strip()

    if len(stripped_task) > MAX_TASK_DESCRIPTION_LENGTH:
        raise ValidationError(
            field_name="task_description",
            invalid_value=f"<{len(stripped_task)} Zeichen>",
            reason=(
                f"Zu lang: {len(stripped_task)} Zeichen "
                f"(Maximum: {MAX_TASK_DESCRIPTION_LENGTH})"
            ),
        )

    if not _SAFE_TASK_PATTERN.match(stripped_task):
        raise ValidationError(
            field_name="task_description",
            invalid_value="<bereinigt>",
            reason=(
                "Unerlaubte Zeichen gefunden. Erlaubt: Buchstaben, Ziffern, "
                "Leerzeichen und .,()[]_-/"
            ),
        )

    return stripped_task


# ---------------------------------------------------------------------------
# Modell-Validierung
# ---------------------------------------------------------------------------

def validate_ai_model_name(raw_model_name: str) -> str:
    """Validiert einen KI-Modell-Namen gegen die Allowlist.

    Verhindert Command-Injection durch unbekannte Modell-Strings indem
    nur explizit erlaubte Modell-Namen akzeptiert werden.

    Args:
        raw_model_name: Der zu prüfende Modell-Name.

    Returns:
        Den validierten Modell-Namen (unverändert).

    Raises:
        ValidationError: Wenn der Modell-Name nicht in der Allowlist ist.

    Example:
        >>> model = validate_ai_model_name(
        ...     "openrouter/anthropic/claude-3-5-sonnet-20241022"
        ... )
    """
    if raw_model_name not in ALLOWED_AI_MODELS:
        logger.warning(
            "Unbekanntes Modell angefordert (blockiert): '%s'",
            raw_model_name,
        )
        raise ValidationError(
            field_name="ai_model",
            invalid_value=raw_model_name,
            reason=(
                f"Modell nicht in Allowlist. "
                f"Erlaubt: {sorted(ALLOWED_AI_MODELS)}"
            ),
        )

    return raw_model_name


# ---------------------------------------------------------------------------
# Zielsprachen-Validierung
# ---------------------------------------------------------------------------

def validate_target_language(raw_language: str) -> str:
    """Validiert eine Zielsprache gegen die Liste unterstützter Sprachen.

    Args:
        raw_language: Zielsprache als String (z. B. ``"perl5"``).

    Returns:
        Validierte Zielsprache in Kleinschreibung.

    Raises:
        ValidationError: Wenn die Sprache nicht unterstützt wird.

    Example:
        >>> lang = validate_target_language("JavaScript")
        >>> print(lang)
        javascript
    """
    normalized_language = raw_language.strip().lower()

    if normalized_language not in ALLOWED_TARGET_LANGUAGES:
        raise ValidationError(
            field_name="target_language",
            invalid_value=raw_language,
            reason=(
                f"Sprache '{normalized_language}' wird nicht unterstützt. "
                f"Erlaubt: {sorted(ALLOWED_TARGET_LANGUAGES)}"
            ),
        )

    return normalized_language


# ---------------------------------------------------------------------------
# Timeout-Validierung
# ---------------------------------------------------------------------------

def validate_timeout_seconds(raw_timeout: int) -> int:
    """Validiert einen Timeout-Wert auf erlaubten Bereich.

    Args:
        raw_timeout: Timeout in Sekunden.

    Returns:
        Validierter Timeout-Wert.

    Raises:
        ValidationError: Wenn der Timeout außerhalb des erlaubten
            Bereichs liegt.

    Example:
        >>> timeout = validate_timeout_seconds(1800)
        >>> print(timeout)
        1800
    """
    if not isinstance(raw_timeout, int) or not (
        MIN_TIMEOUT_SECONDS <= raw_timeout <= MAX_TIMEOUT_SECONDS
    ):
        raise ValidationError(
            field_name="timeout_seconds",
            invalid_value=raw_timeout,
            reason=(
                f"Timeout muss zwischen {MIN_TIMEOUT_SECONDS} und "
                f"{MAX_TIMEOUT_SECONDS} Sekunden liegen."
            ),
        )

    return raw_timeout


# ---------------------------------------------------------------------------
# API-Schlüssel-Validierung
# ---------------------------------------------------------------------------

def load_and_validate_api_key(provider_name: str) -> str:
    """Lädt und validiert einen KI-Provider API-Schlüssel aus der Umgebung.

    Liest den Schlüssel aus der Umgebungsvariable ``{PROVIDER}_API_KEY``
    (wird per .env gesetzt) und prüft auf Vorhandensein und Mindestlänge.

    Args:
        provider_name: Name des Providers in Großbuchstaben
            (z. B. ``"ANTHROPIC"``, ``"OPENAI"``).

    Returns:
        Den API-Schlüssel als String.

    Raises:
        ApiKeyError: Wenn die Umgebungsvariable fehlt oder der Schlüssel
            zu kurz ist.

    Example:
        >>> key = load_and_validate_api_key("ANTHROPIC")
        >>> print(key[:8] + "...")
        sk-ant-a...
    """
    env_variable_name = f"{provider_name.upper()}_API_KEY"
    api_key = os.environ.get(env_variable_name, "").strip()

    if not api_key:
        raise ApiKeyError(
            provider_name=provider_name,
            reason=(
                f"Umgebungsvariable '{env_variable_name}' ist nicht gesetzt. "
                f"Bitte in der .env-Datei konfigurieren."
            ),
        )

    if len(api_key) < 20:
        raise ApiKeyError(
            provider_name=provider_name,
            reason=(
                f"API-Schlüssel aus '{env_variable_name}' erscheint ungültig "
                f"(zu kurz: {len(api_key)} Zeichen, Minimum: 20)."
            ),
        )

    logger.debug("API-Schlüssel geladen: %s (***)", env_variable_name)
    return api_key
