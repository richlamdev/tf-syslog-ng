# https://superuser.com/questions/1593995/iptables-nftables-forward-udp-data-to-multiple-targets

############### OUTPUT MIRROR SETUP FOR ANSIBLE #########
resource "local_file" "mirror_setup" {
  filename = "./mirror/mirror_setup.sh"
  content  = <<EOF
#!/bin/bash

MIRROR_HOST=${aws_instance.public_test_instance[4].private_ip}

ip link add name vethinj up type veth peer name vethgw
ip link set vethgw up
sysctl -w net.ipv4.conf.vethgw.forwarding=1
sysctl -w net.ipv4.conf.vethgw.accept_local=1
sysctl -w net.ipv4.conf.vethgw.rp_filter=0
sysctl -w net.ipv4.conf.all.rp_filter=0
ip route add $MIRROR_HOST/32 dev vethinj

EOF
}
############### OUTPUT MIRROR SETUP FOR ANSIBLE #########

############### OUTPUT NTABLES MIRROR FOR ANSIBLE #######
resource "local_file" "multiply" {
  filename = "./mirror/multiply.nft"
  content  = <<EOF
define MIRROR_HOST=${aws_instance.public_test_instance[4].private_ip}
define SYSLOG0=${aws_instance.public_test_instance[0].private_ip}
define SYSLOG1=${aws_instance.public_test_instance[1].private_ip}

#define SYSLOGn=12.42.1.3

table ip multiply
delete table ip multiply

table ip multiply {
        chain c {
                type filter hook prerouting priority -300; policy accept;
                iif != vethgw ip daddr $MIRROR_HOST udp dport 514 ip saddr set $MIRROR_HOST goto cmultiply
        }

        chain cmultiply {
                jump cdnatdup
                drop
        }

        chain cdnatdup {
                ip daddr set $SYSLOG0 dup to $MIRROR_HOST device vethinj
                ip daddr set $SYSLOG1 dup to $MIRROR_HOST device vethinj

                #ip daddr set $SYSLOGn dup to $MIRROR_HOST device vethinj
        }
}
EOF
}
############### OUTPUT NTABLES MIRROR FOR ANSIBLE #######
