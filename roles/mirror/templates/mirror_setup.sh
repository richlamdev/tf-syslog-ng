#!/bin/bash

HOST_A= {{ host_ip }}

ip link add name vethinj up type veth peer name vethgw
ip link set vethgw up
sysctl -w net.ipv4.conf.vethgw.forwarding=1
sysctl -w net.ipv4.conf.vethgw.accept_local=1
sysctl -w net.ipv4.conf.vethgw.rp_filter=0
sysctl -w net.ipv4.conf.all.rp_filter=0
ip route add $HOST_A/32 dev vethinj
