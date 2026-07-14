#!/usr/bin/env bash
# scripts/check_unbounded_queries.sh — grep guard (Gate G0), not a full analyzer.
#
# Fails when a .dart file streams/fetches a Firestore COLLECTION chain
# (collection()/where()/orderBy()) with no .limit( on the same statement.
# Single-document reads (.doc(id).get()/.snapshots()) are exempt.
#
# Opt out on a verified-bounded line with a trailing comment:
#     // perf-ignore: bounded-elsewhere
#
# Usage:
#   scripts/check_unbounded_queries.sh <file.dart> [file.dart ...]
#   git ls-files '*.dart' | xargs scripts/check_unbounded_queries.sh   # whole tree
set -u
status=0
for f in "$@"; do
  [ -f "$f" ] || continue
  # Lines that stream/fetch a collection chain but carry no .limit( and no opt-out.
  hits="$(grep -nE '\.(snapshots|get)\(\)' "$f" \
       | grep -vE '\.doc\(' \
       | grep -vE '\.limit\(' \
       | grep -vE 'perf-ignore: bounded-elsewhere' \
       | grep -E 'collection\(|where\(|orderBy\(' || true)"
  if [ -n "$hits" ]; then
    echo "Unbounded Firestore query in $f — add .limit() or // perf-ignore: bounded-elsewhere:"
    echo "$hits"
    status=1
  fi
done
exit $status
