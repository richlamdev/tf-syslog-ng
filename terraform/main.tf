provider "aws" {
  region = var.aws_region
  profile = "cloud_user"
}

########################### NEW VPC ##############################
resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    CreatedBy = "tf-syslog-ng"
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
    CreatedBy = "tf-syslog-ng"
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
    CreatedBy = "tf-syslog-ng"
  }
}
########################### SUBNETS ##############################

########################### INTERNET GATWAY ######################
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "igw"
    CreatedBy = "tf-syslog-ng"
  }
}

# create route table and attach to Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "public_route_table"
    CreatedBy = "tf-syslog-ng"
  }
}

# associate designated subnet to public route table
resource "aws_route_table_association" "internet_gateway_association" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
########################### INTERNET GATWAY ######################

########################### NAT GATWAY ###########################
resource "aws_eip" "ngw" {
  vpc = true
}

# create nat gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.ngw.id
  subnet_id     = aws_subnet.public.id

  tags = {
    CreatedBy = "tf-syslog-ng"
  }
  # ensure proper ordering; add an explicit dependency on the IGW for the VPC
  depends_on = [aws_internet_gateway.igw]
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }
  tags = {
    Name = "private_route_table"
    CreatedBy = "tf-syslog-ng"
  }
}

# associate private subnet with private route table
resource "aws_route_table_association" "nat_gateway_association" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}
########################### NAT GATWAY ###########################

########################### SECURITY GROUPS ######################
resource "aws_security_group" "public" {
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
    CreatedBy = "tf-syslog-ng"
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
    CreatedBy = "tf-syslog-ng"
  }
}


resource "aws_security_group" "icmp" {
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
    CreatedBy = "tf-syslog-ng"
  }
}


resource "aws_security_group" "syslog_ng" {
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
    CreatedBy = "tf-syslog-ng"
  }
}


resource "aws_security_group" "dns" {
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
    CreatedBy = "tf-syslog-ng"
  }
}
########################### SECURITY GROUPS ######################

########################### DHCP OPTIONS #########################
resource "aws_vpc_dhcp_options" "config" {
  domain_name = "tatooine.test"
  #domain_name_servers = ["127.0.0.1", "10.0.0.2"]
  #domain_name_servers = ["AmazonProvidedDNS", "${aws_instance.public_test[2].private_ip}" ]
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    Name = "VPC DCHP Options"
    CreatedBy = "tf-syslog-ng"
  }
}

resource "aws_vpc_dhcp_options_association" "dns_resolver" {
  vpc_id          = aws_vpc.vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.config.id
}

resource "aws_route53_zone" "private" {
  name = "tatooine.test"

  vpc {
    vpc_id = aws_vpc.vpc.id
  }
}

locals {
  host_names = {
    namea = "syslog-0.tatooine.test"
    nameb = "syslog-1.tatooine.test"
    namec = "dns.tatooine.test"
    named = "client.tatooine.test"
    namee = "mirror.tatooine.test"
  }
  deploy_names = {
    deploya = aws_instance.public_test[0]
    deployb = aws_instance.public_test[1]
    deployc = aws_instance.public_test[2]
    deployd = aws_instance.public_test[3]
    deploye = aws_instance.public_test[4]
  }
  host_deploy_names = zipmap(values(local.host_names), values(local.deploy_names))
}

resource "aws_route53_record" "domain_records" {
  for_each        = local.host_deploy_names
  zone_id         = aws_route53_zone.private.zone_id
  allow_overwrite = true
  name            = each.key
  type            = "A"
  ttl             = "300"
  records         = [each.value.private_ip]
}

########################### DHCP OPTIONS #########################

########################### EC2 INSTANCES ########################
resource "aws_key_pair" "ssh-key" {
  key_name   = "ssh-key"
  public_key = file(pathexpand("~/.ssh/id_ed25519_tf_acg.pub"))
}

data "aws_ami" "latest-Redhat" {
  most_recent = true
  owners      = ["309956199498"] # Redhat owner ID

  filter {
    name   = "name"
    values = ["RHEL_HA-8.5.0_HVM-2*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# public instance
resource "aws_instance" "public_test" {
  count           = 5
  ami             = "${data.aws_ami.latest-Redhat.id}" # Get latest RH 8.5x image
  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.public.id, aws_security_group.icmp.id, aws_security_group.syslog_ng.id, aws_security_group.dns.id]
  instance_type   = "t3.micro"
  #iam_instance_profile = "EC2SSMRole"
  key_name = "ssh-key"
  tags = {
    Name = "public-instance-test"
    CreatedBy = "tf-syslog-ng"
  }
}

# private instance
#resource "aws_instance" "private_test" {
#ami             = "ami-0b28dfc7adc325ef4"
#subnet_id       = aws_subnet.private.id
#security_groups = [aws_security_group.sg_private.id, aws_security_group.sg_icmp.id]
#instance_type   = "t3.micro"
#count           = 1
#iam_instance_profile = "EC2SSMRole"
#key_name             = "ssh-key"
#tags = {
#Name = "private-instance-test"
#}
#}

########################### EC2 INSTANCES ########################
