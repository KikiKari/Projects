"""Build immutable translation requests from the current manager inventory."""
from __future__ import annotations

import hashlib
from pathlib import Path
import re
import subprocess
import uuid

from github_actions_inbox import SOURCE_REPOSITORIES, validate_jobs


def source_identity(entry, manager):
    """Find a source whose Git commit contains the exact inventoried bytes."""
    raw = Path(entry["pfad"]).read_bytes()
    digest = hashlib.sha256(raw).hexdigest()
    for origin in entry.get("herkunft", []):
        match = re.fullmatch(r"([^@]+)@([^:]+):(.+)", origin)
        if not match:
            continue
        repo, branch, path = match.groups()
        repo_name = "KikiKari/" + repo
        if repo_name not in SOURCE_REPOSITORIES:
            continue
        mirror = manager.QUELLEN_DIR / (repo + ".git")
        try:
            sha = subprocess.check_output(["git", "-C", str(mirror), "rev-parse", "--verify",
                "refs/heads/" + branch + "^{commit}"], stderr=subprocess.DEVNULL, timeout=30, text=True).strip()
            if not re.fullmatch(r"[0-9a-f]{40}", sha):
                continue
            data = subprocess.check_output(["git", "-C", str(mirror), "show", sha + ":" + path],
                                           stderr=subprocess.DEVNULL, timeout=30)
            if hashlib.sha256(data).hexdigest() == digest:
                return {"source_repository": repo_name, "source_commit": sha, "source_path": path,
                        "source_sha256": digest, "source_language": entry["sprache"]}, raw
        except (OSError, subprocess.SubprocessError):
            continue
    raise ValueError("no immutable source matches inventory")


def plan(manager, inventory, state, *, priority, count, run_id, run_attempt, workflow_sha,
         runner_public_key, resolve=source_identity):
    """Select up to count sources using the manager's current language rules."""
    if priority not in {"high", "medium", "low", "alle"} or type(count) is not int or not 1 <= count <= 40:
        raise ValueError("invalid selection")
    if type(run_id) is not int or run_id <= 0 or type(run_attempt) is not int or run_attempt <= 0:
        raise ValueError("invalid run")
    if not isinstance(workflow_sha, str) or not re.fullmatch(r"[0-9a-f]{40}", workflow_sha):
        raise ValueError("invalid workflow commit")
    available = manager.verfuegbare_parser()
    missing = manager.PARSER_SPRACHEN - available
    if missing:
        raise ValueError("required syntax parsers unavailable: " + ", ".join(sorted(missing)))
    candidates = [entry for entry in inventory if priority == "alle" or entry["prioritaet"] == priority]
    cursor = state.get("auswahl_cursor", {}).get(priority)
    if cursor:
        pos = next((i for i, entry in enumerate(candidates) if entry["hash"] == cursor), None)
        if pos is not None:
            candidates = candidates[pos + 1:] + candidates[:pos + 1]
    selected, jobs, entries = 0, [], {}
    for entry in candidates:
        if selected >= count:
            break
        if entry["bytes"] > manager.MAX_BYTES:
            continue
        try:
            source, raw = resolve(entry, manager)
            if not raw.strip() or manager.enthaelt_zugangsdaten(raw):
                continue
            source_text = raw.decode("utf-8")
        except (OSError, ValueError, UnicodeError):
            continue
        done = set(state.get("erledigt", {}).get(entry["hash"], []))
        targets = [target for target in manager.zielsprachen_fuer(entry["sprache"], source_text)
                   if target not in done and target not in missing]
        if entry.get("css_only"):
            targets = [target for target in targets if target == "css"]
        entry = {**entry, "source_sha256": source["source_sha256"]}
        remaining = []
        for target in targets:
            if manager.vorhandenes_erzeugnis(entry, target, source_text):
                done.add(target)
            else:
                remaining.append(target)
        if done:
            state.setdefault("erledigt", {})[entry["hash"]] = sorted(done)
        targets = remaining
        if not targets:
            continue
        # Keep each source together while limiting the batch to 100 jobs.
        if len(jobs) + len(targets) > 100:
            break
        selected += 1
        for target in targets:
            job_id = str(uuid.uuid4())
            jobs.append({"job_id": job_id, **source, "target_language": target})
            entries[job_id] = entry
    validate_jobs(jobs, count)
    request = {"run_id": run_id, "run_attempt": run_attempt, "workflow_sha": workflow_sha,
               "priority": priority, "count": count, "jobs": jobs, "runner_public_key": runner_public_key}
    return request, entries
