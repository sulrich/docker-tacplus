# compilation container
FROM ubuntu:20.04 as build_container

LABEL name=tac_plus
LABEL version=0.1.0

ARG TACPLUS_VERSION
ARG TACPLUS_HASH

ADD "https://www.pro-bono-publico.de/projects/archive/DEVEL.${TACPLUS_VERSION}.tar.bz2" /tac_plus.tar.bz2
RUN echo "${TACPLUS_HASH}  /tac_plus.tar.bz2" | sha256sum -c -

RUN apt update &&                    \
    apt install -y                   \
      bzip2                          \
      gcc                            \
      libc6-dev                      \
      libdigest-md5-perl             \
      libio-socket-ssl-perl          \
      libnet-ldap-perl               \
      make &&                        \
    tar -xf /tac_plus.tar.bz2 &&     \
    cd PROJECTS &&                   \
    ./configure --prefix=/tacacs &&  \
    env SHELL=/bin/bash make &&      \
    env SHELL=/bin/bash make install


FROM ubuntu:20.04

LABEL maintainer="steve ulrich (sulrich@botwerks.org)"

COPY --from=build_container /tacacs /tacacs
COPY tac_plus.cfg /etc/tac_plus/tac_plus.cfg
COPY docker-entry.sh /docker-entry.sh

EXPOSE 49

ENTRYPOINT ["/docker-entry.sh"]
