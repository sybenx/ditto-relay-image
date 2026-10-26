#!/usr/bin/env bash
# fetch.sh <version> <dir>: downloads that release's x86_64 Linux binary into <dir>, after
# checking the release event and its asset event (kind 3063) are signed by soapbox.pub, and
# the file's SHA-256 and size against the asset event. Prints "binary=… sha256=…" lines.
set -euo pipefail
. "$(dirname "$0")/common.sh"
v=$1 dir=$2
file="ditto-relay-$v-linux-x86_64"

rel=$(nakq req -k 30063 -a "$SOAPBOX" -t d="ditto-relay@$v" $RELAYS 2>/dev/null | jq -cs '.[0] // empty')
[ -n "$rel" ] || { echo "no release event for $v" >&2; exit 1; }
nak verify <<<"$rel" >/dev/null || { echo "release event signature is bad" >&2; exit 1; }
[ "$(jq -r .pubkey <<<"$rel")" = "$SOAPBOX" ] || { echo "release event not by soapbox.pub" >&2; exit 1; }

asset=""
for id in $(jq -r '.tags[] | select(.[0]=="e") | .[1]' <<<"$rel"); do
  ev=$(nakq req -i "$id" $RELAYS 2>/dev/null | jq -cs '.[0] // empty')
  [ -n "$ev" ] || continue
  [ "$(jq -r '[.kind, .pubkey, (.tags[]|select(.[0]=="filename")|.[1])] | @tsv' <<<"$ev")" = "3063	$SOAPBOX	$file" ] || continue
  nak verify <<<"$ev" >/dev/null || { echo "asset event signature is bad" >&2; exit 1; }
  asset=$ev
  break
done
[ -n "$asset" ] || { echo "no signed asset event for $file" >&2; exit 1; }

tag() { jq -r --arg k "$1" 'first(.tags[] | select(.[0]==$k) | .[1]) // empty' <<<"$asset"; }
sha=$(tag x) size=$(tag size) url=$(tag url)
[[ $sha =~ ^[0-9a-f]{64}$ ]] || { echo "asset event has no sha256" >&2; exit 1; }
[ "$(tag version)" = "$v" ] || { echo "asset event is for another version" >&2; exit 1; }

mkdir -p "$dir"
curl -fsSL --retry 3 --connect-timeout 20 --max-time 900 -o "$dir/$file" "$url"
[ "$(sha256sum "$dir/$file" | cut -d" " -f1)" = "$sha" ] || { echo "SHA-256 differs from the asset event" >&2; exit 1; }
[ "$(wc -c <"$dir/$file" | tr -d ' ')" = "$size" ] || { echo "size differs from the asset event" >&2; exit 1; }

echo "binary=$file"
echo "sha256=$sha"
