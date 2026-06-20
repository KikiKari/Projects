#!/usr/bin/env python3
"""
report_db.py — Hardened database reporting module.

Exports tables from a SQLite reports database to CSV or JSON.
All SQL injection vectors are closed, connections are managed via context
managers, and errors are logged rather than swallowed.
"""

import csv
import json
import logging
import logging.handlers
import os
import sqlite3
import tempfile
from contextlib import contextmanager
from pathlib import Path
from typing import Generator, List, Optional

DB_PATH = Path("/var/data/reports.db")
EXPORT_DIR = Path("/var/data/exports")

ALLOWED_TABLES = frozenset({"reports", "users", "audit_log"})

logger = logging.getLogger(__name__)


def setup_logging() -> None:
    """
    Configure application-wide logging.

    Reads LOG_LEVEL from the environment (default: INFO).  Attaches a
    RotatingFileHandler (10 MB / 7 backups) and a StreamHandler so output
    goes to both a file and the console.  Safe to call multiple times —
    subsequent calls are no-ops if handlers are already present.
    """
    if logger.handlers:
        return

    level_name = os.environ.get("LOG_LEVEL", "INFO").upper()
    level = getattr(logging, level_name, logging.INFO)
    logger.setLevel(level)

    formatter = logging.Formatter(
        "%(asctime)s %(levelname)-8s %(name)s — %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S",
    )

    log_file = Path("/var/log/report_db.log")
    try:
        file_handler = logging.handlers.RotatingFileHandler(
            log_file, maxBytes=10 * 1024 * 1024, backupCount=7
        )
        file_handler.setFormatter(formatter)
        logger.addHandler(file_handler)
    except OSError as exc:
        # If the log directory is not writable, fall back to console-only.
        logging.warning("Cannot open log file %s: %s", log_file, exc)

    console_handler = logging.StreamHandler()
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)


@contextmanager
def get_connection(db_path: Path) -> Generator[sqlite3.Connection, None, None]:
    """
    Yield an open SQLite connection and close it on exit.

    Args:
        db_path: Filesystem path to the SQLite database file.

    Yields:
        An open :class:`sqlite3.Connection` with ``row_factory`` set to
        :data:`sqlite3.Row`.

    Raises:
        sqlite3.Error: If the database cannot be opened.
    """
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()


