#!/usr/bin/env python3
"""job_runner.py — Production cron-job runner.

Runs a fixed set of build/test/lint jobs, records their outcomes in a
persistent JSON state file, and commits the results to a local Git
repository.

Typical usage (from cron)::

    /usr/bin/python3 /opt/scripts/job_runner.py

Exit codes:
    0  All jobs passed and state was saved successfully.
    1  One or more jobs failed (logged; script still exits cleanly so cron
       does not flood the operator with "command failed" e-mails — see the
       log for details).
"""

import json
import logging
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

WORKSPACE: Path = Path("/home/runner/workspace")
STATE_FILE: Path = WORKSPACE / "job_state.json"
LOG_DIR: Path = WORKSPACE / "logs"
GIT_REPO: Path = WORKSPACE / "output-repo"

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------


def _build_logger() -> logging.Logger:
    """Create and configure the module-level logger.

    Writes to both *stdout* and a date-stamped file under ``LOG_DIR``.
    The log directory is created once at startup so that the ``log()``
    helper does not need to touch the filesystem on every call.

    Returns
    -------
    logging.Logger
        Configured logger instance named ``job_runner``.
    """
    LOG_DIR.mkdir(parents=True, exist_ok=True)

    logger = logging.getLogger("job_runner")
    logger.setLevel(logging.DEBUG)

    formatter = logging.Formatter(
        fmt="[%(asctime)s] [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )

    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    # File handler — one file per calendar day
    log_path = LOG_DIR / f"{datetime.now().strftime('%Y-%m-%d')}.log"
    file_handler = logging.FileHandler(log_path, encoding="utf-8")
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    return logger


logger = _build_logger()

# ---------------------------------------------------------------------------
# State helpers
# ---------------------------------------------------------------------------


def load_state() -> dict:
    """Load the persistent job state from ``STATE_FILE``.

    If the file does not exist or contains invalid JSON, a default empty
    state is returned and the error is logged at WARNING level so that the
    runner can still proceed.

    Returns
    -------
    dict
        Mapping with at least the keys ``"jobs"`` (list) and
        ``"last_run"`` (str | None).
    """
    if STATE_FILE.exists():
        try:
            with open(STATE_FILE, encoding="utf-8") as fh:
                return json.load(fh)
        except json.JSONDecodeError as exc:
            logger.warning("State file is corrupt, starting fresh: %s", exc)
        except OSError as exc:
            logger.warning("Could not read state file: %s", exc)

    return {"jobs": [], "last_run": None}


def save_state(state: dict) -> None:
    """Persist *state* to ``STATE_FILE`` as formatted JSON.

    Parameters
    ----------
    state:
        The state dictionary to serialise.

    Raises
    ------
    OSError
        Propagated if the file cannot be written; the caller logs this.
    """
    with open(STATE_FILE, "w", encoding="utf-8") as fh:
        json.dump(state, fh, indent=2)

# ---------------------------------------------------------------------------
# Job execution
# ---------------------------------------------------------------------------


def run_job(cmd: str, job_name: str) -> bool:
    """Execute a shell command and return whether it succeeded.

    The command string is split on whitespace and executed without
    ``shell=True`` to avoid shell-injection vulnerabilities.  If you need
    shell features (pipes, redirects) pass the tokens as a list directly.
    Never pass untrusted input to ``shell=True``.

    Parameters
    ----------
    cmd:
        The command string to run (e.g. ``"make build"``).  It is split on
        whitespace; avoid embedding shell metacharacters.
    job_name:
        Human-readable name used in log messages.

    Returns
    -------
    bool
        ``True`` if the process exited with code 0, ``False`` otherwise.
    """
    logger.info("Starting job '%s': %s", job_name, cmd)
    try:
        result = subprocess.run(
            cmd.split(),
            shell=False,          # avoids shell-injection risk
            capture_output=True,
            text=True,
            timeout=300,          # prevent hung jobs from blocking the cron
        )
        if result.returncode == 0:
            logger.info("Job '%s' finished successfully (exit 0)", job_name)
        else:
            logger.error(
                "Job '%s' failed (exit %d).\nstdout: %s\nstderr: %s",
                job_name,
                result.returncode,
                result.stdout.strip(),
                result.stderr.strip(),
            )
        return result.returncode == 0
    except subprocess.TimeoutExpired:
        logger.error("Job '%s' timed out after 300 s", job_name)
        return False
    except FileNotFoundError:
        logger.error("Job '%s': command not found — %s", job_name, cmd.split()[0])
        return False
    except OSError as exc:
        logger.error("Job '%s' could not be started: %s", job_name, exc)
        return False

# ---------------------------------------------------------------------------
# Git helpers
# ---------------------------------------------------------------------------


def commit_results(message: str) -> bool:
    """Stage all changes in ``GIT_REPO`` and create a commit.

    Uses ``cwd=`` on each :func:`subprocess.run` call instead of
    ``os.chdir()`` so the process working-directory is never mutated
    (mutation of the working directory is a source of hard-to-debug bugs
    in long-running processes and cron jobs).

    Parameters
    ----------
    message:
        Git commit message.  Must not be empty.

    Returns
    -------
    bool
        ``True`` if the commit was created successfully, ``False`` on any
        error (the error is logged at ERROR level).
    """
    if not message:
        logger.error("commit_results: commit message must not be empty")
        return False

    if not GIT_REPO.is_dir():
        logger.error("Git repo directory does not exist: %s", GIT_REPO)
        return False

    try:
        subprocess.run(
            ["git", "add", "."],
            cwd=GIT_REPO,
            check=True,
            capture_output=True,
            text=True,
        )
        subprocess.run(
            ["git", "commit", "-m", message],
            cwd=GIT_REPO,
            check=True,
            capture_output=True,
            text=True,
        )
        logger.info("Git commit created: %s", message)
        return True
    except subprocess.CalledProcessError as exc:
        logger.error(
            "Git command failed (exit %d): %s\nstderr: %s",
            exc.returncode,
            exc.cmd,
            exc.stderr.strip() if exc.stderr else "",
        )
        return False
    except FileNotFoundError:
        logger.error("'git' executable not found on PATH")
        return False
    except OSError as exc:
        logger.error("Unexpected OS error during git commit: %s", exc)
        return False

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main() -> int:
    """Orchestrate job execution, state persistence, and git commit.

    Defines the list of jobs to run, executes each in order, commits the
    aggregate result to the output repository, and updates the persistent
    state file.

    Returns
    -------
    int
        ``0`` if all jobs passed; ``1`` if one or more jobs failed.
    """
    logger.info("Runner started")
    state = load_state()

    jobs: list[tuple[str, str]] = [
        ("build", "make build"),
        ("test",  "make test"),
        ("lint",  "flake8 ."),
    ]

    success = 0
    failed_jobs: list[str] = []

    for name, cmd in jobs:
        if run_job(cmd, name):
            success += 1
        else:
            failed_jobs.append(name)

    commit_results(f"Run: {success}/{len(jobs)} jobs passed")

    state["last_run"] = datetime.now(tz=timezone.utc).isoformat()
    state["last_run_summary"] = {
        "total": len(jobs),
        "passed": success,
        "failed": failed_jobs,
    }

    try:
        save_state(state)
    except OSError as exc:
        logger.error("Could not save state file: %s", exc)

    logger.info("Done. %d/%d jobs passed.", success, len(jobs))

    return 0 if not failed_jobs else 1


if __name__ == "__main__":
    sys.exit(main())
