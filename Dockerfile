FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y \
    build-essential \
    autoconf \
    automake \
    libtool \
    pkg-config \
    curl \
    libssl-dev \
    libcurl4-openssl-dev \
    libc-ares-dev \
    libncurses-dev \
    libxml2-dev \
    libxmlrpc-core-c3-dev \
    libsigc++-2.0-dev \
    zlib1g-dev \
    libudns-dev \
    && rm -rf /var/lib/apt/lists/*

RUN LIBTORRENT_VERSION=$(curl -s https://api.github.com/repos/rakshasa/libtorrent/tags | grep '"name"' | head -1 | cut -d'"' -f4) && \
    curl -L "https://github.com/rakshasa/libtorrent/archive/refs/tags/${LIBTORRENT_VERSION}.tar.gz" | tar xz && \
    cd libtorrent-${LIBTORRENT_VERSION#v} && \
    autoreconf -fi && \
    ./configure --enable-udns --with-posix-fallocate --disable-debug && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /libtorrent-*

RUN ldconfig

RUN RTORRENT_VERSION=$(curl -s https://api.github.com/repos/rakshasa/rtorrent/tags | grep '"name"' | head -1 | cut -d'"' -f4) && \
    curl -L "https://github.com/rakshasa/rtorrent/archive/refs/tags/${RTORRENT_VERSION}.tar.gz" | tar xz && \
    cd rtorrent-${RTORRENT_VERSION#v} && \
    autoreconf -fi && \
    ./configure --with-xmlrpc-c --disable-debug && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /rtorrent-*


FROM debian:bookworm-slim

RUN useradd -m -u 1000 daedr

RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections

RUN apt-get update && apt-get install -y \
    libssl3 \
    libcurl4 \
    libc-ares2 \
    libncursesw6 \
    libxml2 \
    libxmlrpc-core-c3 \
    libsigc++-2.0-0v5 \
    libudns0 \
    zlib1g \
    wireguard \
    iproute2 \
    resolvconf \
    procps \
    natpmpc \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /usr/local/bin/rtorrent /usr/local/bin/rtorrent
COPY --from=builder /usr/local/lib/libtorrent* /usr/local/lib/

RUN ldconfig

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 49164/tcp
EXPOSE 49164/udp
EXPOSE 6881/tcp
EXPOSE 6881/udp

RUN ln -s /rtorrent/.rtorrent.rc /home/daedr/.rtorrent.rc

ENTRYPOINT ["/entrypoint.sh"]
