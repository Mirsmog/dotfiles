#!/bin/bash

# Get Windows IP automatically
get_windows_ip() {
    # Try multiple methods to get Windows IP
    local ip1=$(ip route | grep default | awk '{print $3}')
    local ip2=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}')

    # Prefer the default gateway IP
    if [ -n "$ip1" ]; then
        echo "$ip1"
    elif [ -n "$ip2" ]; then
        echo "$ip2"
    else
        echo "127.0.0.1"
    fi
}

WINDOWS_IP=$(get_windows_ip)
PROXY_PORT=2081
PROXY_URL="http://${WINDOWS_IP}:${PROXY_PORT}"

# Check current proxy status
if [ -n "$http_proxy" ] || [ -n "$HTTP_PROXY" ]; then
    # Proxy is ON, turn it OFF
    unset http_proxy
    unset https_proxy
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset all_proxy
    unset ALL_PROXY
    unset no_proxy
    unset NO_PROXY

    echo "🔴 Proxy DISABLED"
else
    # Proxy is OFF, turn it ON
    export http_proxy="$PROXY_URL"
    export https_proxy="$PROXY_URL"
    export HTTP_PROXY="$PROXY_URL"
    export HTTPS_PROXY="$PROXY_URL"
    export all_proxy="$PROXY_URL"
    export ALL_PROXY="$PROXY_URL"
    export no_proxy="localhost,127.0.0.1,::1"
    export NO_PROXY="localhost,127.0.0.1,::1"

    echo "🟢 Proxy ENABLED: $PROXY_URL"
    echo "   Windows IP: $WINDOWS_IP"
fi
