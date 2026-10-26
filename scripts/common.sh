# Shared by the scripts: who signs Ditto Relay releases and where they're published.
SOAPBOX=781a1527055f74c1f70230f10384609b34548f8ab6a0a6caa74025827f9fdae5 # soapbox.pub (_@soapbox.pub)
RELAYS="wss://relay.ditto.pub wss://git.shakespeare.diy wss://relay.ngit.dev wss://relay.primal.net"
# nakq req <filter flags>: asks each relay on its own, 30 s each, so one relay that never
# sends EOSE (or refuses GitHub's runners) can't hang a run or hide the others' answers.
nakq() {
  local r
  for r in $RELAYS; do
    within 30 nak "$@" "$r" || echo "no full answer from $r" >&2
  done
}

# within <seconds> <command…>: runs it, killing it if it's still going after that long.
within() {
  local t=$1 pid watcher rc
  shift
  "$@" &
  pid=$!
  (sleep "$t"; kill "$pid" 2>/dev/null) >/dev/null 2>&1 &
  watcher=$!
  wait "$pid" && rc=0 || rc=$?
  { kill "$watcher" && wait "$watcher"; } 2>/dev/null || true
  return "$rc"
}
