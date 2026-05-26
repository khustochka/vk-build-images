# syntax=docker/dockerfile:1

# Build image for kjogvi: hexpm/elixir on debian + compilers, git, node.
# Consumed by the builder stage of kjogvi/Dockerfile.
#
# Independent from kjogvi-base: that one is debian:<DEBIAN_VERSION> for the
# runtime, while this one is hexpm/elixir:...-debian-<DEBIAN_VERSION>-... for
# the toolchain. They are kept on the same Debian release via DEBIAN_VERSION.

ARG ELIXIR_VERSION
ARG OTP_VERSION
ARG DEBIAN_VERSION
FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}

ARG BUILD_PACKAGES="build-essential git curl xz-utils"

ARG NODE_VERSION

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

# Preinstall hex + rebar so app builds don't repeat this every time.
RUN mix local.hex --force && mix local.rebar --force
