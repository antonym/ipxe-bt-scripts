intf=${1:-ipxe_br}
sudo dnsmasq -d --dhcp-range=10.42.42.3,10.42.42.200,10000 \
     --interface="$intf" \
     --enable-tftp="$intf" \
     --tftp-root="$(realpath bin/)" \
     --dhcp-boot=undionly.kpxe
