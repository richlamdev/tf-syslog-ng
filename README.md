# tf-syslog-ng

## Introduction

This is an example of Infrastructure-as-Code (Iac) example utilizing [Terraform](https://www.terraform.io/)
to provision an infrastructure with [Amazon Web Services (AWS)](https://aws.amazon.com/).
The infrastructure is then configured via configuration management software [Ansible](https://www.ansible.com/).

## Purpose

The primary purpose is to provide a temporary testing environment for testing Syslog-NG configuration.

A second purpose is to enable testing of mirroring syslog network traffic.

## How to use

### Prerequisites

#### Knowledge

Although not strictly required, it would be ideal to have familiarity with the following.
This will go a long way for potential changes to adopt to other applications or testing.

* Basic AWS knowledge.  VPC/IGW/NATGW/NACLs/SG/EC2

* Basic Linux and Networking knowledge. (ports, firewalls, DNS, UDP, IP Addressing)

* Basic Terraform knowledge (init/plan/apply/output)

#### Software

* [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

* [Terraform](https://www.terraform.io/downloads)

* AWS account.  It is possible some charges will be incurred with this test environment.
I am not aware of potential costs, due to using short-term AWS test environments (aka temporary
sandboxes via [acloudguru](https://acloudguru.com/))

### Basic usage

Update your AWS credentials.\
```aws configure```

Create a SSH key pair, and ensure the private key is located in your home folder under .ssh/ (aka ~/.ssh)


Clone this repo:\
```git clone https://github.com/richlamdev/tf-syslog-ng```

Deploy infrastructure via Terraform
```cd tf-syslog-ng/terraform```

```terraform init```

```terraform plan```

```terraform apply --auto-approve```

It's advisable to leave this terminal open to reference the Terraform outputs.
This will allow convenient copy & paste of the public DNS hostnames to SSH to.

Configure the EC2 instances via Ansible






NOTES:

ansible -m ping all -u ec2-user --private-key ~/.ssh/id_ed25519_tf_acg

ansible-playbook main.yml -u ec2-user --private-key ~/.ssh/id_ed25519_tf_acg


TODO:

- clean up Terraform, specifically use more variables and reduce violation of DRY principle.
