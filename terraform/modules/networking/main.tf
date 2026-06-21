# ==========================================
# 1. VPC & INTERNET GATEWAY
# ==========================================
resource "aws_vpc" "main" {
# checkov:skip=CKV_AWS_163: "VPC Flow Logs desactivados por costos (FinOps)"
# checkov:skip=CKV2_AWS_11: "Flow Logs desactivados (FinOps)"
# checkov:skip=CKV2_AWS_5: "Default Security Group se manejara en Fase 10"
# checkov:skip=CKV2_AWS_12: "El Default SG se restringirá en la Fase 10 (Hardening)"

  cidr_block           = var.vpc_cidr 
  enable_dns_support   = true 
  enable_dns_hostnames = true 

  tags = {
    Name        = "${var.project_name}-vpc"
    Environment = var.environment 
    ManagedBy   = "Terraform" 
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id 
  tags = { Name = "${var.project_name}-igw" }
}

# ==========================================
# 2. PUBLIC SUBNET (DMZ)
# ==========================================
resource "aws_subnet" "public" {
# checkov:skip=CKV_AWS_130: "Asignacion de IP publica requerida por diseño sin ALB (FinOps)"

  vpc_id                  = aws_vpc.main.id 
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 1) 
  map_public_ip_on_launch = true 
  availability_zone       = "us-east-2a" 
  tags = { Name = "${var.project_name}-public-subnet" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id 
  route {
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.igw.id 
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id 
  route_table_id = aws_route_table.public_rt.id 
}

# ==========================================
# 3. PRIVATE SUBNETS (Database Tier)
# ==========================================
resource "aws_subnet" "private_1" {
  vpc_id                  = aws_vpc.main.id 
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 2) 
  map_public_ip_on_launch = false 
  availability_zone       = "us-east-2a" 
  tags = { Name = "${var.project_name}-private-subnet-1" }
}

resource "aws_subnet" "private_2" {
  vpc_id                  = aws_vpc.main.id 
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, 3) 
  map_public_ip_on_launch = false 
  availability_zone       = "us-east-2b" 
  tags = { Name = "${var.project_name}-private-subnet-2" }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id 
  tags = { Name = "${var.project_name}-private-rt" }
}

resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_1.id 
  route_table_id = aws_route_table.private_rt.id 
}

resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_2.id 
  route_table_id = aws_route_table.private_rt.id 
}