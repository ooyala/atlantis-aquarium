#!/bin/bash

sudo killall -HUP dnsmasq
while :; do
  inotifywait /etc/aquarium/hosts-manager >/dev/null 2>&1
  sudo killall -HUP dnsmasq
done
