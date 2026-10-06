#!/usr/bin/env bash
# Fails when the bundled checklist differs from the published docs page.
set -euo pipefail
url="https://www.digia.tech/docs/developer/integration-checklist.md"
bundled="skills/setup-digia-engage/references/checklist.md"
live="$(mktemp)"
status="$(curl -sSL -o "$live" -w '%{http_code}' "$url")"
if [ "$status" != "200" ]; then
  echo "::warning::$url returned $status. Drift check skipped."
  exit 0
fi
if ! diff -u "$bundled" "$live"; then
  echo "::error::$bundled differs from $url. Copy the published page into $bundled."
  exit 1
fi
echo "Bundled checklist matches $url."
