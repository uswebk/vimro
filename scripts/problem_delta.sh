#!/usr/bin/env bash
# Summarize problems added between a previous ref and HEAD, for release notes.
#
#   scripts/problem_delta.sh v1.2.1
#
# Prints nothing when no problems were added.
set -euo pipefail

prev="${1:-}"
[ -n "$prev" ] || exit 0

added=$(git diff --diff-filter=A --name-only "$prev" HEAD -- 'problems/*/*.json' || true)
[ -n "$added" ] || exit 0

count=$(printf '%s\n' "$added" | wc -l | tr -d ' ')
by_category=$(printf '%s\n' "$added" | cut -d/ -f2 | sort | uniq -c |
  awk '{ printf "%s%s: %s", sep, $2, $1; sep = ", " }')
total=$(git ls-files 'problems/*/*.json' | wc -l | tr -d ' ')

printf '\n## Problems\n\n+%s problems (%s) — %s total\n' "$count" "$by_category" "$total"
