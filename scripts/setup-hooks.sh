#!/usr/bin/env bash
# One-time setup after cloning: use the repo's git hooks.
set -euo pipefail
cd "$(dirname "$0")/.."
git config core.hooksPath .githooks
chmod +x .githooks/* scripts/*.sh scripts/*.py scripts/ci/*.sh scripts/dev/*.sh
echo "Git hooks enabled: pre-commit (secrets, format, analyze), pre-push (full check)."
