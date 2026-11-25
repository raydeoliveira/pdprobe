FROM debian:bookworm-slim

ARG PDPROBE_VERSION=0.2.0
ARG PDPROBE_LINUX_SHA256=5e1dec78192deb11850dae2f07e5251f5ff4a3d14bc3778672e95f149ec5f857

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSL "https://github.com/raydeoliveira/pdprobe/releases/download/v${PDPROBE_VERSION}/pdprobe-${PDPROBE_VERSION}-linux-x86_64.tar.gz" -o /tmp/pdprobe.tar.gz \
    && echo "${PDPROBE_LINUX_SHA256}  /tmp/pdprobe.tar.gz" | sha256sum -c - \
    && tar -xzf /tmp/pdprobe.tar.gz -C /tmp \
    && install -m 0755 "/tmp/pdprobe-${PDPROBE_VERSION}-linux-x86_64/pdprobe" /usr/local/bin/pdprobe \
    && ln -sf pdprobe /usr/local/bin/pdctl \
    && rm -rf /tmp/pdprobe.tar.gz "/tmp/pdprobe-${PDPROBE_VERSION}-linux-x86_64" /var/lib/apt/lists/*

USER nobody
ENTRYPOINT ["pdprobe", "mcp"]
