FROM debian:bullseye-slim

RUN useradd -m -u 1000 daedr

RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections

RUN apt-get update && apt-get install -y \
    git \
    unzip \
    build-essential \
    autoconf \
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

RUN git clone https://github.com/rakshasa/libtorrent.git && \
    cd libtorrent && \
		git checkout $(git branch -a | grep -i 'stable' | sed 's#remotes/origin/##' | head -n1) && \
    autoreconf -fi && \
    ./configure \
        --enable-udns \
        --with-posix-fallocate \
        --disable-debug && \
    make -j$(nproc) && \
    make install && \
    cd ..

RUN echo "/usr/local/lib" >> /etc/ld.so.conf.d/local.conf && \
    ldconfig

RUN git clone https://github.com/rakshasa/rtorrent.git && \
    cd rtorrent && \
		git checkout $(git branch -a | grep -i 'stable' | sed 's#remotes/origin/##' | head -n1) && \
    autoreconf -fi && \
    ./configure \
        --with-xmlrpc-c \
        --disable-debug && \
    make -j$(nproc) && \
    make install && \
    cd ..

RUN rm -rf /build

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 49164/tcp
EXPOSE 49164/udp
EXPOSE 6881/tcp
EXPOSE 6881/udp

RUN ln -s /rtorrent/.rtorrent.rc /home/daedr/.rtorrent.rc

ENTRYPOINT ["/entrypoint.sh"]
