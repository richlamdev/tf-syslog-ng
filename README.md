# tf-syslog-ng
Terraform AWS syslog-ng testing

The Terraform was created in a hurry for some basic testing.

Ansible is a work in progress for syslog/DNS testing.

NOTES:

ansible -m ping all -u ec2-user --private-key ~/.ssh/id_ed25519_tf_acg

ansible-playbook main.yml -u ec2-user --private-key ~/.ssh/id_ed25519_tf_acg


TODO:

- separate the files to more logical breakdown
