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

#RUN wget https://github.com/rakshasa/libtorrent/archive/slingamn-udns.10.zip && \
#    unzip slingamn-udns.10.zip && \
#    mv libtorrent-slingamn-udns.10 libtorrent && \
#    rm slingamn-udns.10.zip

#RUN cd libtorrent && \
#    ./autogen.sh && \
#    ./configure --with-udns --with-posix-fallocate --disable-debug && \
#    make -j$(nproc) && \
#    make install && \
#    cd ..

RUN wget -O - https://github.com/rakshasa/rtorrent-archive/raw/master/libtorrent-0.13.8.tar.gz | tar xz && \
    mv libtorrent-0.13.8 libtorrent && \
    cd libtorrent && \
    ./autogen.sh && \
    ./configure --with-posix-fallocate --disable-debug && \
    make -j$(nproc) && \
    make install && \
    cd ..

RUN wget -O - https://github.com/rakshasa/rtorrent-archive/raw/master/rtorrent-0.9.8.tar.gz | tar xz && \
    mv rtorrent-0.9.8 rtorrent && \
    cd rtorrent && \
    ./autogen.sh && \
    ./configure --disable-debug --with-xmlrpc-c && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
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
