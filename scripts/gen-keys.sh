#!/usr/bin/env bash
# Generates an SSH key pair and stores both halves (base64) in .env.
# The key files themselves are deleted afterwards so nothing sensitive lands in git.
set -euo pipefail

cd "$(dirname "$0")/.."

command -v ssh-keygen >/dev/null 2>&1 || {
  echo "ssh-keygen not found. Install OpenSSH client (e.g. 'sudo apt install openssh-client') and re-run." >&2
  exit 1
}

[ -f .env ] || cp .env.example .env

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

ssh-keygen -t ed25519 -N "" -C "devops-platform" -f "$tmp/key" >/dev/null

pub="$(base64 -w0 "$tmp/key.pub" 2>/dev/null || base64 "$tmp/key.pub" | tr -d '\n')"
priv="$(base64 -w0 "$tmp/key" 2>/dev/null || base64 "$tmp/key" | tr -d '\n')"

set_var() {
  if grep -q "^$1=" .env; then
    sed -i.bak "s|^$1=.*|$1=$2|" .env && rm -f .env.bak
  else
    echo "$1=$2" >> .env
  fi
}

set_var SSH_PUBLIC_KEY_B64 "$pub"
set_var SSH_PRIVATE_KEY_B64 "$priv"

echo "Keys written to .env (SSH_PUBLIC_KEY_B64 / SSH_PRIVATE_KEY_B64)."
echo "Decode with: echo \"\$SSH_PRIVATE_KEY_B64\" | base64 -d > ~/.ssh/devops_platform && chmod 600 ~/.ssh/devops_platform"
