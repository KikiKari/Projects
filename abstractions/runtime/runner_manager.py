#!/usr/bin/env python3
"""Prepare and consume a Gateway batch using the current abstraction manager."""
from __future__ import annotations

import argparse
import importlib.util
import json
import os
from pathlib import Path
import shutil
import sys
import time
import urllib.error

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa

import runner_apply
import runner_planner
import runner_source_index
import runner_result_client


def check_validation_tools(manager):
    missing = sorted({command[0] for command in manager.PRUEFBEFEHLE.values()
                      if command and shutil.which(command[0]) is None})
    missing_parsers = sorted(manager.PARSER_SPRACHEN - manager.verfuegbare_parser())
    if missing or missing_parsers:
        raise RuntimeError("missing validation tools: " + ", ".join(missing + missing_parsers))


def load_manager(path, output_root):
    os.environ["ABSTRACTIONS_EXECUTION"] = "standalone"
    spec = importlib.util.spec_from_file_location("runner_abstractions_manager", path)
    if spec is None or spec.loader is None:
        raise RuntimeError("manager unavailable")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module.ABSTRACTIONS_REPO = Path(output_root).resolve(strict=True)
    return module


def write_private(path, data):
    fd = os.open(path, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
    with os.fdopen(fd, "wb") as file:
        file.write(data)


def prepare_git_sources(manager, directory, state, priority, count, run_id, run_attempt, workflow_sha):
    """Index pinned Git trees and materialize only selected source blobs."""
    from concurrent.futures import ThreadPoolExecutor
    import hashlib
    import io
    import re
    import subprocess

    def git(mirror, *args, data=None):
        return subprocess.run(["git", "-C", str(mirror), *args], input=data,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                              check=True, timeout=1800).stdout

    manager.QUELLEN_DIR.mkdir(parents=True, exist_ok=True)

    def update(source):
        repo = str(source["repo"])
        mirror = manager.QUELLEN_DIR / (repo + ".git")
        if mirror.exists():
            result = manager._git("remote", "update", "--prune", verzeichnis=mirror)
        else:
            url = f"https://github.com/{manager.GITHUB_BENUTZER}/{repo}.git"
            result = manager._git("clone", "--mirror", "--filter=blob:none", url, str(mirror))
        if result.returncode != 0:
            raise RuntimeError(f"{repo}: Quellspiegel nicht verfuegbar")

    with ThreadPoolExecutor(max_workers=3) as pool:
        list(pool.map(update, manager.QUELLEN))

    index = runner_source_index.snapshot(manager, run_id, run_attempt, workflow_sha)
    sources = []

    def list_branch(item):
        repo, branch, commit = item
        mirror = manager.QUELLEN_DIR / (repo + ".git")
        records = []
        for item in git(mirror, "ls-tree", "-r", "-z", "--full-tree", commit).split(b"\\0"):
            if not item:
                continue
            metadata, raw_path = item.split(b"\\t", 1)
            mode, kind, oid = metadata.split(b" ", 2)
            if kind != b"blob" or mode not in (b"100644", b"100755"):
                continue
            path = os.fsdecode(raw_path).replace("\\\\", "/")
            language = manager.QUELLSPRACHEN.get(Path(path).suffix.lower())
            if language is None or any(pattern in "/" + path for pattern in manager.AUSSCHLUSS):
                continue
            if not re.fullmatch(r"[0-9a-f]{40}", oid.decode("ascii")):
                raise ValueError("invalid Git blob identity")
            records.append((repo, branch, commit, path, language, oid.decode("ascii")))
        return records

    branches = [(repo, branch, data["commit"]) for repo, details in index["repositories"].items()
                for branch, data in details.items()]
    with ThreadPoolExecutor(max_workers=6) as pool:
        for records in pool.map(list_branch, branches):
            sources.extend(records)

    grouped = {}
    for repo, branch, commit, path, language, oid in sources:
        origin = f"{repo}@{branch}:{path}"
        item = grouped.get(oid)
        if item is None:
            item = {"blob": oid, "repo": repo, "commit": commit, "path": path,
                    "sprache": language, "herkunft": [], "prioritaet": manager._prioritaet(path, language)}
            grouped[oid] = item
        item["herkunft"].append(origin)

    rank = {"high": 0, "medium": 1, "low": 2}
    candidates = sorted((item for item in grouped.values()
                         if priority == "alle" or item["prioritaet"] == priority),
                        key=lambda item: (rank[item["prioritaet"]], Path(item["path"]).name))
    cursor = state.get("auswahl_blob_cursor", {}).get(priority)
    if cursor:
        pos = next((i for i, item in enumerate(candidates) if item["blob"] == cursor), None)
        if pos is not None:
            candidates = candidates[pos + 1:] + candidates[:pos + 1]
    selected = candidates[:count]
    by_repo = {}
    for item in selected:
        by_repo.setdefault(item["repo"], []).append(item)

    def read_blobs(pair):
        repo, items = pair
        mirror = manager.QUELLEN_DIR / (repo + ".git")
        requested = b"".join((item["blob"] + "\\n").encode("ascii") for item in items)
        checks = git(mirror, "cat-file", "--batch-check=%(objectname) %(objecttype) %(objectsize)", data=requested).splitlines()
        if len(checks) != len(items):
            raise ValueError("incomplete Git blob metadata")
        eligible = []
        for item, line in zip(items, checks):
            fields = line.split()
            if len(fields) != 3 or fields[0].decode("ascii") != item["blob"] or fields[1] != b"blob":
                raise ValueError("invalid Git blob metadata")
            if int(fields[2]) <= manager.MAX_BYTES:
                eligible.append((item, int(fields[2])))
        if not eligible:
            return []
        wanted = b"".join((item["blob"] + "\\n").encode("ascii") for item, _ in eligible)
        output = io.BytesIO(git(mirror, "cat-file", "--batch", data=wanted))
        result = []
        for item, size in eligible:
            header = output.readline().rstrip(b"\\n").split()
            if len(header) != 3 or header[0].decode("ascii") != item["blob"] or header[1] != b"blob" or int(header[2]) != size:
                raise ValueError("invalid Git blob response")
            raw = output.read(size)
            if len(raw) != size or output.read(1) != b"\\n":
                raise ValueError("incomplete Git blob response")
            result.append((item, raw))
        return result

    loaded = {}
    with ThreadPoolExecutor(max_workers=3) as pool:
        for result in pool.map(read_blobs, by_repo.items()):
            for item, raw in result:
                loaded[item["blob"]] = raw

    source_dir = Path(directory) / "sources"
    source_dir.mkdir(mode=0o700, exist_ok=True)
    inventory = []
    for item in selected:
        raw = loaded.get(item["blob"])
        if raw is None or not raw.strip() or manager.enthaelt_zugangsdaten(raw):
            continue
        digest = hashlib.sha256(raw).hexdigest()
        target = source_dir / digest
        if not target.exists():
            write_private(target, raw)
        source_path = Path(item["path"])
        inventory.append({"hash": digest[:16], "name": source_path.name, "stamm": source_path.stem,
                          "sprache": item["sprache"], "bytes": len(raw), "pfad": str(target),
                          "herkunft": item["herkunft"], "prioritaet": item["prioritaet"],
                          "css_only": False, "source_blob": item["blob"], "source_repo": item["repo"],
                          "source_commit": item["commit"], "source_path": item["path"],
                          "source_sha256": digest})
    return index, inventory, (selected[-1]["blob"] if selected else None)


def pinned_source_identity(entry, manager):
    raw = Path(entry["pfad"]).read_bytes()
    import hashlib
    digest = hashlib.sha256(raw).hexdigest()
    if digest != entry["source_sha256"]:
        raise ValueError("selected source changed")
    return {"source_repository": "KikiKari/" + entry["source_repo"],
            "source_commit": entry["source_commit"], "source_path": entry["source_path"],
            "source_sha256": digest, "source_language": entry["sprache"]}, raw


def prepare(manager, directory, *, priority, count, run_id, run_attempt, workflow_sha):
    directory = Path(directory)
    directory.mkdir(mode=0o700, parents=True, exist_ok=True)
    private_path = directory / "runner-private.pem"
    if private_path.exists() or (directory / "request.json").exists():
        raise ValueError("runner batch already exists")
    key = rsa.generate_private_key(public_exponent=65537, key_size=3072)
    public = key.public_key().public_bytes(serialization.Encoding.PEM,
                                           serialization.PublicFormat.SubjectPublicKeyInfo).decode("ascii")
    private = key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
                                serialization.NoEncryption())
    state = manager.zustand_laden()
    selected = state.get("naechste_prioritaet", "high") if priority == "reihum" else priority
    index, inventory, last_blob = prepare_git_sources(manager, directory, state, selected, count,
                                                       run_id, run_attempt, workflow_sha)
    write_private(directory / "source-index.json", json.dumps(index, ensure_ascii=True).encode("utf-8"))
    manifest, entries = runner_planner.plan(manager, inventory, state, priority=selected, count=count,
        run_id=run_id, run_attempt=run_attempt, workflow_sha=workflow_sha, runner_public_key=public,
        resolve=pinned_source_identity)
    if not manifest["jobs"] and last_blob:
        state.setdefault("auswahl_blob_cursor", {})[selected] = last_blob
    write_private(private_path, private)
    write_private(directory / "entries.json", json.dumps(entries, ensure_ascii=False).encode("utf-8"))
    write_private(directory / "request.json", json.dumps(manifest, ensure_ascii=False).encode("utf-8"))
    manager.zustand_speichern(state)
    return len(manifest["jobs"])


