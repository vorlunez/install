#!/bin/bash
# proxychains4 + privoxy
# HTTP_PROXY=http://127.0.0.1:8118 HTTPS_PROXY=http://127.0.0.1:8118 codex
set -e

SOCKS_HOST="127.0.0.1"
SOCKS_PORT="1080"
PRIVOXY_CONF="/etc/privoxy/config"
PROXYCHAINS_CONF="$HOME/.proxychains/proxychains.conf"

sudo apt update
sudo apt install -y proxychains4 privoxy
mkdir -p $HOME/.proxychains
if [ ! -f "$HOME/.proxychains/proxychains.conf" ]; then
    echo -e "[ProxyList]\nsocks5 127.0.0.1 1080" > $HOME/.proxychains/proxychains.conf
fi

# 确保 Privoxy 只监听本机，避免变成局域网/公网开放代理
if grep -qE '^\s*listen-address\s+' "$PRIVOXY_CONF"; then
    sudo sed -i 's/^\s*listen-address\s\+.*/listen-address  127.0.0.1:8118/' "$PRIVOXY_CONF"
else
    echo "listen-address  127.0.0.1:8118" | sudo tee -a "$PRIVOXY_CONF" >/dev/null
fi

# 避免重复追加 forward-socks5t
if grep -qE '^\s*forward-socks5t\s+/\s+' "$PRIVOXY_CONF"; then
    sudo sed -i "s#^\s*forward-socks5t\s\+/.*#forward-socks5t / $SOCKS_HOST:$SOCKS_PORT .#" "$PRIVOXY_CONF"
else
    echo "forward-socks5t / $SOCKS_HOST:$SOCKS_PORT ." | sudo tee -a "$PRIVOXY_CONF" >/dev/null
fi

sudo systemctl enable --now privoxy
sudo systemctl restart privoxy