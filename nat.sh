#!/bin/sh
sudo iptables -t nat -A POSTROUTING -s 10.42.42.0/24 -j MASQUERADE
sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'
