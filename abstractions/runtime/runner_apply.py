"""Validate and store authenticated Gateway translations with the manager."""
from __future__ import annotations

import hashlib
import json
from pathlib import Path

import batch_results


def apply(manager, manifest, entries, verified_result, state, save):
    """Apply a result already authenticated by runner_result_client.receive."""
    value = batch_results.verify(json.dumps(verified_result, ensure_ascii=False).encode("utf-8"), manifest)
    counts = {"erzeugt": 0, "verworfen": 0}
    occupied = {}
    for request, result in zip(manifest["jobs"], value["results"]):
        if result["status"] != "completed":
            counts["verworfen"] += 1
            continue
        entry = entries.get(request["job_id"])
        if not isinstance(entry, dict) or entry.get("source_sha256") != request["source_sha256"]:
            raise ValueError("local source record mismatch")
        raw = Path(entry["pfad"]).read_bytes()
        if hashlib.sha256(raw).hexdigest() != request["source_sha256"]:
            raise ValueError("source changed after request")
        source = raw.decode("utf-8")
        target = request["target_language"]
        code = manager._modell_code_bereinigen(result["code"], target)
        accepted, _reason = manager.erzeugnis_pruefen(code, target, source)
        if not accepted:
            counts["verworfen"] += 1
            continue
        destination = manager.ablegen(entry, target, code, occupied, source)
        if destination is None:
            counts["verworfen"] += 1
            continue
        complete = set(state.setdefault("erledigt", {}).get(entry["hash"], []))
        complete.add(target)
        state["erledigt"][entry["hash"]] = sorted(complete)
        save(state)
        counts["erzeugt"] += 1
    return counts
