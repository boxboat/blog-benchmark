provider "aws" {
  region = var.region
}

resource "aws_vpc" "benchmark_vpc" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "benchmark_public_subnet" {
  cidr_block              = var.public_subnet
  vpc_id                  = aws_vpc.benchmark_vpc.id
  map_public_ip_on_launch = true
}

resource "aws_subnet" "benchmark_private_subnet" {
  cidr_block              = var.private_subnet
  vpc_id                  = aws_vpc.benchmark_vpc.id
  map_public_ip_on_launch = false
}

resource "aws_internet_gateway" "benchmark_inet_gateway" {
  vpc_id = aws_vpc.benchmark_vpc.id
}

resource "aws_route_table" "benchmark_public_rt" {
  vpc_id = aws_vpc.benchmark_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.benchmark_inet_gateway.id
  }
}

resource "aws_route_table_association" "benchmark_inet_rta" {
  subnet_id      = aws_subnet.benchmark_public_subnet.id
  route_table_id = aws_route_table.benchmark_public_rt.id
}

resource "aws_eip" "benchmark_nat" {
  vpc = true
}

resource "aws_nat_gateway" "benchmark_nat_gateway" {
  allocation_id = aws_eip.benchmark_nat.id
  subnet_id     = aws_subnet.benchmark_public_subnet.id
  depends_on    = [aws_internet_gateway.benchmark_inet_gateway]
}

resource "aws_route_table" "benchmark_private_rt" {
  vpc_id = aws_vpc.benchmark_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.benchmark_nat_gateway.id
  }
}

resource "aws_route_table_association" "benchmark_nat_rta" {
  subnet_id      = aws_subnet.benchmark_private_subnet.id
  route_table_id = aws_route_table.benchmark_private_rt.id
}

resource "aws_security_group" "benchmark_ssh_security_group" {
  vpc_id = aws_vpc.benchmark_vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "benchmark_key" {
  key_name   = "bastion"
  public_key = var.ssh_pub_key
}

resource "aws_instance" "benchmark_bastion" {
  ami                    = var.ami
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.benchmark_key.key_name
  subnet_id              = aws_subnet.benchmark_public_subnet.id
  vpc_security_group_ids = [aws_security_group.benchmark_ssh_security_group.id]
}

resource "aws_instance" "benchmark_instance" {
  count                  = var.instance_count
  ami                    = var.ami
  instance_type          = "m5.xlarge"
  key_name               = aws_key_pair.benchmark_key.key_name
  subnet_id              = aws_subnet.benchmark_private_subnet.id
  vpc_security_group_ids = [aws_security_group.benchmark_ssh_security_group.id]
}
