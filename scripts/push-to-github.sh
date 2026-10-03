#!/usr/bin/env bash
# Usage: ./scripts/push-to-github.sh <github-username> [repo-name]
# Creates the repo with the GitHub CLI (if needed) and pushes main.
# Requires: git, gh (run `gh auth login` first). .env is git-ignored and is never pushed.
set -euo pipefail

user="${1:?usage: $0 <github-username> [repo-name]}"
repo="${2:-devops-platform}"

cd "$(dirname "$0")/.."

# Safety net: refuse to continue if a secret file would be committed.
if git ls-files --error-unmatch .env >/dev/null 2>&1; then
  echo ".env is tracked by git - remove it with: git rm --cached .env" >&2
  exit 1
fi

# Point Argo CD manifests at this repository.
url="https://github.com/${user}/${repo}.git"
sed -i.bak "s|REPO_URL|${url}|g" argocd/root-app.yaml argocd/apps/webapp.yaml && rm -f argocd/*.bak argocd/apps/*.bak
sed -i.bak "s|your-github-username|${user}|g" helm/webapp/values.yaml .env.example && rm -f helm/webapp/*.bak ./*.bak

[ -d .git ] || git init -b main
git add -A
git commit -m "Initial commit: DevOps platform" || true

if ! git remote get-url origin >/dev/null 2>&1; then
  gh repo create "${user}/${repo}" --public --source=. --remote=origin
fi

git push -u origin main
echo "Pushed to ${url}"
