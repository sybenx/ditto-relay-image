# Shared by the scripts: who signs Ditto Relay releases and where they're published.
SOAPBOX=781a1527055f74c1f70230f10384609b34548f8ab6a0a6caa74025827f9fdae5 # soapbox.pub (_@soapbox.pub)
RELAYS="wss://relay.ditto.pub wss://git.shakespeare.diy wss://relay.ngit.dev"
# nak with a time limit, so one relay that never sends EOSE can't hang a run.
nakq() { if command -v timeout >/dev/null; then timeout 60 nak "$@"; else nak "$@"; fi; }
