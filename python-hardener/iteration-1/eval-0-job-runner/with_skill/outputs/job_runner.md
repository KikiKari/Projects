# job_runner.py

## Overview

`job_runner.py` is a production cron-job runner that sequentially executes a
fixed set of build, test, and lint commands, commits the resulting changes to
a local Git repository, and persists run state to a JSON file.  All operational
output is routed through Python's `logging` module with a rotating file handler
and a console handler configured once at start-up.

---

## Architecture

```
main()
  │
  ├── setup_logging()          — configure RotatingFileHandler + StreamHandler once
  ├── load_state()             — read job_state.json (safe default on failure)
  │
  ├── run_job("build", [...])  ─┐
  ├── run_job("test",  [...])   ├── subprocess.run(cmd, shell=False, cwd unchanged)
  ├── run_job("lint",  [...])  ─┘
  │
  ├── commit_results(msg)      — git -C <repo> add . && git -C <repo> commit -m msg
  └── save_state(state)        — atomic write via tempfile + os.replace()
```

---

## Configuration

All configuration is read from environment variables so deployments can override
defaults without editing the file.

| Variable                  | Default                               | Description                                    |
|---------------------------|---------------------------------------|------------------------------------------------|
| `JOB_RUNNER_WORKSPACE`    | `/home/runner/workspace`              | Root workspace directory                       |
| `JOB_RUNNER_LOG_DIR`      | `$JOB_RUNNER_WORKSPACE/logs`          | Directory for rotating log files               |
| `JOB_RUNNER_GIT_REPO`     | `$JOB_RUNNER_WORKSPACE/output-repo`   | Path to the Git repository for result commits  |
| `LOG_LEVEL`               | `INFO`                                | Python logging level (DEBUG / INFO / WARNING …)|
| `JOB_TIMEOUT_SECONDS`     | `300`                                 | Per-job subprocess timeout in seconds          |

---

## API / Functions

| Function | Signature | Description |
|---|---|---|
| `setup_logging` | `() -> None` | Configures the module logger once with a `RotatingFileHandler` (10 MB / 7 backups) and a `StreamHandler`. Reads level from `LOG_LEVEL`. Idempotent. |
| `load_state` | `() -> dict` | Reads `job_state.json`. Returns `{"jobs": [], "last_run": None}` on missing file or parse error. |
| `save_state` | `(state: dict) -> None` | Serialises `state` to `job_state.json` atomically via `tempfile.mkstemp` + `os.replace`. |
| `run_job` | `(cmd: list[str], job_name: str) -> bool` | Runs `cmd` as a subprocess without a shell. Returns `True` on exit code 0. Handles timeout and OS errors. |
| `commit_results` | `(message: str) -> bool` | Runs `git -C <GIT_REPO> add .` then `git -C <GIT_REPO> commit -m <message>`. Returns `True` on success. |
| `main` | `() -> None` | Orchestrates logging setup, job execution, git commit, and state persistence. |

---

## Security

| Threat | Original code | Countermeasure applied |
|---|---|---|
| **Shell injection** | `subprocess.run(cmd, shell=True)` — an attacker-controlled `cmd` string could execute arbitrary shell syntax | Changed to `shell=False` with `cmd` as a `list[str]`; the shell is never invoked |
| **CWD mutation** | `os.chdir(GIT_REPO)` permanently alters the process working directory, affecting all subsequent relative-path operations | Replaced with `git -C <GIT_REPO> ...`; process CWD is never changed |
| **Path traversal** | Log and state paths were derived from module-level constants without resolution checks | Paths are now resolved from environment variables; `Path.mkdir(parents=True)` is called only inside functions, not at import time |
| **Secrets in code** | None in original; paths were hardcoded | Paths externalised to environment variables so sensitive deployment details are not committed |

---

## Error handling

| Function | Exception caught | Behaviour on failure |
|---|---|---|
| `load_state` | `json.JSONDecodeError` | Logs a warning with the error detail; returns safe default state |
| `load_state` | `OSError` | Logs a warning with the error detail; returns safe default state |
| `save_state` | `OSError` | Cleans up the temporary file; re-raises so the caller can decide |
| `run_job` | `subprocess.TimeoutExpired` | Logs error with timeout duration; returns `False` |
| `run_job` | `subprocess.SubprocessError` | Logs error with `exc_info=True`; returns `False` |
| `run_job` | `OSError` | Logs error with `exc_info=True`; returns `False` |
| `commit_results` | `subprocess.CalledProcessError` | Logs rc, command, stdout and stderr; returns `False` |
| `commit_results` | `OSError` | Logs error with `exc_info=True`; returns `False` |
| `main` | `OSError` (from `save_state`) | Logs error; script continues and exits normally |

---

## Changes from the original

| # | Category | Original | Fixed |
|---|---|---|---|
| 1 | Resource management | `log()` opened the log file on every call | `setup_logging()` configures `RotatingFileHandler` once; no per-call file open |
| 2 | Security / CWD | `os.chdir(GIT_REPO)` mutated process CWD | `git -C <GIT_REPO>` used; CWD never changed |
| 3 | Security / shell injection | `subprocess.run(cmd, shell=True)` | `subprocess.run(cmd, shell=False)` with `cmd` as a list |
| 4 | Error handling | Bare `except:` in `load_state`, `run_job`, `commit_results` | Replaced with specific exception types + logged errors |
| 5 | Error handling | Silent `pass` in `commit_results` hid all git failures | Returns `bool`; all failures are logged with details |
| 6 | Resource management | `json.load(open(STATE_FILE))` — file handle never closed | Wrapped in `with open(...) as fh:` |
| 7 | Reliability | `save_state` wrote directly — torn writes possible | Atomic write via `tempfile.mkstemp` + `os.replace` |
| 8 | Module-level side effects | `LOG_DIR.mkdir()` called inside `log()` on every invocation | Called once inside `setup_logging()` |
| 9 | Docstrings | None | Google-style docstrings on every public function |
| 10 | Type hints | None | Added to all function signatures |
| 11 | Configuration | Paths hardcoded | Externalised to environment variables with sensible defaults |
