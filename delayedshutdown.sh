#!/bin/bash

# sleep for 58 days and exit
sleep 5011200

pkill -f qbittorrent-nox
[ -f /opt/piavpn-manual/pia_pid ] && kill $(cat /opt/piavpn-manual/pia_pid)

exit 255
