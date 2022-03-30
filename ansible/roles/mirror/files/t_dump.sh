#!/bin/bash

sudo tcpdump -nnvvttttXXs0 -i eth0 udp port 514

exit 0
