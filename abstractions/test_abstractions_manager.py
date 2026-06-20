"""
test_abstractions_manager.py — Unit-Tests für den Abstractions Manager.

Testet alle kritischen Sicherheits- und Kernfunktionen:
    - Path-Traversal-Schutz (validate_source_file_path)
    - Shell-Injection-Prävention (validate_task_description)
    - Modell-Allowlist (validate_ai_model_name)
    - Zielsprachen-Validierung (validate_target_language)
    - Timeout-Validierung (validate_timeout_seconds)
    - JSON-Serialisierung (create_abstraction.py Hilfsfunktionen)
    - File-Change-Detection (Hash-basiert)
    - Atomisches State-File-Schreiben

Ausführen:
    pytest test_abstractions_manager.py -v
    pytest test_abstractions_manager.py -v --cov=validators --cov=create_abstraction

Author: OpenClaw Team
Version: 1.0.0
"""

import json
import os
import sys
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

# Sicherstellen dass lokale Module importierbar sind
sys.path.insert(0, str(Path(__file__).parent))

from exceptions import (
    ValidationError,
    PortationError,
    ApiKeyError,
    StateFileError,
)
from validators import (
    validate_source_file_path,
    validate_task_description,
    validate_ai_model_name,
    validate_target_language,
    validate_timeout_seconds,
    load_and_validate_api_key,
    ALLOWED_TARGET_LANGUAGES,
    ALLOWED_AI_MODELS,
)
from create_abstraction import (
    compute_file_sha256,
    has_source_file_changed,
    load_abstraction_state,
    save_abstraction_state_atomically,
    LANGUAGE_FILE_EXTENSIONS,
)


# ===========================================================================
# Fixtures
# ===========================================================================

@pytest.fixture
def temp_workspace(tmp_path: Path) -> Path:
    """Erstellt eine temporäre Workspace-Struktur für Tests.

    Returns:
        Pfad zum temporären Workspace-Verzeichnis.
    """
    workspace = tmp_path / "workspace"
    scripts_dir = workspace / "skills" / "scripts"
    scripts_dir.mkdir(parents=True)
    return workspace


@pytest.fixture
def valid_python_script(temp_workspace: Path) -> Path:
    """Erstellt ein gültiges Python-Script im Test-Workspace.

    Returns:
        Pfad zum Test-Script.
    """
    scripts_dir = temp_workspace / "skills" / "scripts"
    script = scripts_dir / "db_maintainer.py"
    script.write_text("# Test-Script\nprint('hello world')\n", encoding="utf-8")
    return script


@pytest.fixture
def state_file_path(tmp_path: Path) -> Path:
    """Liefert einen Pfad für eine temporäre State-Datei.

    Returns:
        Pfad für die State-Datei (existiert noch nicht).
    """
    return tmp_path / "db" / "abstractions_state.json"


# ===========================================================================
# Tests: Path-Traversal-Schutz
# ===========================================================================

class TestSourceFilePathValidation:
    """Tests für Path-Traversal-Schutz in validate_source_file_path."""

    def test_valid_path_within_allowed_directory_is_accepted(
        self, valid_python_script: Path, temp_workspace: Path, monkeypatch
    ):
        """Gültiger Pfad innerhalb des erlaubten Verzeichnisses wird akzeptiert."""
        monkeypatch.setenv("OPENCLAW_WORKSPACE", str(temp_workspace))

        # Modul neu importieren damit Env-Variable wirkt
        import importlib
        import validators
        importlib.reload(validators)

        result = validators.validate_source_file_path(str(valid_python_script))
        assert result == valid_python_script.resolve()

    def test_nonexistent_file_raises_file_not_found_error(self):
        """Nicht existente Datei löst FileNotFoundError aus."""
        with pytest.raises(FileNotFoundError, match="nicht gefunden"):
            validate_source_file_path("/absolutely/nonexistent/path/script.py")

    def test_directory_instead_of_file_raises_validation_error(self, tmp_path: Path):
        """Verzeichnis-Pfad statt Datei löst ValidationError aus."""
        with pytest.raises(ValidationError, match="kein reguläres File"):
            validate_source_file_path(str(tmp_path))

    @pytest.mark.parametrize("traversal_attempt", [
        "/etc/passwd",
        "/etc/shadow",
        "/root/.ssh/id_rsa",
        "/proc/1/cmdline",
    ])
    def test_path_outside_workspace_raises_validation_error(
        self, traversal_attempt: str, monkeypatch
    ):
        """Pfade außerhalb des Workspaces werden blockiert."""
        monkeypatch.setenv("OPENCLAW_WORKSPACE", "/home/openclaw/.openclaw/workspace")

        # Datei existiert möglicherweise nicht — dann FileNotFoundError
        # Wenn sie existiert und außerhalb liegt — ValidationError
        with pytest.raises((ValidationError, FileNotFoundError)):
            validate_source_file_path(traversal_attempt)


