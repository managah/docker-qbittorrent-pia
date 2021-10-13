# docker-qbittorrent-pia
Dockerized qBittorrent with Private Internet Access (PIA) VPN.

qBittorrent process will only start after a VPN connection to PIA is established and port forwarding is enabled. qBittorrent's listening port is configured automatically on each startup.

PIA port forwarding expires every 2 months. When that happens, the running Docker container will stop. So it's good to utilize Docker's auto-restart feature.

Supported CPU architectures:
* x86-64
* arm64
* armv7

# Usage
Refer to https://hub.docker.com/r/managah/qbittorrent-pia.

# Inspirations
* https://github.com/pia-foss/manual-connections
* https://github.com/wernight/docker-qbittorrent
