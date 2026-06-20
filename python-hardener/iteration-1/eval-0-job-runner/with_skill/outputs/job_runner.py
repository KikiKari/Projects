#!/usr/bin/env python3
"""
job_runner.py — Production cron job runner.

Executes a fixed set of build/test/lint jobs, commits results to a local Git
repository, and persists run state to a JSON file.  All log output goes through
Python's standard ``logging`` module (RotatingFileHandler + StreamHandler).
"""

import json
import logging
import logging.handlers
import os
import subprocess
import tempfile
from datetime import datetime
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# Paths — resolved from environment variables so deployments can override them
# without changing the file.
# ---------------------------------------------------------------------------
WORKSPACE: Path = Path(os.environ.get("JOB_RUNNER_WORKSPACE", "/home/runner/workspace"))
STATE_FILE: Path = WORKSPACE / "job_state.json"
LOG_DIR: Path = Path(os.environ.get("JOB_RUNNER_LOG_DIR", str(WORKSPACE / "logs")))
GIT_REPO: Path = Path(os.environ.get("JOB_RUNNER_GIT_REPO", str(WORKSPACE / "output-repo")))

# Module-level logger; configured in setup_logging().
logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

def setup_logging() -> None:
    """Configure the root logger with a RotatingFileHandler and StreamHandler.

    Reads the desired log level from the ``LOG_LEVEL`` environment variable
    (default: ``INFO``).  The log directory is created if it does not exist.
    Handler setup is idempotent: calling this function more than once does not
    add duplicate handlers.
    """
    if logger.handlers:
        # Already configured — nothing to do.
        return

    level_name: str = os.environ.get("LOG_LEVEL", "INFO").upper()
    level: int = getattr(logging, level_name, logging.INFO)
    logger.setLevel(level)

    LOG_DIR.mkdir(parents=True, exist_ok=True)

    log_path = LOG_DIR / f"{datetime.now().strftime('%Y-%m-%d')}.log"

    file_handler = logging.handlers.RotatingFileHandler(
        log_path,
        maxBytes=10 * 1024 * 1024,  # 10 MB
        backupCount=7,
        encoding="utf-8",
    )
    file_handler.setFormatter(
        logging.Formatter("[%(asctime)s] [%(levelname)s] %(message)s")
    )

    stream_handler = logging.StreamHandler()
    stream_handler.setFormatter(
        logging.Formatter("[%(asctime)s] [%(levelname)s] %(message)s")
    )

    logger.addHandler(file_handler)
    logger.addHandler(stream_handler)


# ---------------------------------------------------------------------------
# State persistence
# ---------------------------------------------------------------------------

def load_state() -> dict:
    """Load job runner state from the JSON state file.

    Returns:
        A dictionary with the persisted state.  If the file does not exist or
        cannot be parsed, returns a safe default ``{"jobs": [], "last_run": None}``.
    """
    if STATE_FILE.exists():
        try:
            with open(STATE_FILE, "r", encoding="utf-8") as fh:
                return json.load(fh)
        except json.JSONDecodeError as exc:
            logger.warning("State file is corrupt, resetting: %s", exc)
        except OSError as exc:
            logger.warning("Cannot read state file: %s", exc)
    return {"jobs": [], "last_run": None}


def save_state(state: dict) -> None:
    """Persist job runner state to the JSON state file atomically.

    Uses a temporary file in the same directory followed by ``os.replace()``
    to avoid torn writes if the process is interrupted mid-write.

    Args:
        state: Dictionary to serialise as JSON.

    Raises:
        OSError: If the temporary file cannot be created or renamed.
    """
    STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
    dir_path = str(STATE_FILE.parent)

    fd, tmp_path = tempfile.mkstemp(dir=dir_path, suffix=".tmp")
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as fh:
            json.dump(state, fh, indent=2)
        os.replace(tmp_path, STATE_FILE)
    except OSError:
        # Clean up the temp file if the replace failed.
        try:
            os.unlink(tmp_path)
        except OSError:
            pass
        raise


# ---------------------------------------------------------------------------
# Job execution
# ---------------------------------------------------------------------------

def run_job(cmd: list[str], job_name: str) -> bool:
    """Execute a single job as a subprocess.

    The command is passed as a list so the shell is never involved, preventing
    shell-injection vulnerabilities.

    Args:
        cmd:      The command and its arguments as a list of strings.
        job_name: Human-readable name used in log messages.

    Returns:
        ``True`` if the process exited with return code 0, ``False`` otherwise.
    """
    try:
        result = subprocess.run(
            cmd,
            shell=False,
            capture_output=True,
            text=True,
            timeout=int(os.environ.get("JOB_TIMEOUT_SECONDS", "300")),
        )
        if result.returncode == 0:
            logger.info("Job '%s' finished successfully (rc=%d)", job_name, result.returncode)
        else:
            logger.warning(
                "Job '%s' finished with non-zero exit code %d\nstdout: %s\nstderr: %s",
                job_name,
                result.returncode,
                result.stdout.strip(),
                result.stderr.strip(),
            )
        return result.returncode == 0
    except subprocess.TimeoutExpired as exc:
        logger.error("Job '%s' timed out after %s seconds", job_name, exc.timeout)
        return False
    except subprocess.SubprocessError as exc:
        logger.error("Job '%s' failed to start: %s", job_name, exc, exc_info=True)
        return False
    except OSError as exc:
        logger.error("OS error running job '%s': %s", job_name, exc, exc_info=True)
        return False


# ---------------------------------------------------------------------------
# Git commit
# ---------------------------------------------------------------------------

def commit_results(message: str) -> bool:
    """Stage all changes in the Git repository and create a commit.

    Uses ``git -C <repo_path>`` instead of ``os.chdir()`` so the process
    working directory is never mutated.

    Args:
        message: Commit message.

    Returns:
        ``True`` if both ``git add`` and ``git commit`` succeeded,
        ``False`` otherwise.
    """
    try:
        subprocess.run(
            ["git", "-C", str(GIT_REPO), "add", "."],
            check=True,
            capture_output=True,
            text=True,
        )
        subprocess.run(
            ["git", "-C", str(GIT_REPO), "commit", "-m", message],
            check=True,
            capture_output=True,
            text=True,
        )
        logger.info("Git commit created: %s", message)
        return True
    except subprocess.CalledProcessError as exc:
        logger.error(
            "Git operation failed (rc=%d): %s\nstdout: %s\nstderr: %s",
            exc.returncode,
            exc.cmd,
            exc.stdout.strip() if exc.stdout else "",
            exc.stderr.strip() if exc.stderr else "",
        )
        return False
    except OSError as exc:
        logger.error("Could not invoke git: %s", exc, exc_info=True)
        return False


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    """Run all configured jobs, commit results, and persist state.

    Jobs are defined as ``(name, command_list)`` pairs.  Each command list is
    passed directly to :func:`run_job` without shell interpretation.  State is
    persisted atomically after every run.
    """
    setup_logging()
    logger.info("Runner started")

    state = load_state()

    jobs: list[tuple[str, list[str]]] = [
        ("build", ["make", "build"]),
        ("test",  ["make", "test"]),
        ("lint",  ["flake8", "."]),
    ]

    success = 0
    for name, cmd in jobs:
        if run_job(cmd, name):
            success += 1

    commit_results(f"Run: {success}/{len(jobs)} jobs passed")

    state["last_run"] = datetime.now().isoformat()
    try:
        save_state(state)
    except OSError as exc:
        logger.error("Failed to persist state: %s", exc, exc_info=True)

    logger.info("Done. %d/%d passed", success, len(jobs))


if __name__ == "__main__":
    main()
