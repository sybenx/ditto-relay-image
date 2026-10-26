# syntax=docker/dockerfile:1
# Ditto Relay 2.x from the official static binary (NIP-82 release signed by
# soapbox.pub). The workflow downloads the binary into bin/ after checking the
# release and asset event signatures and the SHA-256; it's checked again here.
# The same file syb.lol built from by hand, up to 2.5.1.
FROM debian:bookworm-slim
ARG BINARY=ditto-relay-2.5.1-linux-x86_64
ARG SHA256=230193687fce6fd786ffc57f55c70b6d854df3e8eb3cdadf6f4eff4ab0cce773
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --system --uid 10001 --home /data ditto-relay \
    && mkdir /data && chown ditto-relay /data
COPY bin/${BINARY} /usr/local/bin/ditto-relay
RUN echo "${SHA256}  /usr/local/bin/ditto-relay" | sha256sum -c && chmod 755 /usr/local/bin/ditto-relay
USER ditto-relay
EXPOSE 13131
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s CMD curl -fsS http://127.0.0.1:13131/ >/dev/null || exit 1
ENTRYPOINT ["ditto-relay", "--config", "/etc/ditto-relay/ditto-relay.toml"]
