#!/usr/bin/env bash
# plan.sh <releases file> [version]: prints a JSON list of {version, tags} to build. With no
# version, every release from FLOOR on that isn't on ghcr yet. A version gets its minor tag
# (2.5) and major tag (2) only while it's the newest release of that line, so an older build
# never moves them back, and a new major (3.0.0) never moves 2.
set -euo pipefail
releases=$1 want=${2:-}
repo=${IMAGE:-ghcr.io/sybenx/ditto-relay}
floor=${FLOOR:-2.5.1}

newer_or_same() { [ "$(printf '%s\n%s\n' "$1" "$2" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)" = "$1" ]; }
newest_of() { cut -f1 "$releases" | grep -E "^$(sed 's/\./\\./g' <<<"$1")\." | sort -t. -k1,1n -k2,2n -k3,3n | tail -1; }

out="[]"
while IFS=$'\t' read -r v _; do
  if [ -n "$want" ]; then
    [ "$v" = "$want" ] || continue
  else
    newer_or_same "$v" "$floor" || continue
    docker manifest inspect "$repo:$v" </dev/null >/dev/null 2>&1 && continue
  fi
  minor=${v%.*} major=${v%%.*}
  tags="$repo:$v"
  [ "$(newest_of "$minor")" = "$v" ] && tags="$tags,$repo:$minor"
  [ "$(newest_of "$major")" = "$v" ] && tags="$tags,$repo:$major"
  out=$(jq -c --arg v "$v" --arg t "$tags" '. + [{version: $v, tags: $t}]' <<<"$out")
done <"$releases"

if [ -n "$want" ] && [ "$out" = "[]" ]; then echo "no signed release $want" >&2; exit 1; fi
echo "$out"
