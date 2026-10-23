#!/bin/sh
set -eu
# Credentials are runtime-only, copied from a read-only mount into tmpfs.
umask 077
mkdir -p /run/tlc-ssh
if [ ! -f /run/tlc-ssh/id_ed25519 ]; then
  cp /run/host-key/id_ed25519 /run/tlc-ssh/id_ed25519
  chmod 600 /run/tlc-ssh/id_ed25519
fi
mode=${1:-status}
case "$mode" in
  status) remote='hostname; uname -m; df -B1 /home/codex/tlc-integration/sdk35-runtime-build; free -m; docker --context default ps --format "{{.Names}} {{.Status}}"' ;;
  inventory) remote='cd /home/codex/tlc-integration/sdk35-runtime-build && python3 ensure-sdk35-dev-modules.py --root /home/codex/tlc-integration/sdk35-runtime-build' ;;
  graph) remote='cd /home/codex/tlc-integration/sdk35-runtime-build && bash run-sdk35-runtime-stage.sh graph' ;;
  *) echo 'Usage: tlc-arm64-controller.sh status|inventory|graph' >&2; exit 64 ;;
esac
exec ssh -T -i /run/tlc-ssh/id_ed25519 -o IdentitiesOnly=yes -o BatchMode=yes \
  -o StrictHostKeyChecking=yes -o HostKeyAlias="${TLC_ARM64_HOST_KEY_ALIAS:?Set host key alias}" -o UserKnownHostsFile=/run/host-key/known_hosts \
  -o ConnectTimeout=15 -p "${TLC_ARM64_PORT:-2222}" "${TLC_ARM64_USER:-codex}@${TLC_ARM64_HOST:?Set host}" "$remote"
