FROM debian:bullseye-slim

RUN useradd -m -u 1000 daedr

RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    build-essential \
    automake \
    libtool \
    libcppunit-dev \
    libsigc++-2.0-dev \
    libncurses-dev \
    libxml2-dev \
    pkg-config \
    software-properties-common \
    wget \
    wireguard \
    iproute2 \
    resolvconf \
    procps \
    libpsl-dev \
		libudns-dev \
    zlib1g-dev \
    natpmpc \
    tmux \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

RUN git clone https://github.com/openssl/openssl.git && \
    cd openssl && \
    ./config -fPIC && \
    make -j$(nproc) && \
    make install && \
    cd ..

RUN git clone https://github.com/c-ares/c-ares.git && \
    cd c-ares && \
    ./buildconf && \
    ./configure --enable-nonblocking --enable-shared && \
    make -j$(nproc) && \
    make install && \
    cd ..

RUN git clone https://github.com/curl/curl.git && \
    cd curl && \
    ./buildconf && \
    ./configure --enable-ares --with-openssl && \
    make -j$(nproc) && \
    make install && \
    cd ..

RUN git clone https://github.com/mirror/xmlrpc-c && \
    cd xmlrpc-c/advanced && \
    ./configure --disable-wininet-client --disable-libwww-client --enable-abyss-server --disable-cplusplus --disable-abyss-threads --disable-cgi-server --with-libwww-ssl && \
    make -j$(nproc) && \
    make install && \
    cd ../..

RUN wget -O - https://github.com/rakshasa/rtorrent/releases/download/v0.15.1/libtorrent-0.15.1.tar.gz | tar xz && \
    mv libtorrent-0.15.1 libtorrent && \
    cd libtorrent && \
    ./configure --enable-udns --with-posix-fallocate --disable-debug && \
    make -j$(nproc) && \
    make install && \
    cd ..

RUN wget -O - https://github.com/rakshasa/rtorrent/releases/download/v0.15.1/rtorrent-0.15.1.tar.gz | tar xz && \
    mv rtorrent-0.15.1 rtorrent && \
    cd rtorrent && \
    ./configure --disable-debug --with-xmlrpc-c && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    cd ..

RUN rm -rf /build

RUN curl -o /usr/local/bin/wait-for-it.sh https://raw.githubusercontent.com/vishnubob/wait-for-it/refs/heads/master/wait-for-it.sh && \
    chmod +x /usr/local/bin/wait-for-it.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 49164/tcp
EXPOSE 49164/udp
EXPOSE 6881/tcp
EXPOSE 6881/udp

RUN ln -s /rtorrent/.rtorrent.rc /home/daedr/.rtorrent.rc

ENTRYPOINT ["/entrypoint.sh"]
