# syntax=docker/dockerfile:1

# Base image for quails: ruby + runtime OS packages.
# Consumed by the final stage of quails/Dockerfile.
# Contains no app-specific config (no user, no WORKDIR, no env tuning).

ARG RUBY_VERSION=4.0.4
ARG VARIANT=slim-trixie
FROM ruby:${RUBY_VERSION}-${VARIANT}

ARG DEPLOY_PACKAGES="libvips42 libjpeg62-turbo libjemalloc2 file curl gzip bzip2"
ARG DEBUG_PACKAGES="postgresql-client net-tools netcat-openbsd bind9-dnsutils procps"
ARG DEBUG=false

RUN --mount=type=cache,id=base-apt-cache,sharing=locked,target=/var/cache/apt \
    --mount=type=cache,id=base-apt-lib,sharing=locked,target=/var/lib/apt \
    apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    ${DEPLOY_PACKAGES} $(if [ "${DEBUG}" = "true" ]; then echo ${DEBUG_PACKAGES}; else echo ""; fi) \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

RUN gem update --system --no-document
