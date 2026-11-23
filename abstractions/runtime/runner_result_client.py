"""Retrieve, authenticate and decode a Gateway batch result on an Actions runner."""
from __future__ import annotations

import base64
import hashlib
import json
import re
import urllib.request

import batch_results
import secure_result_channel

BASE = "https://api.github.com/repos/KikiKari/Projects"


def identity(manifest):
    request = {key: value for key, value in manifest.items() if key != "artifact_id"}
    encoded = json.dumps(request, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
    return {"run_id": manifest["run_id"], "run_attempt": manifest["run_attempt"],
            "workflow_sha": manifest["workflow_sha"], "request_sha256": hashlib.sha256(encoded).hexdigest()}


def _get(path, token, opener):
    req = urllib.request.Request(BASE + path, headers={"Authorization": "Bearer " + token,
        "Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "openclaw-runner-results"})
    with opener(req, timeout=60) as response:
        data = response.read(150 * 1024 * 1024 + 1)
    if len(data) > 150 * 1024 * 1024:
        raise ValueError("GitHub response too large")
    return json.loads(data)


def receive(manifest, token, private_key, trusted_gateway_key, *, opener=urllib.request.urlopen):
    """Return None while pending, or verified per-job results on success."""
    if not token or not token.strip():
        raise ValueError("GitHub token unavailable")
    run = manifest["run_id"]
    attempt = manifest["run_attempt"]
    sha = manifest["workflow_sha"]
    if type(run) is not int or run <= 0 or type(attempt) is not int or attempt <= 0 or not re.fullmatch(r"[0-9a-f]{40}", sha):
        raise ValueError("invalid workflow identity")
    context = f"openclaw/actions-result/{run}/{attempt}"
    status = None
    for page in range(1, 11):
        statuses = _get(f"/commits/{sha}/statuses?per_page=100&page={page}", token, opener)
        if not isinstance(statuses, list):
            raise ValueError("invalid GitHub status response")
        status = next((entry for entry in statuses if entry.get("context") == context), None)
        if status is not None or len(statuses) < 100:
            break
    else:
        raise ValueError("result status pagination limit exceeded")
    if status is None or status.get("state") == "pending":
        return None
    match = re.fullmatch(r"result-v1 ([0-9a-f]{40})", status.get("description") or "")
    if status.get("state") != "success" or not match:
        raise ValueError("invalid result status")
    blob_sha = match.group(1)
    blob = _get("/git/blobs/" + blob_sha, token, opener)
    if blob.get("sha") != blob_sha or blob.get("encoding") != "base64":
        raise ValueError("invalid result blob")
    data = base64.b64decode(blob.get("content", ""))
    expected = hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()
    if expected != blob_sha:
        raise ValueError("result blob identity mismatch")
    plaintext = secure_result_channel.open_envelope(data, private_key, identity(manifest), trusted_gateway_key)
    return batch_results.verify(plaintext, manifest)
