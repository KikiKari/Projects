# job_runner.py — Review & Fix Documentation

## Overview

`job_runner.py` is a production cron-job runner that executes a fixed set of
build, test, and lint commands, persists run state to a JSON file, and
commits results to a local Git repository.

---

## Issues Found and Fixed

### 1. Security — `shell=True` in `run_job()`

**Original**
```python
result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
```

**Problem**  
`shell=True` passes the command string to `/bin/sh -c`, which allows shell
metacharacters (`;`, `&&`, `|`, `$()`, etc.) embedded in `cmd` to be
interpreted.  If `cmd` ever contains user-supplied or environment-derived
data, this is a shell-injection vulnerability.

**Fix**  
Split the command string on whitespace and pass a list to `subprocess.run`
with `shell=False` (the default):

```python
result = subprocess.run(
    cmd.split(),
    shell=False,
    capture_output=True,
    text=True,
    timeout=300,
)
```

---

### 2. Security / Correctness — `os.chdir()` in `commit_results()`

**Original**
```python
os.chdir(GIT_REPO)
subprocess.run(["git", "add", "."], check=True)
```

**Problem**  
`os.chdir()` mutates the working directory of the entire process.  In a
cron job (or any long-running process) this is a latent bug: any relative
path used after the `chdir` silently resolves against the new directory.
If `commit_results` raises before the `chdir` completes, subsequent code
runs in an unexpected directory.

**Fix**  
Use the `cwd=` parameter of `subprocess.run`, which scopes the working
directory change to that one child process only:

```python
subprocess.run(["git", "add", "."], cwd=GIT_REPO, check=True, ...)
subprocess.run(["git", "commit", "-m", message], cwd=GIT_REPO, check=True, ...)
```

---

### 3. Error Handling — Bare `except:` clauses

**Original**
```python
except:
    pass          # in load_state(), commit_results(), run_job()
```

**Problem**  
Bare `except:` catches _everything_ including `KeyboardInterrupt`,
`SystemExit`, and programming errors such as `AttributeError`.  Silent
`pass` means failures are invisible — there is no way to know why a job
failed or why the state file could not be read.

**Fix**  
Replace with specific exception types and log each case:

| Location | Exceptions caught | Action |
|---|---|---|
| `load_state` | `json.JSONDecodeError`, `OSError` | Log WARNING, return default state |
| `run_job` | `subprocess.TimeoutExpired`, `FileNotFoundError`, `OSError` | Log ERROR, return `False` |
| `commit_results` | `subprocess.CalledProcessError`, `FileNotFoundError`, `OSError` | Log ERROR, return `False` |
| `main` (save_state) | `OSError` | Log ERROR, continue to exit |

---

### 4. Error Handling — No timeout on subprocess calls

**Original**  
No `timeout=` argument on any `subprocess.run` call.

**Problem**  
A hung child process (e.g. `make build` waiting for user input, or a
network-dependent test suite waiting for a server) blocks the cron job
indefinitely, eventually exhausting cron slots.

**Fix**  
Add `timeout=300` (5 minutes) to `run_job()`.  `commit_results()` uses
`check=True`, so git errors raise `CalledProcessError` immediately.

---

### 5. Logging — Log file opened on every call

**Original**
```python
def log(msg, level="INFO"):
    LOG_DIR.mkdir(exist_ok=True)
    logfile = LOG_DIR / f"{datetime.now().strftime('%Y-%m-%d')}.log"
    with open(logfile, 'a') as f:
        f.write(line + '\n')
```

**Problem**  
- The log directory existence check and an `open()` syscall happen on
  every single log message — unnecessary overhead in a tight loop.
- The custom `log()` function duplicates functionality provided by the
  standard library `logging` module, which handles file rotation, levels,
  formatting, and thread safety.
- The raw `open()` leaves the file descriptor open for the duration of
  the `with` block but not across calls; on a crash between calls the last
  message may not be flushed.

