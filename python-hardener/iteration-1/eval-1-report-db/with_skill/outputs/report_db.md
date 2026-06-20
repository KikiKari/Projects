# report_db

## Overview

`report_db.py` exports tables from a SQLite reports database to CSV or JSON
files.  The module defines a `ReportDatabase` class whose methods validate
table names against a fixed allowlist, pass query values through parameterised
queries, write output files atomically, and log all operations through
Python's standard `logging` module.  A `main()` entry point iterates over all
known tables and exports each one, continuing past individual failures so a
single bad table does not abort the run.

---

## Architecture

```
┌─────────────────────────────────────────────────┐
│                    main()                        │
│  iterates ALLOWED_TABLES, calls export_table()  │
└───────────────────┬─────────────────────────────┘
                    │
        ┌───────────▼────────────┐
        │     ReportDatabase     │
        │  ┌──────────────────┐  │
        │  │  _validate_table │  │  allowlist guard
        │  ├──────────────────┤  │
        │  │    get_table     │  │  SELECT * (table allowlisted)
        │  ├──────────────────┤  │
        │  │  search_reports  │  │  parameterised WHERE
        │  ├──────────────────┤  │
        │  │  export_table    │  │  atomic CSV / JSON write
        │  ├──────────────────┤  │
        │  │   run_custom     │  │  trusted SQL execution
        │  └──────────────────┘  │
        └───────────┬────────────┘
                    │
        ┌───────────▼────────────┐
        │   get_connection()     │  @contextmanager — always closes conn
        └───────────┬────────────┘
                    │
            SQLite on disk
           /var/data/reports.db
```

---

## Configuration

| Environment variable | Default | Description |
|---|---|---|
| `LOG_LEVEL` | `INFO` | Python log level name (`DEBUG`, `INFO`, `WARNING`, `ERROR`, `CRITICAL`). |

The log file path is hard-coded to `/var/log/report_db.log` with a
`RotatingFileHandler` (10 MB per file, 7 backups).  If that path is not
writable the module falls back to console-only logging.

Database and export paths can be overridden at `ReportDatabase.__init__` time
using the `db_path` and `export_dir` keyword arguments.

---

## API / Functions

### Module-level

| Name | Signature | Description |
|---|---|---|
| `setup_logging` | `() -> None` | Configures the module logger once with a `RotatingFileHandler` and a `StreamHandler`. Idempotent. |
| `get_connection` | `(db_path: Path) -> Generator[sqlite3.Connection, None, None]` | Context manager: opens the database, yields the connection, always closes on exit. |
| `main` | `() -> None` | Entry point: calls `setup_logging()`, instantiates `ReportDatabase`, and exports all tables in `ALLOWED_TABLES`. |

### `ReportDatabase`

| Method | Signature | Description |
|---|---|---|
| `__init__` | `(db_path=DB_PATH, export_dir=EXPORT_DIR) -> None` | Stores paths; does **not** open a connection. |
| `_validate_table` | `(table_name: str) -> None` | Raises `ValueError` if `table_name` is not in `ALLOWED_TABLES`. |
| `get_table` | `(table_name: str) -> List[sqlite3.Row]` | Returns all rows from an allowlisted table. |
| `search_reports` | `(status: str, owner: str) -> List[sqlite3.Row]` | Parameterised query against `reports` filtered by status and owner. |
| `export_table` | `(table_name: str, fmt: str = "csv") -> Optional[Path]` | Exports table to CSV or JSON using an atomic temp-file write. Returns the output path, or `None` if the table is empty. |
| `run_custom` | `(raw_sql: str) -> None` | Executes trusted raw SQL and commits. Logs and re-raises on error. |

---

## Security

| Threat | Location in original | Countermeasure applied |
|---|---|---|
| **SQL injection via table name** | `get_table`: `f"SELECT * FROM {table_name}"` | Table name validated against `ALLOWED_TABLES` frozenset before interpolation. |
| **SQL injection via user values** | `search_reports`: f-string with `status` and `user_input` in WHERE clause | Replaced with a parameterised query (`?` placeholders). |
| **DB connection never closed** | `__init__` opened `self.conn`; no `close()` anywhere | All access flows through the `get_connection()` context manager which calls `conn.close()` in `finally`. |
| **Module-level side effect** | `EXPORT_DIR.mkdir(exist_ok=True)` at import time | Moved into `export_table()` (called only when actually exporting) and `main()`. |
| **Torn / partial export files** | Direct `open()` write to final path | Atomic write: `tempfile.mkstemp()` then `os.replace()`. |

---

## Error handling

| Function | Exception(s) handled | Behaviour on failure |
|---|---|---|
| `setup_logging` | `OSError` (log file open) | Falls back to console-only; logs a warning. |
| `get_connection` | — (callers handle `sqlite3.Error`) | Ensures `conn.close()` is always called via `finally`. |
| `ReportDatabase._validate_table` | Raises `ValueError` for unknown tables | Propagates to caller; prevents malicious or typo'd table names from reaching the DB. |
| `ReportDatabase.get_table` | `sqlite3.Error` | Propagates to caller with full traceback available. |
| `ReportDatabase.search_reports` | `sqlite3.Error` | Propagates to caller. |
| `ReportDatabase.export_table` | `OSError` on write | Logs error with `exc_info=True`, removes the temp file, re-raises. Cleans up the partial temp file. |
| `ReportDatabase.run_custom` | `sqlite3.Error` | Logs error with `exc_info=True` and re-raises. |
| `main` | `ValueError`, `sqlite3.Error`, `OSError` | Logs the error with `exc_info=True` and continues to the next table so one failure does not abort the run. |
