#!/usr/bin/env python3
"""Run Actions translation requests directly against the configured provider."""
import argparse
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path

import runner_manager


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--manager", required=True)
    parser.add_argument("--output-root", required=True)
    parser.add_argument("--directory", required=True)
    args = parser.parse_args()
    token = os.environ.get("OPENROUTER_API_KEY", "").strip()
    if not token:
        raise RuntimeError("OPENROUTER_API_KEY fehlt")
    manager = runner_manager.load_manager(args.manager, args.output_root)
    manager.VERSUCHE = 2
    manager.ZEITLIMIT = 60
    directory = Path(args.directory)
    manifest = json.loads((directory / "request.json").read_text(encoding="utf-8"))
    entries = json.loads((directory / "entries.json").read_text(encoding="utf-8"))
    jobs = manifest["jobs"]
    if len(jobs) > 100:
        raise ValueError("Mehr als 100 Teilauftraege")
    state = manager.zustand_laden()
    occupied = {}
    counts = {"erzeugt": 0, "verworfen": 0}

    def translate(job):
        entry = entries[job["job_id"]]
        raw = Path(entry["pfad"]).read_bytes()
        if hashlib.sha256(raw).hexdigest() != job["source_sha256"]:
            raise ValueError("Quelldatei wurde veraendert")
        source = raw.decode("utf-8")
        code = manager.modell_fragen(source, job["source_language"],
                                     job["target_language"], entry["name"], token)
        return source, code

    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as pool:
        pending = {pool.submit(translate, job): job for job in jobs}
        for future in concurrent.futures.as_completed(pending):
            job = pending[future]
            entry = entries[job["job_id"]]
            target = job["target_language"]
            try:
                source, code = future.result()
                accepted, reason = manager.erzeugnis_pruefen(code, target, source) if code else (False, "keine Antwort")
                if not accepted:
                    print(f"{entry['name']} -> {target}: {reason}", flush=True)
                    counts["verworfen"] += 1
                    continue
                destination = manager.ablegen(entry, target, code, occupied, source)
                if destination is None:
                    counts["verworfen"] += 1
                    continue
                done = set(state.setdefault("erledigt", {}).get(entry["hash"], []))
                done.add(target)
                state["erledigt"][entry["hash"]] = sorted(done)
                manager.zustand_speichern(state)
                counts["erzeugt"] += 1
                print(f"{entry['name']} -> {target}: gespeichert", flush=True)
            except Exception as exc:
                counts["verworfen"] += 1
                print(f"{entry['name']} -> {target}: {type(exc).__name__}", flush=True)
    if jobs:
        last = entries[jobs[-1]["job_id"]]
        state.setdefault("auswahl_cursor", {})[manifest["priority"]] = last["hash"]
        if last.get("source_blob"):
            state.setdefault("auswahl_blob_cursor", {})[manifest["priority"]] = last["source_blob"]
    state["naechste_prioritaet"] = {"high": "medium", "medium": "low", "low": "high", "alle": "alle"}[manifest["priority"]]
    manager.zustand_speichern(state)
    print("Ergebnisse:", counts, flush=True)
    return 0 if counts["erzeugt"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
