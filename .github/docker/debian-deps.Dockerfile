# syntax=docker/dockerfile:1.7

FROM debian:bookworm-slim

ARG TARGETARCH
ARG TARGETVARIANT

RUN --mount=type=bind,source=binaries,target=/tmp/fileuni-binaries,ro set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      ffmpeg \
      imagemagick \
      iproute2 \
      iputils-ping \
      libvips-tools \
      latexmk \
      net-tools \
      p7zip-full \
      texlive-xetex \
      tzdata; \
    rm -rf /var/lib/apt/lists/*; \
    case "${TARGETARCH}${TARGETVARIANT:+/${TARGETVARIANT}}" in \
      amd64) src="/tmp/fileuni-binaries/amd64/fileuni" ;; \
      386) src="/tmp/fileuni-binaries/386/fileuni" ;; \
      arm64) src="/tmp/fileuni-binaries/arm64/fileuni" ;; \
      arm/v7) src="/tmp/fileuni-binaries/armv7/fileuni" ;; \
      *) echo "Unsupported Docker target: ${TARGETARCH}${TARGETVARIANT:+/${TARGETVARIANT}}" >&2; exit 1 ;; \
    esac; \
    install -Dm0755 "${src}" /usr/local/bin/fileuni

ENTRYPOINT ["/usr/local/bin/fileuni"]
