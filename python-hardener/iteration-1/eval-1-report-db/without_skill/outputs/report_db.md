# report_db.py — Code Review & Changes

## Overview

`report_db.py` provides the `ReportDatabase` class for querying, exporting, and managing data stored in an SQLite reports database.  The file was reviewed and hardened in the following four areas:

1. SQL injection vulnerabilities
2. Bare `except` clauses
3. Database connection lifecycle
4. Missing docstrings

---

## Issues Found and Fixed

### 1. SQL Injection

**Original problems**

| Method | Issue |
|---|---|
| `get_table` | Table name embedded directly via f-string: `f"SELECT * FROM {table_name}"` |
| `search_reports` | Both `status` and `user_input` interpolated via f-string into the WHERE clause |

**Fixes applied**

- `get_table` — A static `_validate_table_name` helper now checks the supplied name against an explicit allowlist (`ALLOWED_TABLES`).  SQLite does not support parameterised identifier substitution, so allowlist validation is the correct mitigation here.  Any name not in the set raises `ValueError` before the query is built.
- `search_reports` — Rewritten to use a parameterised query (`?` placeholders) so user-supplied values are never concatenated into SQL:

  ```python
  # Before (vulnerable)
  query = f"SELECT * FROM reports WHERE status = '{status}' AND owner = '{user_input}'"

  # After (safe)
  sql = "SELECT * FROM reports WHERE status = ? AND owner = ?"
  cursor.execute(sql, (status, owner))
  ```

---

### 2. Bare `except` Clauses

**Original problem**

`run_custom` used a bare `except: pass`, which silently swallowed every possible exception including `KeyboardInterrupt`, `SystemExit`, and programming errors:

```python
try:
    cursor = self.conn.cursor()
    cursor.execute(raw_sql)
    self.conn.commit()
except:          # bare except – catches everything, including KeyboardInterrupt
    pass         # silent failure – no logging, no re-raise
```

**Fix applied**

Replaced with a specific `except sqlite3.Error` that re-raises as the module's own `ReportDatabaseError`, preserving the original cause via `raise ... from exc`:

```python
except sqlite3.Error as exc:
    raise ReportDatabaseError(
        f"Failed to execute custom SQL: {exc}"
    ) from exc
```

The same pattern was applied consistently to all other `try/except` blocks in the class.

---

### 3. Database Connection Not Closed

**Original problem**

`ReportDatabase.__init__` opened a connection that was never closed.  In `main()` the `db` object went out of scope without an explicit `close()`, relying on the garbage collector to flush any pending writes — which is not guaranteed, especially in CPython with reference cycles or in other Python implementations.

**Fix applied**

- Added a `close()` method that safely shuts the connection and sets `self.conn = None` (idempotent on repeated calls).
- Implemented `__enter__` / `__exit__` so the class can be used as a context manager.
- Updated `main()` to use `with ReportDatabase() as db:` so the connection is always closed, even if an exception is raised mid-loop.

```python
# Before
def main():
    db = ReportDatabase()
    for t in tables:
        path = db.export_table(t)   # connection never explicitly closed

# After
def main():
    with ReportDatabase() as db:    # __exit__ calls close() unconditionally
        for table in tables:
            ...
```

---

### 4. Missing Docstrings

No docstrings were present on the module, class, or any method.

**Fix applied**

Added Google-style docstrings to:

| Target | Content |
|---|---|
| Module | High-level purpose, usage note |
| `ReportDatabase` | Class purpose, attributes, context-manager usage example |
| `__init__` | Parameters, raises |
| `__enter__` / `__exit__` | Brief description |
| `close` | Behaviour, idempotency note |
| `_validate_table_name` | Why an allowlist is used instead of parameters, raises |
| `get_table` | Args, returns, raises |
| `search_reports` | Args, returns, raises |
| `export_table` | Args, returns, raises |
| `run_custom` | Security warning, args, returns, raises |
| `main` | One-line summary |

---

## Additional Improvements

| Area | Change |
|---|---|
| Custom exception class | `ReportDatabaseError(Exception)` added so callers can distinguish expected database errors from programming errors |
| Export format validation | `export_table` now raises `ValueError` immediately for unknown `fmt` values instead of silently returning `None` |
| CSV header row | The exported CSV now includes a header row derived from `sqlite3.Row.keys()` |
| Encoding | File opens now specify `encoding="utf-8"` explicitly |
| Logging | `logging` replaces bare `print` for diagnostic messages; `main()` configures `basicConfig` when run as a script |
| `EXPORT_DIR` side-effect | Directory creation moved from module level into `__init__` to avoid side-effects on import |

---

## Summary of All Changes

```
report_db.py
├── Module docstring added
├── ALLOWED_TABLES constant introduced
├── ReportDatabaseError custom exception added
├── ReportDatabase
│   ├── __init__: export_dir.mkdir moved here; sqlite3.Error caught; docstring added
│   ├── __enter__ / __exit__ added (context-manager support)
│   ├── close() added
│   ├── _validate_table_name() added (SQL injection mitigation for table names)
│   ├── get_table: uses _validate_table_name; sqlite3.Error caught; docstring added
│   ├── search_reports: parameterised query replaces f-string; docstring added
│   ├── export_table: format validated; OSError caught; header row added; docstring added
│   └── run_custom: bare except replaced; result rows returned; docstring + warning added
└── main: uses context manager; per-table errors caught and logged
```
