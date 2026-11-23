"""Discover authenticated Projects workflow request artifacts on the gateway.

This module only reads and validates requests. It does not submit work or
change a workflow; a caller must durably claim requests before dispatch.
"""
from __future__ import annotations

import io
import json
import re
import urllib.parse
import urllib.request
import zipfile

REPOSITORY = "KikiKari/Projects"
WORKFLOW_ID = 329626223
MAX_ARCHIVE = 2 * 1024 * 1024
MAX_MANIFEST = 2 * 1024 * 1024
PRIORITIES = frozenset({"reihum", "high", "medium", "low", "alle"})
LANGUAGES = frozenset({"javascript", "perl5", "powershell", "python", "shell", "tcl",
                       "perl6", "ruby", "lua", "go", "java", "c", "cpp", "php", "fsharp", "css"})
SOURCE_LANGUAGES = LANGUAGES | {"html"}
SOURCE_REPOSITORIES = frozenset({"KikiKari/Projects", "KikiKari/OpenClaw", "KikiKari/Onboarding"})


def validate_jobs(jobs, count):
    """Validate source identities and all 16 supported target languages.

    The manifest contains immutable Git identities, not source code, prompts or
    credentials. The executor must fetch and hash-check content before dispatch.
    """
    if not isinstance(jobs, list) or len(jobs) > 40 * len(LANGUAGES):
        raise ValueError("invalid batch size")
    ids, pairs, sources = set(), set(), set()
    required = {"job_id", "source_repository", "source_commit", "source_path",
                "source_sha256", "source_language", "target_language"}
    for job in jobs:
        if not isinstance(job, dict) or set(job) != required:
            raise ValueError("invalid job fields")
        jid, repo = job["job_id"], job["source_repository"]
        commit, path, digest = job["source_commit"], job["source_path"], job["source_sha256"]
        source, target = job["source_language"], job["target_language"]
        if (not isinstance(jid, str) or not re.fullmatch(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", jid)
                or repo not in SOURCE_REPOSITORIES or not isinstance(commit, str)
                or not re.fullmatch(r"[0-9a-f]{40}", commit) or not isinstance(digest, str)
                or not re.fullmatch(r"[0-9a-f]{64}", digest) or not isinstance(path, str)
                or not path or len(path.encode("utf-8")) > 1024 or "\\" in path
                or any(part in {"", ".", "..", ".git"} for part in path.split("/"))
                or source not in SOURCE_LANGUAGES or target not in LANGUAGES
                or source == target or (target == "css" and source != "html")):
            raise ValueError("invalid translation job")
        identity = (repo, commit, path, digest, source)
        pair = (identity, target)
        if jid in ids or pair in pairs:
            raise ValueError("duplicate job or translation pair")
        ids.add(jid)
        pairs.add(pair)
        sources.add(identity)
    if len(sources) > count:
        raise ValueError("source count exceeded")


class SafeRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, fp, code, message, headers, new_url):
        redirected = super().redirect_request(request, fp, code, message, headers, new_url)
        if redirected is not None and urllib.parse.urlsplit(new_url).hostname != urllib.parse.urlsplit(request.full_url).hostname:
            redirected.remove_header("Authorization")
            redirected.unredirected_hdrs.pop("Authorization", None)
        return redirected


def read_url(url, token, limit=MAX_ARCHIVE):
    parsed = urllib.parse.urlsplit(url)
    if parsed.scheme != "https" or parsed.hostname != "api.github.com":
        raise ValueError("untrusted GitHub API endpoint")
    request = urllib.request.Request(url, headers={"Authorization": "Bearer " + token,
        "Accept": "application/vnd.github+json", "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "openclaw-actions-inbox"})
    opener = urllib.request.build_opener(SafeRedirect())
    with opener.open(request, timeout=30) as response:
        data = response.read(limit + 1)
    if len(data) > limit:
        raise ValueError("GitHub response too large")
    return data


def api_json(path, token):
    return json.loads(read_url("https://api.github.com" + path, token, 2 * 1024 * 1024))


def requests_for_run(run, token):
    """Return strictly bound manifests for one trusted in-progress run."""
    if (run.get("workflow_id") != WORKFLOW_ID or run.get("status") != "in_progress"
            or run.get("head_branch") != "main"
            or (run.get("head_repository") or {}).get("full_name", "").lower() != REPOSITORY.lower()
            or run.get("event") not in {"schedule", "workflow_dispatch"}):
        return []
    run_id, attempt, sha = run.get("id"), run.get("run_attempt"), run.get("head_sha")
    if type(run_id) is not int or type(attempt) is not int or not re.fullmatch(r"[0-9a-f]{40}", sha or ""):
        raise ValueError("invalid workflow identity")
    expected = {f"openclaw-gateway-request-v1-{run_id}-{attempt}",
                f"openclaw-gateway-request-v2-{run_id}-{attempt}"}
    listing = api_json(f"/repos/{REPOSITORY}/actions/runs/{run_id}/artifacts?per_page=100", token)
    if listing.get("total_count", 0) > 100:
        raise ValueError("artifact list requires pagination")
    matched = [x for x in listing.get("artifacts", []) if x.get("name") in expected and not x.get("expired")]
    if len(matched) > 1:
        raise ValueError("ambiguous request artifact")
    if not matched:
        return []
    artifact = matched[0]
    artifact_id = artifact.get("id")
    if type(artifact_id) is not int:
        raise ValueError("invalid artifact identity")
    archive = read_url(f"https://api.github.com/repos/{REPOSITORY}/actions/artifacts/{artifact_id}/zip", token)
    with zipfile.ZipFile(io.BytesIO(archive)) as zipped:
        files = zipped.infolist()
        if len(files) != 1 or files[0].filename != "request.json" or files[0].file_size > MAX_MANIFEST:
            raise ValueError("invalid request archive")
        manifest = json.loads(zipped.read(files[0]))
    fields = {"run_id", "run_attempt", "workflow_sha", "priority", "count", "jobs"}
    version2 = artifact["name"] == f"openclaw-gateway-request-v2-{run_id}-{attempt}"
    if not isinstance(manifest, dict) or set(manifest) != (fields | {"runner_public_key"} if version2 else fields):
        raise ValueError("invalid request fields")
    if (manifest["run_id"] != run_id or manifest["run_attempt"] != attempt or manifest["workflow_sha"] != sha
            or manifest["priority"] not in PRIORITIES or type(manifest["count"]) is not int
            or not 1 <= manifest["count"] <= 40):
        raise ValueError("request does not match workflow")
    validate_jobs(manifest["jobs"], manifest["count"])
    if version2:
        from cryptography.hazmat.primitives import serialization
        from cryptography.hazmat.primitives.asymmetric import rsa
        pem = manifest["runner_public_key"]
        if not isinstance(pem, str) or len(pem) > 2048:
            raise ValueError("invalid runner public key")
        key = serialization.load_pem_public_key(pem.encode("ascii"))
        if not isinstance(key, rsa.RSAPublicKey) or key.key_size not in (3072, 4096):
            raise ValueError("unsupported runner public key")
    return [{**manifest, "artifact_id": artifact_id}]


def discover(token):
    if not token or not token.strip():
        raise ValueError("GitHub credential unavailable")
    path = f"/repos/{REPOSITORY}/actions/workflows/{WORKFLOW_ID}/runs?status=in_progress&per_page=100"
    payload = api_json(path, token)
    if payload.get("total_count", 0) > 100:
        raise ValueError("workflow run list requires pagination")
    return [item for run in payload.get("workflow_runs", []) for item in requests_for_run(run, token)]
