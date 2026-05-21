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
  name        = "mysstic-sg-prime"
  description = "Allow HTTP/HTTPS inbound traffic, SSH exclusively via Tailscale"
  vpc_id      = aws_vpc.mysstic_vpc.id

  ingress {
    description = "HTTP from anywhere for Portfolio"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  ingress {
    description = "HTTPS from anywhere for Portfolio"
    from_port   = 443
    to_port     = 443
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

# ==========================================
# 5. PRIVATE SUBNET 2 (High availability RDS)
# ==========================================
resource "aws_subnet" "mysstic_private_subnet_2" {
  vpc_id                  = aws_vpc.mysstic_vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false        
  availability_zone       = "us-east-2b"

  tags = {
    Name = "mysstic-private-subnet-db-2"
  }
}
resource "aws_route_table_association" "mysstic_private_assoc_2" {
  subnet_id      = aws_subnet.mysstic_private_subnet_2.id
  route_table_id = aws_route_table.mysstic_private_rt.id
}

# ==========================================
# 6. DB SUBNET GROUP
# ==========================================
resource "aws_db_subnet_group" "mysstic_db_group" {
  name       = "mysstic-db-subnet-group"
  
  subnet_ids = [
    aws_subnet.mysstic_private_subnet.id,
    aws_subnet.mysstic_private_subnet_2.id
  ]
  tags = {
    Name = "mysstic-db-subnet-group"
  }
}