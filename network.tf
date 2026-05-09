# ==========================================
# 1. VPC & IGW
# ==========================================
resource "aws_vpc" "mysstic_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "mysstic-vpc-prime"
    Environment = "DevSecOps"
    ManagedBy   = "Terraform"
  }
}

resource "aws_internet_gateway" "mysstic_igw" {
  vpc_id = aws_vpc.mysstic_vpc.id
  tags = { Name = "mysstic-igw" }
}

# ==========================================
# 2. PUBLIC SUBNET (DMZ)
# ==========================================
resource "aws_subnet" "mysstic_public_subnet" {
  vpc_id                  = aws_vpc.mysstic_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-2a"
  tags = { Name = "mysstic-public-subnet" }
}

resource "aws_route_table" "mysstic_public_rt" {
  vpc_id = aws_vpc.mysstic_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.mysstic_igw.id
  }
  tags = { Name = "mysstic-public-route-table" }
}

resource "aws_route_table_association" "mysstic_public_assoc" {
  subnet_id      = aws_subnet.mysstic_public_subnet.id
  route_table_id = aws_route_table.mysstic_public_rt.id
}

# ==========================================
# 3. PRIVATE SUBNET (Database Tier)
# ==========================================
resource "aws_subnet" "mysstic_private_subnet" {
  vpc_id                  = aws_vpc.mysstic_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-2a"
  tags = { Name = "mysstic-private-subnet-db" }
}

resource "aws_route_table" "mysstic_private_rt" {
  vpc_id = aws_vpc.mysstic_vpc.id
  tags = { Name = "mysstic-private-route-table" }
}

resource "aws_route_table_association" "mysstic_private_assoc" {
  subnet_id      = aws_subnet.mysstic_private_subnet.id
  route_table_id = aws_route_table.mysstic_private_rt.id
}

# ==========================================
# 4. SECURITY GROUPS
# ==========================================
resource "aws_security_group" "mysstic_sg" {
  name        = "mysstic-allow-ssh"
  description = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.mysstic_vpc.id

  ingress {
    description = "SSH from anywhere"
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
  tags = { Name = "mysstic-sg-prime" }
}