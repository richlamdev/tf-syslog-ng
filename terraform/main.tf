provider "aws" {
  region = var.aws_region
}

########################### NEW VPC ##############################
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "richy-vpc"
    #Environment = var.infra_env
    ManagedBy = "terraform"
  }
}
########################### NEW VPC ##############################

########################### SUBNETS ##############################

# public subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = true

  # 251 IP addresses each
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name      = "10.0.1.0 - Public Subnet"
    ManagedBy = "terraform"
  }
}

# private subnet
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = false

  # 251 IP addresses each
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name      = "10.0.2.0 - Private Subnet"
    ManagedBy = "terraform"
  }
}
########################### SUBNETS ##############################

########################### INTERNET GATWAY ######################
resource "aws_internet_gateway" "richy-igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "richy-igw"
  }
}

# create route table and attach to Internet Gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.richy-igw.id
  }
  tags = {
    Name = "public_route_table"
  }
}

# associate designated subnet to public route table
resource "aws_route_table_association" "internet_gateway_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}
########################### INTERNET GATWAY ######################

########################### NAT GATWAY ###########################
resource "aws_eip" "nat_gateway" {
  vpc = true
}

# create nat gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "nat_gateway"
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.richy-igw]
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name = "private_route_table"
  }
}

# associate private subnet with private route table
resource "aws_route_table_association" "nat_gateway_association" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}
########################### NAT GATWAY ###########################

########################### SECURITY GROUPS ######################
resource "aws_security_group" "sg_public" {
  name        = "sg_public_ssh"
  description = "allow SSH from internet"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "public_sg_ssh_only"
  }
}


resource "aws_security_group" "sg_private" {
  name        = "sg_private_ssh"
  description = "allow SSH from public subnet"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "private_sg_ssh_only_from_public_subnet"
  }
}


resource "aws_security_group" "sg_icmp" {
  name        = "sg_icmp"
  description = "allow icmp from public or private subnet"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.0.0/20"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "private_sg_icmp_from_public_or_private_subnet"
  }
}


resource "aws_security_group" "allow_syslog_ng" {
  name        = "allow_syslog_ng"
  description = "allow syslog-ng UDP 514 ingress from public or private subnet"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 514
    to_port     = 514
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/20"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_syslog_ng_from_public_or_private_subnet"
  }
}


resource "aws_security_group" "allow_dns" {
  name        = "allow_dns"
  description = "allow dns UDP 53 ingress from public or private subnet"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["10.0.0.0/20"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_dns_from_public_or_private_subnet"
  }
}
########################### SECURITY GROUPS ######################

########################### DHCP OPTIONS #########################
resource "aws_vpc_dhcp_options" "vpc_dhcp_options" {
  domain_name = "tatooine.test"
  #domain_name_servers = ["127.0.0.1", "10.0.0.2"]
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name = "richy's vpc_dhcp_options"
  }
}

resource "aws_vpc_dhcp_options_association" "richy_dns_resolver" {
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.vpc_dhcp_options.id
}

resource "aws_route53_zone" "private" {
  name = "tatooine.test"

  vpc {
    vpc_id = aws_vpc.vpc.id
  }
}

#variable "tatooine_A_records" {
#  default = ["syslog-0", "syslog-1", "dns", "client", "mirror"]
#}

locals {
  host_names = {
    namea = "syslog-0.tatooine.test"
    nameb = "syslog-1.tatooine.test"
    namec = "dns.tatooine.test"
    named = "client.tatooine.test"
    namee = "mirror.tatooine.test"
  }
  deploy_names = {
    deploya = aws_instance.public_test_instance[0]
    deployb = aws_instance.public_test_instance[1]
    deployc = aws_instance.public_test_instance[2]
    deployd = aws_instance.public_test_instance[3]
    deploye = aws_instance.public_test_instance[4]
  }
  host_deploy_names = zipmap(values(local.host_names),values(local.deploy_names))
}

resource "aws_route53_record" "domain_records" {
  for_each = local.host_deploy_names
  zone_id = aws_route53_zone.private.zone_id
  allow_overwrite = true
  name    = each.key
  type    = "A"
  ttl     = "300"
  records = [each.value.private_ip]
}

