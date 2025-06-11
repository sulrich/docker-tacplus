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

# Install required Perl modules in groups to handle dependencies better
RUN cpanm --notest \
    Authen::Simple::RADIUS \
    Data::Radius \
    Net::TacacsPlus

# Install network-related modules that may need special handling
RUN cpanm --notest \
    Net::Frame::Simple \
    Net::Frame::Layer::IPv4 \
    Net::Frame::Layer::IPv6 \
    Net::Frame::Layer::UDP \
    Net::IP

# Install modules that require compilation (may fail in some environments)
RUN cpanm --notest \
    Crypt::Passwd::XS || echo "Crypt::Passwd::XS failed, continuing without it"

# Install raw network modules (often problematic)
RUN cpanm --notest \
    Net::RawIP \
    Net::Write::Layer \
    Net::TacacsPlus  \
    Net::Write::Layer3 || echo "Raw network modules failed, continuing without them"
# List Perl installation paths for debugging
RUN echo "=== Perl installation paths ===" && \
    perl -V:installsitearch -V:installsitelib -V:installvendorarch -V:installvendorlib && \
    find /usr -name "perl*" -type d 2>/dev/null | head -20

# clone the repository
RUN git clone https://github.com/MarcJHuber/event-driven-servers.git /src

WORKDIR /src

# Generate configure script if it doesn't exist, then build
RUN if [ ! -f ./configure ]; then autoreconf -fiv; fi && \
    ./configure --prefix=/tacacs && \
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

# Copy Perl modules from build container - only copy directories that exist
RUN mkdir -p /usr/local/lib /usr/local/share /usr/share /usr/lib

# Copy Perl directories using shell commands to handle missing paths gracefully
RUN --mount=from=build_container,source=/usr/local,target=/mnt/usr_local \
    --mount=from=build_container,source=/usr/share,target=/mnt/usr_share \
    --mount=from=build_container,source=/usr/lib,target=/mnt/usr_lib \
    if [ -d /mnt/usr_local/lib/x86_64-linux-gnu/perl ]; then \
        cp -r /mnt/usr_local/lib/x86_64-linux-gnu/perl* /usr/local/lib/x86_64-linux-gnu/ 2>/dev/null || true; \
    fi && \
    if [ -d /mnt/usr_local/share/perl ]; then \
        cp -r /mnt/usr_local/share/perl* /usr/local/share/ 2>/dev/null || true; \
    fi && \
    if [ -d /mnt/usr_share/perl5 ]; then \
        cp -r /mnt/usr_share/perl* /usr/share/ 2>/dev/null || true; \
    fi && \
    if [ -d /mnt/usr_lib/x86_64-linux-gnu/perl5 ]; then \
        cp -r /mnt/usr_lib/x86_64-linux-gnu/perl* /usr/lib/x86_64-linux-gnu/ 2>/dev/null || true; \
    fi

# Copy the tacacs binary
COPY --from=build_container /tacacs /tacacs
COPY tac_plus.cfg /etc/tac_plus/tac_plus.cfg
COPY docker-entry.sh /docker-entry.sh
COPY --from=build_container /tacacs /tacacs
COPY tac_plus.cfg /etc/tac_plus/tac_plus.cfg
COPY docker-entry.sh /docker-entry.sh

EXPOSE 49

ENTRYPOINT ["/docker-entry.sh"]
