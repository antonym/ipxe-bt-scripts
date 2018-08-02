#!/bin/sh
echo coucou > hello
aria2c hello.torrent --enable-dht=false -V
rm hello
aria2c hello.torrent --enable-dht=false
