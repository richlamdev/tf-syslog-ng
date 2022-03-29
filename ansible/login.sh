#!/bin/bash
# Caution, this is potentially dangerous, as it auto accepts host key.

ssh -i ~/.ssh/id_ed25519_tf_acg -o "StrictHostKeyChecking no" -l ec2-user $@

exit 0
