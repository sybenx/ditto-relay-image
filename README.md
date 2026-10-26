# ditto-relay image

`ghcr.io/sybenx/ditto-relay`: [Ditto Relay](https://gitworkshop.dev/soapbox.pub/ditto-relay)'s
official static binary in a small Debian image. It's built by a GitHub job, not from source:
the binary is soapbox.pub's own, checked against their signed release.

Tags: `2.5.1` (exact), `2.5` (newest 2.5.x), `2` (newest 2.x; a 3.0 release never moves it).
Pin `2.5` to get fixes on Update and change the tag yourself for a new minor.

## How a release gets here

Daily (and on demand from the Actions tab), [the workflow](.github/workflows/image.yml):

1. finds Ditto Relay releases: NIP-82 release events (kind 30063) by soapbox.pub
   (`781a1527…`, `_@soapbox.pub`), with their signatures checked (`scripts/releases.sh`);
2. for one not on ghcr yet, finds its signed asset event (kind 3063) for the x86_64 Linux
   binary, downloads it and checks the SHA-256 and size from that event (`scripts/fetch.sh`);
3. builds the [Dockerfile](Dockerfile), which checks the SHA-256 again;
4. starts the image as syb.lol runs it (uid 1000, read-only config, syb.lol's
   [config](test/ditto-relay.toml) with a throwaway relay key made in CI) and checks NIP-11,
   one publish and one REQ (`scripts/smoke.sh`);
5. only then pushes the tags. A failure publishes nothing and opens an issue.

Only x86_64 for now. No secrets from any server are in this repo or in CI.

## Running it

```yaml
services:
  relay:
    image: ghcr.io/sybenx/ditto-relay:2.5
    user: "1000:1000"
    volumes:
      - ./config:/etc/ditto-relay:ro   # ditto-relay.toml (+ secret.key)
      - ./data:/data
    ulimits:
      nofile: { soft: 65536, hard: 65536 }
    restart: unless-stopped
```
