# syntax=docker/dockerfile:1.7

FROM debian:bookworm-slim

ARG TARGETARCH
ARG TARGETVARIANT

COPY binaries/ /tmp/fileuni-binaries/

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
      ffmpeg \
      imagemagick \
      libvips-tools \
      p7zip-full \
      tzdata; \
    rm -rf /var/lib/apt/lists/*; \
    case "${TARGETARCH}${TARGETVARIANT:+/${TARGETVARIANT}}" in \
      amd64) src="/tmp/fileuni-binaries/amd64/fileuni" ;; \
      arm64) src="/tmp/fileuni-binaries/arm64/fileuni" ;; \
      arm/v7) src="/tmp/fileuni-binaries/armv7/fileuni" ;; \
      *) echo "Unsupported Docker target: ${TARGETARCH}${TARGETVARIANT:+/${TARGETVARIANT}}" >&2; exit 1 ;; \
    esac; \
    install -Dm0755 "${src}" /usr/local/bin/fileuni; \
    rm -rf /tmp/fileuni-binaries

ENTRYPOINT ["/usr/local/bin/fileuni"]