# ===========================================================================
# Tests: Shell-Injection-Prävention
# ===========================================================================

class TestTaskDescriptionValidation:
    """Tests für Shell-Injection-Prävention in validate_task_description."""

    @pytest.mark.parametrize("valid_task", [
        "Port db_maintainer.py to Go",
        "Add error handling to json_processor",
        "Refactor websearch-crawl.sh for Perl 5",
        "Port check-live.js with full JSDoc",
        "Migrate log_collector.py to Ruby",
    ])
    def test_valid_task_descriptions_are_accepted(self, valid_task: str):
        """Gültige Task-Beschreibungen werden unverändert zurückgegeben."""
        result = validate_task_description(valid_task)
        assert result == valid_task.strip()

    @pytest.mark.parametrize("malicious_input, description", [
        ("; rm -rf /",           "Semikolon + Befehl"),
        ("$(cat /etc/passwd)",   "Befehlssubstitution $(...)"),
        ("`whoami`",             "Backtick-Substitution"),
        ("task && evil_cmd",     "&&-Verkettung"),
        ("task | cat /etc/shadow", "Pipe-Redirect"),
        ("task\ncommand",        "Newline-Injection"),
        ("task; exit 0",         "Semikolon-Injection"),
        ("task > /tmp/evil",     "Ausgabe-Redirect"),
    ])
    def test_shell_metacharacters_are_rejected(
        self, malicious_input: str, description: str
    ):
        """Shell-Metazeichen in Task-Beschreibungen werden blockiert."""
        with pytest.raises(ValidationError, match="Unerlaubte|unerlaubte"):
            validate_task_description(malicious_input)

    def test_empty_task_raises_validation_error(self):
        """Leere Task-Beschreibung löst ValidationError aus."""
        with pytest.raises(ValidationError):
            validate_task_description("")

    def test_whitespace_only_task_raises_validation_error(self):
        """Nur-Leerzeichen Task löst ValidationError aus."""
        with pytest.raises(ValidationError):
            validate_task_description("   ")

    def test_task_at_maximum_length_is_accepted(self):
        """Task exakt an der Maximallänge (500 Zeichen) wird akzeptiert."""
        max_length_task = "a" * 500
        result = validate_task_description(max_length_task)
        assert len(result) == 500

    def test_task_exceeding_maximum_length_raises_validation_error(self):
        """Task über 500 Zeichen löst ValidationError aus."""
        too_long_task = "a" * 501
        with pytest.raises(ValidationError, match="lang|Länge"):
            validate_task_description(too_long_task)


# ===========================================================================
# Tests: Modell-Allowlist
# ===========================================================================

class TestAiModelValidation:
    """Tests für die KI-Modell-Allowlist in validate_ai_model_name."""

    @pytest.mark.parametrize("valid_model", list(ALLOWED_AI_MODELS))
    def test_all_allowed_models_are_accepted(self, valid_model: str):
        """Alle Modelle aus der Allowlist werden akzeptiert."""
        result = validate_ai_model_name(valid_model)
        assert result == valid_model

    @pytest.mark.parametrize("invalid_model", [
        "gpt-4",                          # Ohne Provider-Prefix
        "unknown-model",                   # Unbekanntes Modell
        "openrouter/evil; rm -rf /",       # Injection-Versuch
        "",                               # Leer
        "claude-3-5-sonnet-20241022",     # Ohne openrouter/-Prefix
    ])
    def test_unknown_models_are_rejected(self, invalid_model: str):
        """Unbekannte Modelle außerhalb der Allowlist werden blockiert."""
        with pytest.raises(ValidationError):
            validate_ai_model_name(invalid_model)


# ===========================================================================
# Tests: Zielsprachen-Validierung
# ===========================================================================

