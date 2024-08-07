FROM ubuntu:22.04

ENV VPN_PROTOCOL=openvpn_udp_strong PREFERRED_REGION=none PIA_PF=true AUTOCONNECT=true DISABLE_IPV6=yes MAX_LATENCY=1
WORKDIR /qb-pia

ADD . .

RUN export DEBIAN_FRONTEND=noninteractive \
    && export DEBCONF_NONINTERACTIVE_SEEN=true \
    && echo 'tzdata tzdata/Areas select Asia' | debconf-set-selections \
    && echo 'tzdata tzdata/Zones/Asia select Ho_Chi_Minh' | debconf-set-selections \
    \
    && apt-get update \
    && apt-get install -y gnupg apt-transport-https \
    \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv 401E8827DA4E93E44C7D01E6D35164147CA69FC4 \
    && echo "deb http://ppa.launchpad.net/qbittorrent-team/qbittorrent-stable/ubuntu jammy main " | tee -a /etc/apt/sources.list \
    \
    && apt-get update \
    && apt-get install -y qbittorrent-nox openvpn curl jq \
    \
    && apt-get remove --purge -y gnupg \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
    \
    # Add non-root user
    && useradd --system --uid 1000 -m --shell /usr/sbin/nologin qbittorrent \
    # Create symbolic links to simplify mounting
    && mkdir -p /home/qbittorrent/.config/qBittorrent \
    && chown qbittorrent:qbittorrent /home/qbittorrent/.config/qBittorrent \
    && ln -s /home/qbittorrent/.config/qBittorrent /config \
       \
    && mkdir -p /home/qbittorrent/.local/share/qBittorrent \
    && chown qbittorrent:qbittorrent /home/qbittorrent/.local/share/qBittorrent \
    && ln -s /home/qbittorrent/.local/share/qBittorrent /torrents \
       \
    && mkdir /downloads \
    && chown qbittorrent:qbittorrent /downloads \
     # Check it works
    && su qbittorrent -s /bin/sh -c 'qbittorrent-nox -v'


RUN chmod +x /qb-pia/manual-connections/*.sh && chmod +x /qb-pia/*.sh

CMD ["qbittorrent-nox", "--webui-port=9999"]
ENTRYPOINT [ "/qb-pia/entrypoint.sh" ]

VOLUME [ "/pia-data", "/config", "/torrents", "/downloads" ]

HEALTHCHECK --interval=1m --timeout=3s --start-period=45s \
 CMD curl -f --retry 6 --max-time 5 --retry-delay 10 --retry-max-time 60 http://localhost:9999 || bash -c 'kill -s 15 -1 && (sleep 10; kill -s 9 -1)'