**Fix**  
Replace the custom `log()` function with the standard `logging` module.
A `_build_logger()` factory function opens both handlers **once** at
startup.  All call-sites use `logger.info(...)`, `logger.error(...)`, etc.

```python
logger = _build_logger()   # called once at module import

# usage
logger.info("Runner started")
logger.error("Job '%s' failed (exit %d)", job_name, result.returncode)
```

---

### 6. Resource leak — `open()` without context manager in `load_state()`

**Original**
```python
return json.load(open(STATE_FILE))
```

**Problem**  
The file object returned by `open()` is never explicitly closed.  The
CPython garbage collector will close it eventually, but this is not
guaranteed on other runtimes and may cause issues under resource pressure.

**Fix**
```python
with open(STATE_FILE, encoding="utf-8") as fh:
    return json.load(fh)
```

---

### 7. Correctness — Naive datetime (no timezone)

**Original**
```python
state["last_run"] = datetime.now().isoformat()
```

**Problem**  
`datetime.now()` returns a _naive_ datetime (no timezone info).  When the
cron host's local timezone changes (DST, migration) the timestamps become
ambiguous or incorrect.

**Fix**
```python
state["last_run"] = datetime.now(tz=timezone.utc).isoformat()
```

Produces an unambiguous ISO-8601 string such as
`2026-05-26T14:30:00.123456+00:00`.

---

### 8. Observability — stdout/stderr from failed jobs never recorded

**Original**  
`result.returncode` was logged but `result.stdout` and `result.stderr` were
discarded on failure.

**Fix**  
Log `stdout` and `stderr` at ERROR level when a job fails:

```python
logger.error(
    "Job '%s' failed (exit %d).\nstdout: %s\nstderr: %s",
    job_name, result.returncode,
    result.stdout.strip(), result.stderr.strip(),
)
```

---

### 9. State — Failed job names not recorded

**Original**  
The state file recorded only `last_run` timestamp; there was no record of
which jobs passed or failed.

**Fix**  
The `last_run_summary` key is added to state:

```json
{
  "last_run": "2026-05-26T14:30:00+00:00",
  "last_run_summary": {
    "total": 3,
    "passed": 2,
    "failed": ["lint"]
  }
}
```

---

### 10. Exit code — `main()` always exited 0

**Original**  
`main()` had no return value; `sys.exit()` was not called.

**Fix**  
`main()` returns `int` and `sys.exit(main())` is called so that the cron
scheduler can detect failure:

```python
if __name__ == "__main__":
    sys.exit(main())
```

---

## Summary of All Changes

| # | Category | Change |
|---|---|---|
| 1 | Security | Replaced `shell=True` with `shell=False` + list args in `run_job` |
| 2 | Security / Correctness | Replaced `os.chdir()` with `cwd=` parameter in `commit_results` |
| 3 | Error handling | Replaced bare `except: pass` with specific exception handling + logging |
| 4 | Error handling | Added `timeout=300` to subprocess calls in `run_job` |
| 5 | Logging | Replaced custom `log()` with stdlib `logging`; file opened once at startup |
| 6 | Resource safety | Used context manager for `open()` in `load_state` |
| 7 | Correctness | Used timezone-aware UTC datetime for `last_run` |
| 8 | Observability | Log stdout/stderr of failed jobs |
| 9 | Observability | Record failed job names in persistent state |
| 10 | Correctness | `main()` returns meaningful exit code; `sys.exit(main())` called |

---

## Docstring Coverage

All public functions now carry NumPy-style docstrings with:

- One-line summary sentence.
- Extended description (where relevant).
- `Parameters` section (typed).
- `Returns` section (typed).
- `Raises` section where exceptions propagate to the caller.

The module itself has a top-level docstring describing purpose, usage, and
exit codes.

---

## File Locations

| Path | Description |
|---|---|
| `/home/runner/workspace/logs/YYYY-MM-DD.log` | Daily rotating log file |
| `/home/runner/workspace/job_state.json` | Persistent run state |
| `/home/runner/workspace/output-repo/` | Git repository for committed results |
