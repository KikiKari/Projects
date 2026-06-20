"""
exceptions.py — Benutzerdefinierte Exceptions für den Abstractions Manager.

Alle anwendungsspezifischen Fehlerklassen sind hier zentral definiert,
um eine einheitliche Fehlerbehandlung in der gesamten Codebasis zu
ermöglichen.

Author: OpenClaw Team
Version: 1.0.0
"""


class AbstractionsManagerError(Exception):
    """Basis-Exception für alle Abstractions-Manager-Fehler.

    Alle anwendungsspezifischen Exceptions erben von dieser Klasse,
    sodass Aufrufer wahlweise spezifische oder alle Anwendungsfehler
    abfangen können.

    Example:
        >>> try:
        ...     run_manager()
        ... except AbstractionsManagerError as e:
        ...     print(f"Anwendungsfehler: {e}")
    """
    pass


class PortationError(AbstractionsManagerError):
    """Wird ausgelöst wenn eine Script-Portierung fehlschlägt.

    Args:
        source_script: Dateiname des Quell-Scripts.
        target_language: Zielsprache der fehlgeschlagenen Portierung.
        original_error: Ursprüngliche Exception, die den Fehler verursacht hat.

    Attributes:
        source_script (str): Name des Quell-Scripts.
        target_language (str): Zielsprache der Portierung.
        original_error (Exception | None): Ursprüngliche Exception.

    Example:
        >>> raise PortationError("db_maintainer.py", "perl5", ValueError("Syntax"))
        PortationError: Portierung fehlgeschlagen: db_maintainer.py → perl5
    """

    def __init__(
        self,
        source_script: str,
        target_language: str,
        original_error: Exception | None = None,
    ) -> None:
        self.source_script = source_script
        self.target_language = target_language
        self.original_error = original_error
        super().__init__(
            f"Portierung fehlgeschlagen: {source_script} → {target_language}"
            + (f": {original_error}" if original_error else "")
        )


class NodeCommunicationError(AbstractionsManagerError):
    """Wird ausgelöst bei Verbindungsproblemen mit Worker-Nodes.

    Args:
        node_identifier: Bezeichnung des betroffenen Nodes (z. B. "Node 2").
        reason: Beschreibung des Verbindungsproblems.

    Attributes:
        node_identifier (str): Bezeichnung des Nodes.
        reason (str): Beschreibung des Problems.

    Example:
        >>> raise NodeCommunicationError("Node 2", "Connection refused")
        NodeCommunicationError: Node 'Node 2' nicht erreichbar: Connection refused
    """

    def __init__(self, node_identifier: str, reason: str) -> None:
        self.node_identifier = node_identifier
        self.reason = reason
        super().__init__(
            f"Node '{node_identifier}' nicht erreichbar: {reason}"
        )


class ValidationError(AbstractionsManagerError):
    """Wird ausgelöst bei ungültigen Eingaben oder Parametern.

    Args:
        field_name: Name des fehlerhaften Feldes oder Parameters.
        invalid_value: Der ungültige Wert (wird für Logging maskiert).
        reason: Beschreibung warum der Wert ungültig ist.

    Attributes:
        field_name (str): Name des Feldes.
        reason (str): Fehlerbeschreibung.

    Example:
        >>> raise ValidationError("--model", "evil_model", "Nicht in Allowlist")
        ValidationError: Ungültiger Wert für '--model': Nicht in Allowlist
    """

    def __init__(
        self,
        field_name: str,
        invalid_value: object,
        reason: str,
    ) -> None:
        self.field_name = field_name
        self.reason = reason
        # Wert wird absichtlich nicht in die Message eingebettet (kein Leak)
        super().__init__(
            f"Ungültiger Wert für '{field_name}': {reason}"
        )


class StateFileError(AbstractionsManagerError):
    """Wird ausgelöst bei Problemen mit der State-Datei.

    Args:
        state_file_path: Pfad zur State-Datei.
        operation: Fehlgeschlagene Operation ("read", "write", "parse").
        original_error: Ursprüngliche Exception.

    Example:
        >>> raise StateFileError("/path/state.json", "write", PermissionError())
        StateFileError: State-Datei-Fehler bei 'write': /path/state.json
    """

    def __init__(
        self,
        state_file_path: str,
        operation: str,
        original_error: Exception | None = None,
    ) -> None:
        self.state_file_path = state_file_path
        self.operation = operation
        self.original_error = original_error
        super().__init__(
            f"State-Datei-Fehler bei '{operation}': {state_file_path}"
            + (f" ({original_error})" if original_error else "")
        )


class ApiKeyError(AbstractionsManagerError):
    """Wird ausgelöst wenn ein API-Schlüssel fehlt oder ungültig ist.

    Args:
        provider_name: Name des KI-Providers (z. B. "ANTHROPIC").
        reason: Beschreibung des Problems.

    Example:
        >>> raise ApiKeyError("ANTHROPIC", "Umgebungsvariable nicht gesetzt")
        ApiKeyError: API-Schlüssel-Fehler für 'ANTHROPIC': Umgebungsvariable nicht gesetzt
    """

    def __init__(self, provider_name: str, reason: str) -> None:
        self.provider_name = provider_name
        self.reason = reason
        super().__init__(
            f"API-Schlüssel-Fehler für '{provider_name}': {reason}"
        )
