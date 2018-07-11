#!/bin/bash
# Install Minecraft DNS Rotator

cp minecraft-dnsrotator.sh /usr/bin/
chmod +x /usr/bin/minecraft-dnsrotator.sh
mkdir -p /etc/minecraftdnsrotator/conf/
cp -a conf/* /etc/minecraftdnsrotator/conf/
