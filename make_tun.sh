sudo ip tuntap add mode tap dev ipxe_tap # group kvm multi_queue
sudo ip link set dev ipxe_tap up

sudo brctl addbr ipxe_br
sudo brctl addif ipxe_br ipxe_tap
sudo ip link set ipxe_tap up
sudo ip link set ipxe_br up
sudo ip a a 10.42.42.2/24 dev ipxe_br
