#!/usr/bin/env python3
"""
report_db.py

Provides the ReportDatabase class for querying, searching, and exporting
data from an SQLite reports database. Includes safe parameterised queries
and proper resource management.
"""

import sqlite3
import json
import csv
import logging
from pathlib import Path

DB_PATH = Path("/var/data/reports.db")
EXPORT_DIR = Path("/var/data/exports")

logger = logging.getLogger(__name__)

# Allowlist of table names that callers may access.
ALLOWED_TABLES = {"reports", "users", "audit_log"}


class ReportDatabaseError(Exception):
    """Raised for expected errors originating from ReportDatabase operations."""


class ReportDatabase:
    """Manages read and export operations against the SQLite reports database.

    The connection is opened lazily on first use and must be closed explicitly
    by calling :meth:`close`, or by using the instance as a context manager::

        with ReportDatabase() as db:
            rows = db.search_reports("open", "alice")

    Attributes:
        db_path: Path to the SQLite database file.
        export_dir: Directory where exported files are written.
    """

    def __init__(self, db_path: Path = DB_PATH, export_dir: Path = EXPORT_DIR) -> None:
        """Initialise the ReportDatabase.

        Args:
            db_path: Filesystem path to the SQLite database.  Defaults to
                ``/var/data/reports.db``.
            export_dir: Directory used for exported CSV/JSON files.  The
                directory is created if it does not already exist.  Defaults to
                ``/var/data/exports``.

        Raises:
            ReportDatabaseError: If the database cannot be opened or the export
                directory cannot be created.
        """
        self.db_path = db_path
        self.export_dir = export_dir
        try:
            self.export_dir.mkdir(parents=True, exist_ok=True)
        except OSError as exc:
            raise ReportDatabaseError(
                f"Cannot create export directory '{export_dir}': {exc}"
            ) from exc
        try:
            self.conn = sqlite3.connect(self.db_path)
            self.conn.row_factory = sqlite3.Row
        except sqlite3.Error as exc:
            raise ReportDatabaseError(
                f"Cannot open database '{db_path}': {exc}"
            ) from exc

    # ------------------------------------------------------------------
    # Context-manager support
    # ------------------------------------------------------------------

    def __enter__(self) -> "ReportDatabase":
        """Return self to support use as a context manager."""
        return self

    def __exit__(self, exc_type, exc_val, exc_tb) -> None:
        """Close the database connection on context-manager exit."""
        self.close()

    def close(self) -> None:
        """Close the underlying database connection.

        Safe to call multiple times; subsequent calls after the first are
        no-ops.
        """
        if self.conn is not None:
            try:
                self.conn.close()
            except sqlite3.Error as exc:
                logger.warning("Error while closing database connection: %s", exc)
            finally:
                self.conn = None

    # ------------------------------------------------------------------
    # Query helpers
    # ------------------------------------------------------------------

    @staticmethod
    def _validate_table_name(table_name: str) -> None:
        """Raise ValueError if *table_name* is not in the allowlist.

        SQLite does not support parameterised table-name substitution, so we
        validate against a fixed allowlist instead of interpolating the name
        directly into the SQL string.

        Args:
            table_name: The table name to validate.

        Raises:
            ValueError: If *table_name* is not in :data:`ALLOWED_TABLES`.
        """
        if table_name not in ALLOWED_TABLES:
            raise ValueError(
                f"Table '{table_name}' is not in the allowed list: {sorted(ALLOWED_TABLES)}"
            )

    def get_table(self, table_name: str) -> list:
        """Return all rows from *table_name*.

        Args:
            table_name: Name of the table to read.  Must be one of
                :data:`ALLOWED_TABLES`.

        Returns:
            A list of :class:`sqlite3.Row` objects (empty list if the table
            has no rows).

        Raises:
            ValueError: If *table_name* is not allowlisted.
            ReportDatabaseError: If the query fails.
        """
        self._validate_table_name(table_name)
        # Table name has been validated against an allowlist; safe to embed.
        sql = f"SELECT * FROM {table_name}"  # noqa: S608 – allowlist-validated above
        try:
            cursor = self.conn.cursor()
            cursor.execute(sql)
            return cursor.fetchall()
        except sqlite3.Error as exc:
            raise ReportDatabaseError(
                f"Failed to read table '{table_name}': {exc}"
            ) from exc

    def search_reports(self, status: str, owner: str) -> list:
        """Search the *reports* table by status and owner using parameterised queries.

        Args:
            status: The report status to filter on (e.g. ``"open"``).
            owner: The owner/username to filter on.

        Returns:
            A list of matching :class:`sqlite3.Row` objects.

        Raises:
            ReportDatabaseError: If the query fails.
        """
        sql = "SELECT * FROM reports WHERE status = ? AND owner = ?"
        try:
            cursor = self.conn.cursor()
            cursor.execute(sql, (status, owner))
            return cursor.fetchall()
        except sqlite3.Error as exc:
            raise ReportDatabaseError(
                f"Failed to search reports (status={status!r}, owner={owner!r}): {exc}"
            ) from exc

    # ------------------------------------------------------------------
    # Export helpers
    # ------------------------------------------------------------------

    def export_table(self, table_name: str, fmt: str = "csv") -> Path | None:
        """Export *table_name* to a file in the export directory.

        Args:
            table_name: Name of the table to export.  Must be one of
                :data:`ALLOWED_TABLES`.
            fmt: Output format – either ``"csv"`` (default) or ``"json"``.

        Returns:
            The :class:`~pathlib.Path` of the written file, or ``None`` if the
            table contains no rows.

        Raises:
            ValueError: If *table_name* is not allowlisted or *fmt* is unknown.
            ReportDatabaseError: If the query or file-write fails.
        """
        if fmt not in {"csv", "json"}:
            raise ValueError(f"Unsupported export format '{fmt}'. Use 'csv' or 'json'.")

        data = self.get_table(table_name)
        if not data:
            logger.info("Table '%s' is empty; skipping export.", table_name)
            return None

        out_path = self.export_dir / f"{table_name}.{fmt}"
        try:
            if fmt == "csv":
                with open(out_path, "w", newline="", encoding="utf-8") as fh:
                    writer = csv.writer(fh)
                    writer.writerow(data[0].keys())   # header row
                    writer.writerows(data)
            else:  # json
                with open(out_path, "w", encoding="utf-8") as fh:
                    json.dump([dict(row) for row in data], fh, indent=2)
        except OSError as exc:
            raise ReportDatabaseError(
                f"Failed to write export file '{out_path}': {exc}"
            ) from exc

        logger.info("Exported '%s' to '%s'.", table_name, out_path)
        return out_path

    def run_custom(self, raw_sql: str) -> list:
        """Execute a caller-supplied SQL statement and return any result rows.

        .. warning::
            This method executes arbitrary SQL.  Only call it with trusted,
            internally-generated queries.  Never pass user-supplied input
            directly to this method.

        Args:
            raw_sql: A complete SQL statement to execute.

        Returns:
            A list of :class:`sqlite3.Row` objects (may be empty for
            non-SELECT statements).

        Raises:
            ReportDatabaseError: If execution fails.
        """
        try:
            cursor = self.conn.cursor()
            cursor.execute(raw_sql)
            self.conn.commit()
            return cursor.fetchall()
        except sqlite3.Error as exc:
            raise ReportDatabaseError(
                f"Failed to execute custom SQL: {exc}"
            ) from exc


def main() -> None:
    """Export all standard tables to CSV files and print the output paths."""
    tables = list(ALLOWED_TABLES)
    try:
        with ReportDatabase() as db:
            for table in tables:
                try:
                    path = db.export_table(table)
                    if path:
                        print(f"Exported {table}: {path}")
                    else:
                        print(f"Skipped {table}: no rows found.")
                except (ReportDatabaseError, ValueError) as exc:
                    logger.error("Could not export table '%s': %s", table, exc)
    except ReportDatabaseError as exc:
        logger.critical("Database initialisation failed: %s", exc)
        raise SystemExit(1) from exc


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
    main()
