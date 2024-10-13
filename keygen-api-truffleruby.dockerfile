# syntax=docker/dockerfile:1

ARG GRAALVM_VERSION=24.1.0

# Build image
FROM ghcr.io/graalvm/truffleruby-community:${GRAALVM_VERSION}-debian AS build
ARG GRAALVM_VERSION

ENV BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_DEPLOYMENT="1" \
    RAILS_ENV="production"

RUN apt-get update && apt-get install -y --no-install-recommends \
  git \
  build-essential \
  libxml2-dev \
  libxslt-dev \
  tzdata \
  openssl \
  libpq-dev

WORKDIR /app
COPY ./Gemfile /app/Gemfile
COPY ./Gemfile.lock /app/Gemfile.lock

RUN \
  bundle config --global without "${BUNDLE_WITHOUT}"  && \
  bundle config --global path "${BUNDLE_PATH}" && \
  bundle config --global deployment "${BUNDLE_DEPLOYMENT}" && \
  bundle config --global retry 5 && \
  bundle install && \
  find /usr/local/bundle/ /opt/truffleruby-${GRAALVM_VERSION} \
    \( \
      -name "*.c" -o \
      -name "*.o" -o \
      -name "*.a" -o \
      -name "*.h" -o \
      -name "Makefile" -o \
      -name "*.md" \
    \) -delete && \
  chmod -R a+r "${BUNDLE_PATH}"

# Runtime Stage
FROM debian:sid-slim
ARG GRAALVM_VERSION

LABEL maintainer="keygen.sh <oss@keygen.sh>"

ENV BUNDLE_WITHOUT="development:test" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_DEPLOYMENT="1" \
    RAILS_ENV="production" \
    LANG=en_US.UTF-8

# Runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
  postgresql-client \
  tzdata \
  ca-certificates libyaml-0-2 zlib1g libssl3t64 libc6 && \
# Add keygen user
  groupadd -g 1000 keygen && \
  useradd -m -d /app -g keygen -u 1000 keygen && \
# Setup gmrc for the keygen user
  echo "gem: --no-document" > ~/.gemrc && \
# cleanup
  apt-get autopurge -y && \
  apt-get clean && \
  rm -rf /tmp/*

# Install truffleruby from the build image
COPY --from=build /usr/lib/locale /usr/lib/locale
COPY --from=build /opt/truffleruby-$GRAALVM_VERSION /opt/truffleruby-$GRAALVM_VERSION
ENV PATH=/opt/truffleruby-$GRAALVM_VERSION/bin:$PATH

# Copy keygen bundle
COPY --from=build --chown=keygen:keygen \
  /usr/local/bundle/ /usr/local/bundle

WORKDIR /app
COPY . /app

RUN chmod +x /app/scripts/entrypoint.sh && \
  chown -R keygen:keygen /app

ENV KEYGEN_EDITION="CE" \
    KEYGEN_MODE="singleplayer" \
    RAILS_LOG_TO_STDOUT="1" \
    PORT="3000" \
    BIND="0.0.0.0" \
    RUBY_YJIT_ENABLE=0 \
    RUBYOPT= \
    WEB_CONCURRENCY=0

USER keygen

ENTRYPOINT ["/app/scripts/entrypoint.sh"]
CMD ["web"]
