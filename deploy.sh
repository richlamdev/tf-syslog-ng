#!/bin/bash

ansible-playbook main.yml -u ec2-user --private-key ~/.ssh/id_ed25519_tf_acg

exit 0
