#!/bin/sh

aria2c -V kernel.torrent --seed-ratio=0.0 --console-log-level=debug --enable-dht=false
