provider "aws" {
  region = "us-west-2"
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


resource "aws_security_group" "sg_private_icmp" {
  name        = "sg_private_icmp"
  description = "allow icmp from public subnet"
  vpc_id      = aws_vpc.vpc.id
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.0.1.0/24"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "private_sg_icmp_only_from_public_subnet"
  }
}
########################### SECURITY GROUPS ######################

########################### EC2 INSTANCES ########################
resource "aws_key_pair" "richy-ssh-key" {
  key_name   = "richy-ssh-key"
  public_key = file(pathexpand("~/.ssh/id_ed25519_tf_acg.pub"))
}

# public instance
resource "aws_instance" "public_test_instance" {
  count           = 2
  ami             = "ami-0b28dfc7adc325ef4"
  subnet_id       = aws_subnet.public.id
  security_groups = [aws_security_group.sg_public.id]
  instance_type   = "t3.micro"
  #iam_instance_profile = "EC2SSMRole"
  key_name = "richy-ssh-key"
  tags = {
    Name = "public-instance-test"
  }
}

# private instance
resource "aws_instance" "private_test_instance" {
  ami             = "ami-0b28dfc7adc325ef4"
  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.sg_private.id]
  instance_type   = "t3.micro"
  count           = 1
  #iam_instance_profile = "EC2SSMRole"
  #key_name             = "richy-ssh-key"
  tags = {
    Name = "private-instance-test"
  }
}

output "instance_ips" {
  value = aws_instance.public_test_instance.*.public_ip
}

output "public_hostname" {
  value = aws_instance.public_test_instance.*.public_dns
}
########################### EC2 INSTANCES ########################

########################### OUTPUT INVENTORY FOR ANSIBLE #########
resource "local_file" inventory {
  filename = "./inventory"
  content = <<EOF
  [aws]
  ${aws_instance.public_test_instance[0].public_dns}
  ${aws_instance.public_test_instance[1].public_dns}

  [multi:children]
  aws

  [multi:vars]
  ansible_become=True
  ansible_become_method=sudo
  ansible_become_user=root
  ansible_python_interpreter=/usr/bin/python3
  EOF
}
########################### OUTPUT INVENTORY FOR ANSIBLE #########
