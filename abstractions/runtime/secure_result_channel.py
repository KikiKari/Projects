"""Encrypt runner results and authenticate the gateway using SSH signatures.

The encrypted envelope may be stored on an untrusted transport. Authentication
uses a pinned SSH public key; the private signing key never leaves the gateway.
"""
from __future__ import annotations

import base64
import json
import os
from pathlib import Path
import subprocess
import tempfile

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

NAMESPACE = "openclaw-actions-result-v1"
IDENTITY = "openclaw-gateway"
MAX_ENVELOPE = 140 * 1024 * 1024


def _json(value):
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")


def _encode(value):
    return base64.b64encode(value).decode("ascii")


def _decode(value):
    if not isinstance(value, str):
        raise ValueError("invalid envelope encoding")
    return base64.b64decode(value, validate=True)


def seal(payload, recipient_public_pem, identity, signing_key):
    """Encrypt for this runner and sign the exact run-bound ciphertext."""
    if not isinstance(payload, bytes) or len(payload) > 100 * 1024 * 1024:
        raise ValueError("invalid result size")
    public = serialization.load_pem_public_key(recipient_public_pem)
    if not isinstance(public, rsa.RSAPublicKey) or public.key_size < 3072:
        raise ValueError("runner RSA key must be at least 3072 bits")
    if not isinstance(identity, dict) or set(identity) != {"run_id", "run_attempt", "workflow_sha", "request_sha256"}:
        raise ValueError("invalid run identity")
    associated = _json(identity)
    key, nonce = AESGCM.generate_key(bit_length=256), os.urandom(12)
    wrapped = public.encrypt(key, padding.OAEP(mgf=padding.MGF1(algorithm=hashes.SHA256()),
                                              algorithm=hashes.SHA256(), label=associated))
    ciphertext = AESGCM(key).encrypt(nonce, payload, associated)
    envelope = {"version": 1, "identity": identity, "key": _encode(wrapped),
                "nonce": _encode(nonce), "ciphertext": _encode(ciphertext)}
    result = subprocess.run(["ssh-keygen", "-Y", "sign", "-n", NAMESPACE, "-f", str(signing_key)],
                            input=_json(envelope), stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                            check=True, timeout=30)
    envelope["signature"] = result.stdout.decode("ascii")
    return _json(envelope)


def open_envelope(data, recipient_private_pem, expected_identity, trusted_ssh_public_key):
    """Authenticate before decrypting, reject replay and altered ciphertext."""
    if not isinstance(data, bytes) or len(data) > MAX_ENVELOPE:
        raise ValueError("invalid envelope size")
    envelope = json.loads(data)
    if (not isinstance(envelope, dict) or set(envelope) !=
            {"version", "identity", "key", "nonce", "ciphertext", "signature"} or
            envelope["version"] != 1 or envelope["identity"] != expected_identity):
        raise ValueError("result envelope identity mismatch")
    signature = envelope.pop("signature")
    if not isinstance(signature, str) or len(signature) > 16384:
        raise ValueError("invalid signature")
    if not isinstance(trusted_ssh_public_key, str) or "\n" in trusted_ssh_public_key or "\r" in trusted_ssh_public_key:
        raise ValueError("invalid trusted key")
    with tempfile.TemporaryDirectory(prefix="openclaw-result-verify-") as tmp:
        root = Path(tmp)
        allowed = root / "allowed_signers"
        allowed.write_text(IDENTITY + " " + trusted_ssh_public_key.strip() + "\n", encoding="utf-8")
        sigfile = root / "signature"
        sigfile.write_text(signature, encoding="ascii")
        result = subprocess.run(["ssh-keygen", "-Y", "verify", "-f", str(allowed), "-I", IDENTITY,
                                 "-n", NAMESPACE, "-s", str(sigfile)], input=_json(envelope),
                                stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)
    if result.returncode != 0:
        raise ValueError("gateway signature verification failed")
    private = serialization.load_pem_private_key(recipient_private_pem, password=None)
    if not isinstance(private, rsa.RSAPrivateKey) or private.key_size < 3072:
        raise ValueError("invalid runner private key")
    associated = _json(expected_identity)
    key = private.decrypt(_decode(envelope["key"]),
                          padding.OAEP(mgf=padding.MGF1(algorithm=hashes.SHA256()),
                                       algorithm=hashes.SHA256(), label=associated))
    return AESGCM(key).decrypt(_decode(envelope["nonce"]), _decode(envelope["ciphertext"]), associated)
