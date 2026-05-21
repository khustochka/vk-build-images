# syntax=docker/dockerfile:1

# Build image for quails: base + compilers, headers, node, yarn.
# Consumed by the gems/assets stages of quails/Dockerfile.

ARG BASE_IMAGE
FROM ${BASE_IMAGE}

ARG BUILD_PACKAGES="git build-essential libpq-dev libjpeg62-turbo-dev wget curl gzip xz-utils libsqlite3-dev libssl-dev libyaml-dev"

ARG NODE_VERSION
ARG YARN_VERSION=1.22.22

RUN --mount=type=cache,id=build-apt-cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=build-apt-lib,sharing=locked,target=/var/lib/apt \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y ${BUILD_PACKAGES} \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Node.js from the official binary distribution.
# Pinned exactly to NODE_VERSION; arch is auto-detected so the same Dockerfile
# works on amd64 and arm64 builders.
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
        amd64) node_arch="x64" ;; \
        arm64) node_arch="arm64" ;; \
        *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    tarball="node-v${NODE_VERSION}-linux-${node_arch}.tar.xz"; \
    curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/${tarball}"; \
    curl -fsSLO "https://nodejs.org/dist/v${NODE_VERSION}/SHASUMS256.txt"; \
    grep " ${tarball}\$" SHASUMS256.txt | sha256sum -c -; \
    tar -xJf "${tarball}" -C /usr/local --strip-components=1 --no-same-owner \
        --exclude=CHANGELOG.md --exclude=LICENSE --exclude=README.md; \
    rm "${tarball}" SHASUMS256.txt; \
    node --version; \
    npm --version

RUN npm install --global yarn@${YARN_VERSION}
