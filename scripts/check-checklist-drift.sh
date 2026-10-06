#!/usr/bin/env bash
# Fails when the bundled checklist differs from the de_docs source page.
set -euo pipefail
src="Digia-Technology-Private-Limited/de_docs/contents/docs/developer/integration-checklist.mdx"
bundled="skills/setup-digia-engage/references/checklist.md"
live="$(mktemp)"
if ! gh api -H "Accept: application/vnd.github.raw" "repos/$src" > "$live.mdx" 2>/dev/null; then
  echo "::warning::Cannot read $src. Drift check skipped."
  exit 0
fi
# Strip the frontmatter and make relative doc links absolute, as in the bundled copy.
awk 'n>=2 {print} /^---$/ && n<2 {n++}' "$live.mdx" \
  | sed 's#(\./\([a-z/-]*\)\.mdx)#(https://www.digia.tech/docs/developer/\1)#g' > "$live"
if ! diff -u "$bundled" "$live"; then
  echo "::error::$bundled differs from $src. Run this script's transform and commit the result."
  exit 1
fi
echo "Bundled checklist matches $src."
