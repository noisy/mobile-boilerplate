#!/usr/bin/env bash
# Fails if a key, keystore or Firebase config file is about to be committed.
# Checks the files git tracks or would add (staged and untracked, not ignored).
# Prints only file names, never the matching text.
set -euo pipefail
cd "$(dirname "$0")/.."

files="$(git ls-files --cached --others --exclude-standard 2>/dev/null || true)"
[[ -n "$files" ]] || exit 0

status=0

# Files that must never be in the repo, whatever they contain.
forbidden='(\.(keystore|jks|p8|p12|pem|mobileprovision|cer|apk|aab|ipa)$|(^|/)(google-services\.json|GoogleService-Info\.plist|key\.properties|local\.properties|\.env)$)'
if bad="$(grep -E "$forbidden" <<<"$files")"; then
  echo "Never commit these files (keys, config, build outputs):" >&2
  sed 's/^/  /' <<<"$bad" >&2
  status=1
fi

# Content that looks like a real credential. Google API keys start with AIza;
# the Firebase templates use obvious placeholders instead.
patterns='-----BEGIN [A-Z ]*PRIVATE KEY-----|AIza[0-9A-Za-z_-]{35}|"private_key_id"|ghp_[0-9A-Za-z]{36}|github_pat_[0-9A-Za-z_]{40,}'
existing="$(while IFS= read -r f; do [[ -f "$f" ]] && printf '%s\n' "$f"; done <<<"$files")"
if [[ -n "$existing" ]] && bad="$(tr '\n' '\0' <<<"$existing" | xargs -0 grep -IlE -- "$patterns" | grep -v '^scripts/check_no_secrets.sh$' || true)" && [[ -n "$bad" ]]; then
  echo "These files look like they contain a key or token (text not shown):" >&2
  sed 's/^/  /' <<<"$bad" >&2
  status=1
fi

[[ $status -eq 0 ]] && echo "No secrets found."
exit $status
