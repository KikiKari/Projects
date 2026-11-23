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
    trees = manager.quellen_holen()
    if not trees:
        raise RuntimeError("no source repositories available")
    inventory = manager.inventar_bauen(trees)
    if not inventory:
        raise RuntimeError("source inventory is empty")
    selected = state.get("naechste_prioritaet", "high") if priority == "reihum" else priority
    manifest, entries = runner_planner.plan(manager, inventory, state, priority=selected, count=count,
        run_id=run_id, run_attempt=run_attempt, workflow_sha=workflow_sha, runner_public_key=public)
    write_private(private_path, private)
    write_private(directory / "entries.json", json.dumps(entries, ensure_ascii=False).encode("utf-8"))
    write_private(directory / "request.json", json.dumps(manifest, ensure_ascii=False).encode("utf-8"))
    manager.zustand_speichern(state)
    return len(manifest["jobs"])


def receive(manager, directory, token, trusted_gateway_key, *, timeout_seconds=18000, interval=15):
    directory = Path(directory)
    manifest = json.loads((directory / "request.json").read_text(encoding="utf-8"))
    entries = json.loads((directory / "entries.json").read_text(encoding="utf-8"))
    private = (directory / "runner-private.pem").read_bytes()
    deadline = time.monotonic() + timeout_seconds
    while time.monotonic() < deadline:
        try:
            result = runner_result_client.receive(manifest, token, private, trusted_gateway_key)
        except (urllib.error.URLError, OSError):
            result = None
        if result is not None:
            state = manager.zustand_laden()
            counts = runner_apply.apply(manager, manifest, entries, result, state, manager.zustand_speichern)
            if manifest["jobs"]:
                state.setdefault("auswahl_cursor", {})[manifest["priority"]] = entries[manifest["jobs"][-1]["job_id"]]["hash"]
            state["naechste_prioritaet"] = {"high": "medium", "medium": "low", "low": "high", "alle": "alle"}[manifest["priority"]]
            manager.zustand_speichern(state)
            return counts
        time.sleep(interval)
    raise TimeoutError("Gateway result not received within runner deadline")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("phase", choices=("prepare", "receive"))
    parser.add_argument("--manager", required=True)
    parser.add_argument("--output-root", required=True)
    parser.add_argument("--directory", required=True)
    parser.add_argument("--priority", default="reihum", choices=("reihum", "high", "medium", "low", "alle"))
    parser.add_argument("--count", type=int, default=40)
    parser.add_argument("--trusted-key-file")
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
    result = receive(manager, args.directory, token, trusted)
    print("Ergebnisse:", result)
    return 1 if result["verworfen"] else 0


if __name__ == "__main__":
    sys.exit(main())