class TestTargetLanguageValidation:
    """Tests für validate_target_language."""

    @pytest.mark.parametrize("valid_language", list(ALLOWED_TARGET_LANGUAGES))
    def test_all_supported_languages_are_accepted(self, valid_language: str):
        """Alle unterstützten Zielsprachen werden akzeptiert."""
        result = validate_target_language(valid_language)
        assert result == valid_language.lower()

    def test_language_is_normalized_to_lowercase(self):
        """Zielsprachen werden auf Kleinschreibung normalisiert."""
        result = validate_target_language("JavaScript")
        assert result == "javascript"

    def test_unsupported_language_raises_validation_error(self):
        """Nicht unterstützte Sprachen werden blockiert."""
        with pytest.raises(ValidationError, match="nicht unterstützt"):
            validate_target_language("cobol")

    def test_language_with_injection_attempt_raises_validation_error(self):
        """Injection-Versuche in Sprachen-Parameter werden blockiert."""
        with pytest.raises(ValidationError):
            validate_target_language("perl5; rm -rf /")


# ===========================================================================
# Tests: Timeout-Validierung
# ===========================================================================

class TestTimeoutValidation:
    """Tests für validate_timeout_seconds."""

    @pytest.mark.parametrize("valid_timeout", [1, 60, 1800, 3600, 7200])
    def test_valid_timeouts_are_accepted(self, valid_timeout: int):
        """Gültige Timeout-Werte werden akzeptiert."""
        result = validate_timeout_seconds(valid_timeout)
        assert result == valid_timeout

    @pytest.mark.parametrize("invalid_timeout", [0, -1, 7201, 99999])
    def test_out_of_range_timeouts_raise_validation_error(self, invalid_timeout: int):
        """Timeout außerhalb 1–7200 löst ValidationError aus."""
        with pytest.raises(ValidationError):
            validate_timeout_seconds(invalid_timeout)

    def test_float_timeout_raises_validation_error(self):
        """Float-Timeout (kein Integer) löst ValidationError aus."""
        with pytest.raises(ValidationError):
            validate_timeout_seconds(1800.5)  # type: ignore


# ===========================================================================
# Tests: API-Schlüssel-Validierung
# ===========================================================================

class TestApiKeyValidation:
    """Tests für load_and_validate_api_key."""

    def test_valid_api_key_is_returned(self, monkeypatch):
        """Gültiger API-Schlüssel aus Umgebungsvariable wird zurückgegeben."""
        fake_key = "sk-ant-api03-" + "x" * 30
        monkeypatch.setenv("ANTHROPIC_API_KEY", fake_key)
        result = load_and_validate_api_key("ANTHROPIC")
        assert result == fake_key

    def test_missing_api_key_raises_api_key_error(self, monkeypatch):
        """Fehlende Umgebungsvariable löst ApiKeyError aus."""
        monkeypatch.delenv("ANTHROPIC_API_KEY", raising=False)
        with pytest.raises(ApiKeyError, match="nicht gesetzt"):
            load_and_validate_api_key("ANTHROPIC")

    def test_too_short_api_key_raises_api_key_error(self, monkeypatch):
        """Zu kurzer API-Schlüssel (< 20 Zeichen) löst ApiKeyError aus."""
        monkeypatch.setenv("ANTHROPIC_API_KEY", "short")
        with pytest.raises(ApiKeyError, match="ungültig|kurz"):
            load_and_validate_api_key("ANTHROPIC")


# ===========================================================================
# Tests: File-Change-Detection
# ===========================================================================

