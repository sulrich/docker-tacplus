# compilation container
FROM ubuntu:latest AS build_container

ARG DEBIAN_FRONTEND=noninteractive

# Update package lists and install ca-certificates first
RUN apt-get update && \
    apt-get install -y ca-certificates && \
      apt-get install -y \
        autoconf \
        automake \
        build-essential \
        bzip2 \
        cpanminus \
        curl \
        gcc \
        git \
        libc-ares-dev \
        libc6-dev \
        libcrypt-dev \
        libdigest-md5-perl \
        libio-socket-ssl-perl \
        libnet-ldap-perl \
        libpcap-dev \
        libpcre2-dev \
        libssl-dev \
        libtool \
        make \
        perl \
        pkg-config && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# clone the repository
RUN git clone https://github.com/MarcJHuber/event-driven-servers.git /src

WORKDIR /src

# Generate configure script if it doesn't exist, then build
RUN if [ ! -f ./configure ]; then autoreconf -fiv; fi && \
    ./configure --minimum --prefix=/tacacs tac_plus-ng && \
    env SHELL=/bin/bash make && \
    env SHELL=/bin/bash make install

# runtime container
FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y \
      ca-certificates \
      libc-ares2 \
      libdigest-md5-perl \
      libio-socket-ssl-perl \
      libnet-ldap-perl \
      libpcre2-8-0 \
      perl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy the tacacs binary
COPY --from=build_container /tacacs /tacacs
COPY tac_plus.cfg /etc/tac_plus/tac_plus.cfg
COPY docker-entry.sh /docker-entry.sh
COPY --from=build_container /tacacs /tacacs
COPY tac_plus.cfg /etc/tac_plus/tac_plus.cfg
COPY docker-entry.sh /docker-entry.sh

EXPOSE 49

ENTRYPOINT ["/docker-entry.sh"]
