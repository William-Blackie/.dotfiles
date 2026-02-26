#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

FAIL=0

report_match() {
  local label="$1"
  local pattern="$2"

  if rg -n --hidden --no-ignore-vcs --glob '!.git/**' --glob '!.DS_Store' --glob '!*.png' --glob '!*.jpg' --glob '!*.jpeg' --glob '!*.gif' --glob '!*.svg' -e "$pattern" .; then
    echo "FAIL: potential secret detected ($label)"
    FAIL=1
  else
    echo "PASS: no $label found"
  fi
}

echo "Scanning repository for sensitive patterns..."
report_match "private key block" '-----BEGIN (EC|RSA|OPENSSH|DSA|PGP) PRIVATE KEY-----'
report_match "AWS access key" 'AKIA[0-9A-Z]{16}'
report_match "AWS temporary key" 'ASIA[0-9A-Z]{16}'
report_match "GitHub personal access token" 'ghp_[A-Za-z0-9]{36}'
report_match "GitHub fine-grained token" 'github_pat_[A-Za-z0-9_]{40,}'
report_match "Google API key" 'AIza[0-9A-Za-z_-]{35}'
report_match "Slack token" 'xox[baprs]-[A-Za-z0-9-]{10,}'
report_match "Stripe live key" 'sk_live_[0-9A-Za-z]{20,}'

echo "Checking for sensitive key file extensions..."
if git ls-files | rg -n '\.(pem|key|p12|pfx|jks)$'; then
  echo "FAIL: tracked key/certificate-like file extension detected"
  FAIL=1
else
  echo "PASS: no tracked key/certificate-like files"
fi

if command -v gitleaks > /dev/null 2>&1; then
  echo "Running gitleaks history scan..."
  if gitleaks detect --source . --no-banner --redact; then
    echo "PASS: gitleaks found no leaks"
  else
    echo "FAIL: gitleaks found potential leaks"
    FAIL=1
  fi
else
  echo "WARN: gitleaks not installed; skipping history scan"
fi

if [[ "$FAIL" -ne 0 ]]; then
  echo "Secret scan failed."
  exit 1
fi

echo "Secret scan passed."
