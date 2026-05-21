terraform {
  backend "s3" {
    bucket         = "mysstic-warden-tfstate-ez"
    key            = "terraform/state/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "mysstic-terraform-locks"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

# ==========================================
# 1. COMPUTE (EC2 Instance)
# ==========================================
resource "aws_instance" "mysstic_server" {
  ami                         = "ami-0e68dc81dc36750a1" 
  instance_type               = "t3.micro"              
  iam_instance_profile        = aws_iam_instance_profile.mysstic_ec2_profile.name
  subnet_id                   = aws_subnet.mysstic_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.mysstic_sg.id] 
  associate_public_ip_address = true 
  key_name                    = "mysstic-key" 

  root_block_device {
    volume_size           = 8           
    volume_type           = "gp3"       
    encrypted             = true        
    delete_on_termination = true        
  }

  instance_market_options {
    market_type = "spot"
  }

  tags = {
    Name   = "mysstic-warden-node"
    Backup = "True"
  }

  user_data = <<-EOF
              #!/bin/bash
              # 1. No GUI y evitar prompts interactivos
              export DEBIAN_FRONTEND=noninteractive
              
              # 2. Actualización de repositorios e instalación de Python (Requisito de Ansible)
              apt-get update
              apt-get install -y python3 python3-apt
              
              # 3. Marcar el fin del bootstrap
              echo "Bootstrap de Terraform completado. Esperando a Ansible..." > /var/log/bootstrap_done.txt
              EOF
  lifecycle {
    ignore_changes = [user_data] 
  }
}

# ==========================================
# 2. DISASTER RECOVERY (DLM)
# ==========================================
resource "aws_dlm_lifecycle_policy" "mysstic_backup_policy" {
  description        = "Backup diario para MyssTic Warden - Retencion 7 dias"
  execution_role_arn = aws_iam_role.dlm_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["INSTANCE"]
    schedule {
      name = "Daily-3AM-Backup"
      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["03:00"]
      }
      retain_rule {
        count = 7
      }
      tags_to_add = {
        SnapshotCreator = "DLM-Robot"
      }
      copy_tags = true
    }
    target_tags = {
      Backup = "True"
    }
  }
}

# ==========================================
# 3. STATE MANAGEMENT (S3 & DynamoDB)
# ==========================================
resource "aws_s3_bucket" "mysstic_terraform_state" {
  bucket = "mysstic-warden-tfstate-ez"
  lifecycle {
    prevent_destroy = true 
  }
  tags = {
    Name        = "mysstic-tfstate-bucket"
    Environment = "DevSecOps"
  }
}

resource "aws_s3_bucket_versioning" "mysstic_state_versioning" {
  bucket = aws_s3_bucket.mysstic_terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "mysstic-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name   = "LockID"
    type   = "S"
  }
  tags = {
    Name        = "mysstic-tf-lock-table"
    Environment = "DevSecOps"
  }
}

# ==========================================
# 4. OUTPUTS
# ==========================================
output "server_public_ip" {
  description = "Public IP for SSH access"
  value       = aws_instance.mysstic_server.public_ip
}