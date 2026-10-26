#!/usr/bin/env bash
# smoke.sh <image> <version>: starts the image as syb.lol runs it (uid 1000, config read-only,
# syb.lol's config with a throwaway relay key), then checks NIP-11, a publish and a REQ.
set -euo pipefail
image=$1 v=$2
port=${PORT:-13131}
work=$(mktemp -d "${TMPDIR:-/tmp}/ditto-smoke.XXXXXX")
name="ditto-smoke-$$"
cleanup() {
  if [ "${ok:-}" != 1 ]; then echo "--- relay log"; docker logs "$name" 2>&1 | tail -50; fi
  docker rm -f "$name" >/dev/null 2>&1 || true
  rm -rf "$work"
}
trap cleanup EXIT

mkdir -p "$work/config"
cp "$(dirname "$0")/../test/ditto-relay.toml" "$work/config/"
relay_sk=$(nak key generate)
printf '%s' "$relay_sk" >"$work/config/secret.key"
chmod 755 "$work" "$work/config" && chmod 644 "$work/config/"*

docker run -d --name "$name" --user 1000:1000 -p "127.0.0.1:$port:13131" \
  -v "$work/config:/etc/ditto-relay:ro" --tmpfs /data:uid=1000,gid=1000 "$image" >/dev/null

info=""
for _ in $(seq 60); do
  info=$(curl -fsS -H 'Accept: application/nostr+json' "http://127.0.0.1:$port/" 2>/dev/null) && break
  sleep 1
done
[ -n "$info" ] || { echo "FAIL: no NIP-11 after 60 s"; exit 1; }
echo "NIP-11: $(jq -c '{name, version, supported_nips}' <<<"$info")"
[ "$(jq -r .version <<<"$info")" = "$v" ] || { echo "FAIL: NIP-11 version isn't $v"; exit 1; }
[ "$(jq -r .self <<<"$info")" = "$(nak key public "$relay_sk")" ] || { echo "FAIL: relay didn't use secret.key"; exit 1; }

# nak reads events or filters from stdin when it isn't a terminal, and does nothing on an
# empty pipe (as in a GitHub step), so every nak below gets /dev/null.
sk=$(nak key generate)
pub=$(nak event --sec "$sk" -k 1 -c "start test $v" "ws://127.0.0.1:$port" </dev/null 2>&1)
grep -q success <<<"$pub" || { echo "FAIL: publish: $pub"; exit 1; }
id=$(grep -m1 -o '"id":"[0-9a-f]*"' <<<"$pub" | cut -d'"' -f4)
got=$(nak req -k 1 -a "$(nak key public "$sk")" "ws://127.0.0.1:$port" </dev/null 2>/dev/null | jq -r .id)
[ "$got" = "$id" ] || { echo "FAIL: REQ didn't return the event (got '$got')"; exit 1; }
echo "publish + REQ: ok ($id)"

ok=1
echo "PASS: $image"
