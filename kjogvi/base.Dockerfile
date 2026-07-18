# syntax=docker/dockerfile:1

# Base image for kjogvi: debian + runtime OS packages.
# Consumed by the final stage of kjogvi/Dockerfile.
# Contains no app-specific config (no user, no WORKDIR, no env tuning).

ARG DEBIAN_VERSION=
FROM debian:${DEBIAN_VERSION}

ARG DEPLOY_PACKAGES="libsctp1 libvips42 libstdc++6 openssl libncurses6 locales ca-certificates postgresql-client file curl gzip bzip2"
ARG DEBUG_PACKAGES="net-tools netcat-openbsd bind9-dnsutils procps"
ARG DEBUG=false

RUN --mount=type=cache,id=base-apt-cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=base-apt-lib,sharing=locked,target=/var/lib/apt \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    ${DEPLOY_PACKAGES} $(if [ "${DEBUG}" = "true" ]; then echo ${DEBUG_PACKAGES}; else echo ""; fi) \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Generate en_US.UTF-8 locale so the release can set LANG/LC_ALL at runtime.
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen
