#!/bin/bash

sleep 15

sed -i 's|\[\[ $proto == -4 \]\] && cmd sysctl -q net\.ipv4\.conf\.all\.src_valid_mark=1|[[ $proto == -4 ]] \&\& [[ $(sysctl -n net.ipv4.conf.all.src_valid_mark) != 1 ]] \&\& cmd sysctl -q net.ipv4.conf.all.src_valid_mark=1|' /usr/bin/wg-quick

wg-quick up /wireguard/wg0.conf

(
    while true; do
        date > /rtorrent/natpmpc.log
        
        udp_output=$(natpmpc -a 0 0 udp 60 -g 10.2.0.1 2>&1)
        echo "$udp_output" >> /rtorrent/natpmpc.log
        udp_public_port=$(echo "$udp_output" | grep -oP 'Mapped public port \K\d+')
        
        tcp_output=$(natpmpc -a 0 0 tcp 60 -g 10.2.0.1 2>&1)
        echo "$tcp_output" >> /rtorrent/natpmpc.log
        tcp_public_port=$(echo "$tcp_output" | grep -oP 'Mapped public port \K\d+')
        
        if [ -n "$udp_public_port" ] && [ -n "$tcp_public_port" ]; then
            echo "UDP Public Port: $udp_public_port" >> /rtorrent/natpmpc.log
            echo "TCP Public Port: $tcp_public_port" >> /rtorrent/natpmpc.log
						sed -i '/^network\.port_range\.set/d' /rtorrent/.rtorrent.rc
						echo "network.port_range.set = $udp_public_port-$udp_public_port" >> /rtorrent/.rtorrent.rc
        else
            echo "ERROR: Failed to extract public port(s)" >> /rtorrent/natpmpc.log
            break
        fi

        sleep 45
    done
) &

sleep 1

rm -f "/rtorrent/.session/rtorrent.lock"

su - daedr -c "tmux new-session -d -s rtorrent 'rtorrent'"

tail -f /dev/null
