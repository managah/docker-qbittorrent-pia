#!/bin/bash

[ -z "$PIA_USER" ] && echo "Please specify PIA_USER" && exit 1
[ -z "$PIA_PASS" ] && echo "Please specify PIA_PASS" && exit 1

debugfile=/opt/piavpn-manual/debug_info
pidfile=/opt/piavpn-manual/pia_pid
setuplog=/tmp/pia_setup

if [ ! -f $pidfile ] || ! ps -p $(cat $pidfile) > /dev/null; then
    cd /qb-pia/manual-connections
    ./run_setup.sh > $setuplog 2>&1 &
fi

port="0"
confirmation="Initialization Sequence Complete"
while true; do
    if [ -f $debugfile ] && grep -q "$confirmation" $debugfile && [ -f $setuplog ]; then
        port=$(tail $setuplog | grep -Eo 'Forwarded\s*port\s*[0-9]+' | awk '{print $NF}')
        if [ ! -z "$port" ]; then
            break
        fi
    fi
    sleep 1
done

if [[ "$@" == *"qbittorrent-nox"* ]]; then
    conffile=/config/qBittorrent.conf
    tuninterface=tun06
    if [ -f $conffile ]; then
        sed -i -r s/Session\\\\Port=[0-9]\+/Session\\\\Port=$port/ $conffile
        sed -i -r s/PortRangeMin=[0-9]\+/PortRangeMin=$port/ $conffile
        sed -i -r s/\(Session\\\\Interface.*\)=.*/\\1=$tuninterface/ $conffile
    else
        cat > $conffile <<EOF
[BitTorrent]
Session\Port=$port
Session\Interface=$tuninterface
Session\InterfaceName=$tuninterface

[Preferences]
General\Locale=C
WebUI\Enabled=true
Downloads\SavePath=/downloads
Connection\PortRangeMin=$port

[LegalNotice]
Accepted=true

[General]
ported_to_new_savepath_system=true
EOF
    fi

    GATEWAY="$(ip route |awk '/default/ {print $3}')"
    for cidr in ${LAN_CIDR:-192.168.0.0/24 192.168.10.0/24}; do
        ip route add to $cidr via $GATEWAY dev eth0
    done

    /qb-pia/delayedshutdown.sh &
fi

exec runuser -u qbittorrent -- "$@"
