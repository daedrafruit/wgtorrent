sudo sysctl -w net.ipv4.conf.all.src_valid_mark=1
docker run \
    --name wgtorrent \
    -v /zfs:/zfs \
    -v /home/daedr/docker/wgtorrent/config/rtorrent:/rtorrent \
    -v /zfs/mnt/torrents:/torrents \
    -v /home/daedr/docker/wgtorrent/config/wireguard:/wireguard \
    -v /run/resolvconf/resolv.conf:/etc/resolv.conf \
    --cap-add NET_ADMIN \
    --restart unless-stopped \
    -d \
    wgtorrent
