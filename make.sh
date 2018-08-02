#!/bin/bash

script="$(mktemp)"
cleanup () {
    rm "$script"
}

trap cleanup EXIT

add_debug () {
    if [[ -z "$DEBUG" ]]; then
        export DEBUG="$1"
    else
        export DEBUG="$DEBUG,$1"
    fi
}

add_debug bittorrent_client:15
add_debug bittorrent:15
# add_debug netdevice:15
# add_debug tcpip:15
# add_debug ethernet:15
# add_debug ipv4:15
# add_debug tcp:15
# add_debug neighbour:15
# add_debug malloc

# cat > "$script" <<EOF
# #!ipxe
# echo CUSTOM SCRIPT RUNNING
# dhcp
# echo DHCP DONE, FETCHING TORRENT FILE
# imgfetch --name lol http://10.42.42.2:8000/kernel.torrent
# echo STARTING TORRENT
# chain torrent://lol
# EOF

add_debug stream_tester

cat > "$script" <<EOF
#!ipxe
echo CUSTOM SCRIPT RUNNING
dhcp
imgfetch stream_tester://10.42.42.2:4242#tcp
echo DONE TESTING
EOF

make EMBED="$script" bin/undionly.kpxe bin-x86_64-linux/tap.linux -j7