def receive(manager, directory, token, trusted_gateway_key, *, timeout_seconds=18000, interval=15, deadline_epoch=None, progress_interval=300):
    directory = Path(directory)
    manifest = json.loads((directory / "request.json").read_text(encoding="utf-8"))
    entries = json.loads((directory / "entries.json").read_text(encoding="utf-8"))
    private = (directory / "runner-private.pem").read_bytes()
    if timeout_seconds <= 0 or interval <= 0 or progress_interval <= 0:
        raise ValueError("invalid receive timeout or interval")
    remaining = timeout_seconds if deadline_epoch is None else min(timeout_seconds, deadline_epoch - time.time())
    start = time.monotonic()
    deadline = start + max(0, remaining)
    next_progress = start
    polls = 0
    failures = 0
    while time.monotonic() < deadline:
        try:
            result = runner_result_client.receive(manifest, token, private, trusted_gateway_key)
        except (urllib.error.URLError, OSError):
            result = None
            failures += 1
            state_label = "transport_error"
        else:
            state_label = "result_pending" if result is None else "result_received"
        polls += 1
        now = time.monotonic()
        if now >= next_progress or result is not None:
            print(f"Gateway-Empfang: {state_label}; Abfragen={polls}; Transportfehler={failures}; "
                  f"verbleibend={max(0, int(deadline - now))}s", flush=True)
            next_progress = now + progress_interval
        if result is not None:
            state = manager.zustand_laden()
            counts = runner_apply.apply(manager, manifest, entries, result, state, manager.zustand_speichern)
            if manifest["jobs"]:
                state.setdefault("auswahl_cursor", {})[manifest["priority"]] = entries[manifest["jobs"][-1]["job_id"]]["hash"]
                blob = entries[manifest["jobs"][-1]["job_id"]].get("source_blob")
                if blob:
                    state.setdefault("auswahl_blob_cursor", {})[manifest["priority"]] = blob
            state["naechste_prioritaet"] = {"high": "medium", "medium": "low", "low": "high", "alle": "alle"}[manifest["priority"]]
            manager.zustand_speichern(state)
            return counts
        time.sleep(max(0, min(interval, deadline - time.monotonic())))
    raise TimeoutError(f"Gateway result not received within runner deadline; polls={polls}, transport_errors={failures}")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("phase", choices=("prepare", "receive"))
    parser.add_argument("--manager", required=True)
    parser.add_argument("--output-root", required=True)
    parser.add_argument("--directory", required=True)
    parser.add_argument("--priority", default="reihum", choices=("reihum", "high", "medium", "low", "alle"))
    parser.add_argument("--count", type=int, default=40)
    parser.add_argument("--trusted-key-file")
    parser.add_argument("--deadline-epoch", type=int)
    args = parser.parse_args()
    manager = load_manager(args.manager, args.output_root)
    if args.phase == "prepare":
        check_validation_tools(manager)
        n = prepare(manager, args.directory, priority=args.priority, count=args.count,
                    run_id=int(os.environ["GITHUB_RUN_ID"]), run_attempt=int(os.environ["GITHUB_RUN_ATTEMPT"]),
                    workflow_sha=os.environ["GITHUB_SHA"])
        print("Gateway-Auftraege vorbereitet:", n)
        return 0
    if not args.trusted_key_file:
        raise ValueError("gateway signing key must be pinned")
    token = os.environ.get("GITHUB_TOKEN", "")
    trusted = Path(args.trusted_key_file).read_text(encoding="utf-8").strip()
    result = receive(manager, args.directory, token, trusted, deadline_epoch=args.deadline_epoch)
    print("Ergebnisse:", result)
    return 1 if result["verworfen"] else 0


if __name__ == "__main__":
    sys.exit(main())
