"""Versioned, run-bound result envelopes for the Projects runner."""
from __future__ import annotations

import hashlib
import json

from github_actions_inbox import validate_jobs


def _canonical(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def build(manifest, records):
    """Serialize terminal results; incomplete batches must stay pending."""
    validate_jobs(manifest["jobs"], manifest["count"])
    if len(records) != len(manifest["jobs"]):
        raise ValueError("batch result count mismatch")
    outputs = []
    for request, record in zip(manifest["jobs"], records):
        if not isinstance(record, dict) or record.get("status") not in ("completed", "failed"):
            raise ValueError("batch has unresolved jobs")
        job = record.get("job") or {}
        if any(job.get(key) != request[key] for key in
               ("job_id", "source_sha256", "source_language", "target_language")):
            raise ValueError("result does not match request")
        entry = {"job_id": request["job_id"], "source_sha256": request["source_sha256"],
                 "target_language": request["target_language"], "status": record["status"]}
        if record["status"] == "completed":
            result = record.get("result") or {}
            code = result.get("code")
            if (result.get("status") != "ok" or not isinstance(code, str) or not code.strip()
                    or any(result.get(key) != job.get(key) for key in
                           ("job_id", "target_language", "selected_node"))):
                raise ValueError("invalid node result")
            entry.update({"code": code, "code_sha256": hashlib.sha256(code.encode("utf-8")).hexdigest(),
                          "selected_node": job["selected_node"], "attempt_id": job["attempt_id"]})
        outputs.append(entry)
    value = {"version": 1, "run_id": manifest["run_id"], "run_attempt": manifest["run_attempt"],
             "workflow_sha": manifest["workflow_sha"], "results": outputs}
    return _canonical(value)


def verify(data, manifest):
    """Check run, job identity and content hashes before runner validation."""
    if not isinstance(data, bytes) or len(data) > 100 * 1024 * 1024:
        raise ValueError("invalid result envelope size")
    validate_jobs(manifest["jobs"], manifest["count"])
    value = json.loads(data)
    if not isinstance(value, dict) or set(value) != {"version", "run_id", "run_attempt", "workflow_sha", "results"}:
        raise ValueError("invalid result envelope")
    if value["version"] != 1 or any(value.get(key) != manifest[key] for key in
                                    ("run_id", "run_attempt", "workflow_sha")):
        raise ValueError("result run mismatch")
    results = value["results"]
    if not isinstance(results, list) or len(results) != len(manifest["jobs"]):
        raise ValueError("result count mismatch")
    for expected, actual in zip(manifest["jobs"], results):
        if not isinstance(actual, dict) or any(actual.get(key) != expected[key] for key in
                     ("job_id", "source_sha256", "target_language")):
            raise ValueError("result identity mismatch")
        if actual.get("status") == "failed":
            if set(actual) != {"job_id", "source_sha256", "target_language", "status"}:
                raise ValueError("invalid failed result")
        elif actual.get("status") == "completed":
            if set(actual) != {"job_id", "source_sha256", "target_language", "status", "code",
                               "code_sha256", "selected_node", "attempt_id"}:
                raise ValueError("invalid completed result")
            code = actual["code"]
            if (not isinstance(code, str) or not code.strip() or
                hashlib.sha256(code.encode("utf-8")).hexdigest() != actual["code_sha256"] or
                not isinstance(actual["selected_node"], str) or not actual["selected_node"] or
                not isinstance(actual["attempt_id"], str) or not actual["attempt_id"]):
                raise ValueError("invalid result content")
        else:
            raise ValueError("nonterminal result")
    return value
