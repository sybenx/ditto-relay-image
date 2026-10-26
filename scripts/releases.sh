#!/usr/bin/env bash
# Lists Ditto Relay's stable releases, oldest first, one "version<TAB>release event id" a line.
# Only NIP-82 release events (kind 30063) signed by soapbox.pub whose signature checks out.
set -euo pipefail
. "$(dirname "$0")/common.sh"

nakq req -k 30063 -a "$SOAPBOX" -t i=ditto-relay $RELAYS 2>/dev/null |
  while read -r ev; do
    [ "$(jq -r .pubkey <<<"$ev")" = "$SOAPBOX" ] || continue
    nak verify <<<"$ev" >/dev/null 2>&1 || { echo "bad signature: $(jq -r .id <<<"$ev")" >&2; continue; }
    v=$(jq -r 'first(.tags[] | select(.[0]=="version") | .[1]) // empty' <<<"$ev")
    d=$(jq -r 'first(.tags[] | select(.[0]=="d") | .[1]) // empty' <<<"$ev")
    [[ $v =~ ^[0-9]+\.[0-9]+\.[0-9]+$ && $d == "ditto-relay@$v" ]] || continue
    printf '%s\t%s\n' "$v" "$(jq -r .id <<<"$ev")"
  done | sort -u -t$'\t' -k1,1 | sort -t. -k1,1n -k2,2n -k3,3n