class TestFileChangeDetection:
    """Tests für Hash-basierte Änderungserkennung."""

    def test_unchanged_file_is_not_detected_as_changed(self, tmp_path: Path):
        """Unveränderte Datei wird nicht als geändert erkannt."""
        test_file = tmp_path / "script.py"
        test_file.write_text("print('hello')", encoding="utf-8")

        current_hash = compute_file_sha256(test_file)
        hash_cache = {str(test_file): current_hash}

        assert not has_source_file_changed(test_file, hash_cache)

    def test_modified_file_is_detected_as_changed(self, tmp_path: Path):
        """Geänderte Datei wird korrekt als geändert erkannt."""
        test_file = tmp_path / "script.py"
        test_file.write_text("print('hello')", encoding="utf-8")
        old_hash = compute_file_sha256(test_file)

        hash_cache = {str(test_file): old_hash}
        test_file.write_text("print('changed!')", encoding="utf-8")

        assert has_source_file_changed(test_file, hash_cache)

    def test_new_file_without_cached_hash_is_detected_as_changed(self, tmp_path: Path):
        """Datei ohne gespeicherten Hash wird als neu/geändert erkannt."""
        test_file = tmp_path / "new_script.py"
        test_file.write_text("print('new')", encoding="utf-8")
        empty_cache: dict = {}

        assert has_source_file_changed(test_file, empty_cache)

    def test_different_files_produce_different_hashes(self, tmp_path: Path):
        """Verschiedene Dateien haben unterschiedliche SHA-256 Hashes."""
        file_a = tmp_path / "a.py"
        file_b = tmp_path / "b.py"
        file_a.write_text("content A", encoding="utf-8")
        file_b.write_text("content B", encoding="utf-8")

        assert compute_file_sha256(file_a) != compute_file_sha256(file_b)

    def test_identical_content_produces_identical_hash(self, tmp_path: Path):
        """Identischer Inhalt produziert identischen Hash."""
        file_a = tmp_path / "a.py"
        file_b = tmp_path / "b.py"
        identical_content = "identical content"
        file_a.write_text(identical_content, encoding="utf-8")
        file_b.write_text(identical_content, encoding="utf-8")

        assert compute_file_sha256(file_a) == compute_file_sha256(file_b)


# ===========================================================================
# Tests: Atomisches State-File
# ===========================================================================

class TestAtomicStateFile:
    """Tests für atomisches Lesen/Schreiben der State-Datei."""

    def test_state_is_saved_and_loaded_correctly(self, state_file_path: Path):
        """State wird korrekt gespeichert und geladen."""
        test_state = {
            "file_hashes": {"script.py": "abc123"},
            "last_run": "2026-05-26T10:00:00",
        }
        save_abstraction_state_atomically(state_file_path, test_state)
        loaded_state = load_abstraction_state(state_file_path)

        assert loaded_state == test_state

    def test_nonexistent_state_file_returns_empty_dict(self, tmp_path: Path):
        """Fehlende State-Datei gibt leeres Dictionary zurück."""
        nonexistent_path = tmp_path / "nonexistent" / "state.json"
        result = load_abstraction_state(nonexistent_path)
        assert result == {}

    def test_atomic_write_creates_parent_directories(self, tmp_path: Path):
        """Atomisches Schreiben erstellt fehlende Verzeichnisse."""
        deep_path = tmp_path / "a" / "b" / "c" / "state.json"
        save_abstraction_state_atomically(deep_path, {"key": "value"})
        assert deep_path.exists()

    def test_atomic_write_leaves_no_temp_file_on_success(self, tmp_path: Path):
        """Nach erfolgreichem Schreiben gibt es keine .tmp-Datei."""
        state_path = tmp_path / "state.json"
        save_abstraction_state_atomically(state_path, {"data": 1})

        temp_files = list(tmp_path.glob("*.tmp"))
        assert len(temp_files) == 0

    def test_invalid_json_in_state_file_raises_state_file_error(self, tmp_path: Path):
        """Korrupte State-Datei löst StateFileError aus."""
        corrupted_state = tmp_path / "state.json"
        corrupted_state.write_text("{ invalid json !!!", encoding="utf-8")

        with pytest.raises(StateFileError, match="parse"):
            load_abstraction_state(corrupted_state)


# ===========================================================================
# Tests: Sprachzuordnung
# ===========================================================================

class TestLanguageFileExtensions:
    """Tests für die Sprache-zu-Extension-Zuordnung."""

    def test_all_supported_languages_have_file_extensions(self):
        """Jede unterstützte Zielsprache hat eine zugeordnete Datei-Extension."""
        for language in ALLOWED_TARGET_LANGUAGES:
            assert language in LANGUAGE_FILE_EXTENSIONS, (
                f"Fehlende Extension für Sprache: {language}"
            )

    @pytest.mark.parametrize("language, expected_ext", [
        ("perl5",       ".pl"),
        ("perl6",       ".raku"),
        ("javascript",  ".js"),
        ("python",      ".py"),
        ("bash",        ".sh"),
        ("powershell",  ".ps1"),
        ("go",          ".go"),
    ])
    def test_correct_file_extension_per_language(
        self, language: str, expected_ext: str
    ):
        """Korrekte Datei-Extension je Zielsprache."""
        assert LANGUAGE_FILE_EXTENSIONS[language] == expected_ext
