# compilation container
FROM ubuntu:latest AS build_container

ARG TACPLUS_VERSION=master
ARG DEBIAN_FRONTEND=noninteractive

# install git and build dependencies
RUN apt update && \
    apt install -y \
      git \
      bzip2 \
      gcc \
      libc6-dev \
      libdigest-md5-perl \
      libio-socket-ssl-perl \
      libnet-ldap-perl \
      make && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

# clone the repository
RUN git clone https://github.com/MarcJHuber/event-driven-servers.git /src

# build tacacs+
WORKDIR /src
RUN ./configure --prefix=/tacacs && \
    env SHELL=/bin/bash make && \
    env SHELL=/bin/bash make install

# runtime container
FROM ubuntu:latest

LABEL maintainer="steve ulrich (sulrich@botwerks.org)"

# install runtime dependencies
RUN apt update && \
    apt install -y \
      libdigest-md5-perl \
      libio-socket-ssl-perl \
      libnet-ldap-perl && \
    apt clean && \
    rm -rf /var/lib/apt/lists/*

COPY --from=build_container /tacacs /tacacs
COPY tac_plus.cfg /etc/tac_plus/tac_plus.cfg
COPY docker-entry.sh /docker-entry.sh

EXPOSE 49

ENTRYPOINT ["/docker-entry.sh"]