class ReportDatabase:
    """
    High-level interface for the reports SQLite database.

    All database access is performed through :func:`get_connection` so
    connections are never leaked.  Table names are validated against
    :data:`ALLOWED_TABLES` before being interpolated into SQL; query
    values are always passed via parameterised queries.

    Args:
        db_path: Path to the SQLite database file.
        export_dir: Directory where exported files are written.
    """

    def __init__(
        self,
        db_path: Path = DB_PATH,
        export_dir: Path = EXPORT_DIR,
    ) -> None:
        """
        Initialise ReportDatabase.

        Args:
            db_path: Path to the SQLite database file.  Defaults to
                :data:`DB_PATH`.
            export_dir: Directory that will receive exported files.
                Created automatically if it does not exist.  Defaults
                to :data:`EXPORT_DIR`.
        """
        self.db_path = db_path
        self.export_dir = export_dir

    def _validate_table(self, table_name: str) -> None:
        """
        Raise ValueError if *table_name* is not in the allowlist.

        Args:
            table_name: The table name to validate.

        Raises:
            ValueError: If *table_name* is not in :data:`ALLOWED_TABLES`.
        """
        if table_name not in ALLOWED_TABLES:
            raise ValueError(
                f"Table '{table_name}' is not in the allowlist "
                f"{sorted(ALLOWED_TABLES)}."
            )

    def get_table(self, table_name: str) -> List[sqlite3.Row]:
        """
        Return all rows from *table_name*.

        Args:
            table_name: Name of the table to query.  Must be present in
                :data:`ALLOWED_TABLES`.

        Returns:
            A list of :class:`sqlite3.Row` objects (may be empty).

        Raises:
            ValueError: If *table_name* is not in the allowlist.
            sqlite3.Error: On database errors.
        """
        self._validate_table(table_name)
        # Table name has been validated against an allowlist — safe to
        # interpolate.  Values are never interpolated this way.
        sql = f"SELECT * FROM {table_name}"  # nosec B608
        with get_connection(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(sql)
            return cursor.fetchall()

    def search_reports(self, status: str, owner: str) -> List[sqlite3.Row]:
        """
        Return reports matching *status* and *owner*.

        Args:
            status: Report status string to filter by.
            owner: Owner name to filter by.

        Returns:
            A list of matching :class:`sqlite3.Row` objects (may be empty).

        Raises:
            sqlite3.Error: On database errors.
        """
        sql = "SELECT * FROM reports WHERE status = ? AND owner = ?"
        with get_connection(self.db_path) as conn:
            cursor = conn.cursor()
            cursor.execute(sql, (status, owner))
            return cursor.fetchall()

    def export_table(
        self, table_name: str, fmt: str = "csv"
    ) -> Optional[Path]:
        """
        Export a table to a file and return its path.

        Files are written atomically: data is first written to a
        temporary file in :attr:`export_dir`, then renamed into place
        with :func:`os.replace` so a crash mid-write never leaves a
        partial file.

        Args:
            table_name: Table to export.  Must be in :data:`ALLOWED_TABLES`.
            fmt: Output format — ``"csv"`` (default) or ``"json"``.

        Returns:
            :class:`~pathlib.Path` to the written file, or ``None`` if the
            table is empty.

        Raises:
            ValueError: If *table_name* is not in the allowlist, or if
                *fmt* is not ``"csv"`` or ``"json"``.
            sqlite3.Error: On database read errors.
            OSError: If the export directory cannot be created or the
                file cannot be written.
        """
        if fmt not in {"csv", "json"}:
            raise ValueError(f"Unsupported format '{fmt}'. Use 'csv' or 'json'.")

        data = self.get_table(table_name)
        if not data:
            logger.info("Table '%s' is empty — skipping export.", table_name)
            return None

        self.export_dir.mkdir(parents=True, exist_ok=True)
        out_path = self.export_dir / f"{table_name}.{fmt}"

        # Atomic write: write to a temp file, then rename.
        fd, tmp_path = tempfile.mkstemp(
            dir=self.export_dir, prefix=f".{table_name}_", suffix=f".{fmt}"
        )
        try:
            with os.fdopen(fd, "w", newline="" if fmt == "csv" else "\n") as fh:
                if fmt == "csv":
                    writer = csv.writer(fh)
                    writer.writerow(data[0].keys())
                    writer.writerows([tuple(row) for row in data])
                else:
                    json.dump([dict(row) for row in data], fh, indent=2)
            os.replace(tmp_path, out_path)
        except OSError:
            logger.error(
                "Failed to write export for table '%s'.", table_name, exc_info=True
            )
            try:
                os.unlink(tmp_path)
            except OSError:
                pass
            raise

        logger.info("Exported '%s' to %s", table_name, out_path)
        return out_path

    def run_custom(self, raw_sql: str) -> None:
        """
        Execute arbitrary SQL and commit the transaction.

        .. warning::
            This method accepts a raw SQL string.  The caller is
            responsible for ensuring the input is trusted and does not
            contain user-supplied data.

        Args:
            raw_sql: SQL statement to execute.

        Raises:
            sqlite3.Error: If execution or commit fails.
        """
        with get_connection(self.db_path) as conn:
            try:
                cursor = conn.cursor()
                cursor.execute(raw_sql)
                conn.commit()
                logger.debug("run_custom executed successfully.")
            except sqlite3.Error:
                logger.error(
                    "run_custom failed for SQL: %.200s", raw_sql, exc_info=True
                )
                raise


def main() -> None:
    """
    Entry point: export all known tables to CSV.

    Creates the export directory if it does not exist, instantiates
    :class:`ReportDatabase`, and iterates over :data:`ALLOWED_TABLES`.
    Errors for individual tables are logged and execution continues so
    that one failing table does not abort the others.
    """
    setup_logging()
    db = ReportDatabase()
    for table in sorted(ALLOWED_TABLES):
        try:
            path = db.export_table(table)
            if path:
                logger.info("Exported %s -> %s", table, path)
        except (ValueError, sqlite3.Error, OSError):
            logger.error("Could not export table '%s'.", table, exc_info=True)


if __name__ == "__main__":
    main()
