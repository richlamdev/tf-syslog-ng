#!/bin/bash

ansible -m ping all -u ec2-user --private-key ~/.ssh/id_ed25519_tf_acg

exit 0
