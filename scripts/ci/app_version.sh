#!/usr/bin/env bash
# Prints the human version from pubspec.yaml (e.g. 0.1.0). Bump it there.
set -euo pipefail
sed -n 's/^version: *\([0-9][0-9.]*\).*/\1/p' pubspec.yaml
