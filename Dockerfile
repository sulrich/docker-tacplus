# compilation container
FROM ubuntu:latest AS build_container

ARG DEBIAN_FRONTEND=noninteractive
ARG TACPLUS_VERSION
ARG TACPLUS_HASH

# update package lists and install ca-certificates first
RUN apt-get update && \
    apt-get install -y \
      autoconf \
      automake \
      build-essential \
      bzip2 \
      ca-certificates \
      gcc \
      git \
      libc6-dev \
      libcrypt-dev \
      libpam0g-dev \
      libpcre2-dev \
      libssl-dev \
      libtool \
      make \
      pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# clone the repository and pin to the specified version
RUN git clone https://github.com/MarcJHuber/event-driven-servers.git /src && \
    if [ -n "${TACPLUS_VERSION}" ]; then \
      cd /src && git checkout "${TACPLUS_VERSION}" 2>/dev/null || true; \
    fi

WORKDIR /src

# generate configure script if it doesn't exist, then build
RUN if [ ! -f ./configure ]; then autoreconf -fiv; fi && \
    ./configure --minimum --prefix=/tacacs tac_plus && \
    env SHELL=/bin/bash make && \
    env SHELL=/bin/bash make install

# runtime container
FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y \
      libcrypt1 \
      libpam0g \
      libpcre2-8-0 \
      libssl3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# copy the tacacs binary and simple config
COPY --from=build_container /tacacs /tacacs
COPY tac_plus.cfg /etc/tac_plus/tac_plus.cfg
COPY docker-entry.sh /docker-entry.sh

EXPOSE 49

ENTRYPOINT ["/docker-entry.sh"]