#resource "aws_route53_record" "syslog1" {
#zone_id = aws_route53_zone.private.zone_id
#name    = "syslog-1"
#type    = "A"
#ttl     = "300"
#records = [aws_instance.public_test_instance[1].private_ip]
#}
#
#resource "aws_route53_record" "dns" {
#zone_id = aws_route53_zone.private.zone_id
#name    = "dns"
#type    = "A"
#ttl     = "300"
#records = [aws_instance.public_test_instance[2].private_ip]
#}
#
#resource "aws_route53_record" "client" {
#zone_id = aws_route53_zone.private.zone_id
#name    = "client"
#type    = "A"
#ttl     = "300"
#records = [aws_instance.public_test_instance[3].private_ip]
#}
#
#resource "aws_route53_record" "mirror" {
#zone_id = aws_route53_zone.private.zone_id
#name    = "mirror"
#type    = "A"
#ttl     = "300"
#records = [aws_instance.public_test_instance[4].private_ip]
#}

########################### DHCP OPTIONS #########################


########################### EC2 INSTANCES ########################
resource "aws_key_pair" "richy-ssh-key" {
  key_name   = "richy-ssh-key"
  public_key = file(pathexpand("~/.ssh/id_ed25519_tf_acg.pub"))
}

# public instance
resource "aws_instance" "public_test_instance" {
  count           = 5
  ami             = "ami-0b28dfc7adc325ef4"
  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.sg_public.id, aws_security_group.sg_icmp.id, aws_security_group.allow_syslog_ng.id, aws_security_group.allow_dns.id]
  instance_type   = "t3.micro"
  #iam_instance_profile = "EC2SSMRole"
  key_name = "richy-ssh-key"
  tags = {
    Name = "public-instance-test"
  }
}

# private instance
#resource "aws_instance" "private_test_instance" {
#ami             = "ami-0b28dfc7adc325ef4"
#subnet_id       = aws_subnet.private.id
#security_groups = [aws_security_group.sg_private.id, aws_security_group.sg_icmp.id]
#instance_type   = "t3.micro"
#count           = 1
#iam_instance_profile = "EC2SSMRole"
#key_name             = "richy-ssh-key"
#tags = {
#Name = "private-instance-test"
#}
#}

########################### EC2 INSTANCES ########################

########################### OUTPUT INVENTORY FOR ANSIBLE #########
#resource "local_file" "inventory" {
#filename = "./inventory"
#content  = <<EOF
#[syslogng]
#${aws_instance.public_test_instance[0].public_dns}
#${aws_instance.public_test_instance[1].public_dns}
#
#[dns]
#${aws_instance.public_test_instance[2].public_dns}
#
#[client]
#${aws_instance.public_test_instance[3].public_dns}
#
#[mirror]
#${aws_instance.public_test_instance[4].public_dns}
#
#[multi:children]
#syslogng
#dns
#client
#
#[multi:vars]
#ansible_become=True
#ansible_become_method=sudo
#ansible_become_user=root
#ansible_python_interpreter=/usr/bin/python3
#EOF
#}
############################ OUTPUT INVENTORY FOR ANSIBLE #########
#
############################ HOSTS FILE FOR EACH INSTANCE #########
#
#locals {
#hosts_append = <<-EOT
#local-data: "syslog-0.tatooine.test.         IN        A      ${aws_instance.public_test_instance[0].private_ip}"
#local-data: "syslog-1.tatooine.test.         IN        A      ${aws_instance.public_test_instance[1].private_ip}"
#local-data: "dns.tatooine.test.              IN        A      ${aws_instance.public_test_instance[2].private_ip}"
#local-data: "client.tatooine.test.           IN        A      ${aws_instance.public_test_instance[3].private_ip}"
#local-data: "mirror.tatooine.test.           IN        A      ${aws_instance.public_test_instance[4].private_ip}"
#
#local-data-ptr: "${aws_instance.public_test_instance[0].private_ip}            syslog-0.tatooine.test."
#local-data-ptr: "${aws_instance.public_test_instance[1].private_ip}            syslog-1.tatooine.test."
#local-data-ptr: "${aws_instance.public_test_instance[2].private_ip}            dns.tatooine.test."
#local-data-ptr: "${aws_instance.public_test_instance[3].private_ip}            client.tatooine.test."
#local-data-ptr: "${aws_instance.public_test_instance[4].private_ip}            mirror.tatooine.test."
#EOT
#}
#
#resource "local_file" "hosts_append" {
#filename = "./dnshosts/hosts_append"
#content  = local.hosts_append
#}
#
#
#
