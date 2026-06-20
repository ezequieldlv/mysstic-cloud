# ==========================================
# 1. IAM ROLE & PROFILE
# ==========================================
data "aws_iam_policy_document" "ec2_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2_role" {
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "s3_readonly_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2_role.name
}

# ==========================================
# 2. SECURITY GROUP
# ==========================================
resource "aws_security_group" "ec2_sg" {
  name        = "${var.project_name}-ec2-sg"
  description = "Permitir HTTP/HTTPS entrante"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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

  tags = { Name = "${var.project_name}-ec2-sg" }
}

# ==========================================
# 3. EC2 INSTANCE
# ==========================================
resource "aws_instance" "server" {
  ami                         = "ami-0ecbd2e35f5b231f2" 
  instance_type               = "t4g.micro"
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id] 
  associate_public_ip_address = true 
  key_name                    = "mysstic-key" 

  root_block_device {
    volume_size           = 8           
    volume_type           = "gp2"      
    encrypted             = true        
    delete_on_termination = true        
  }

  tags = {
    Name   = "${var.project_name}-node"
    Backup = "True"
  }

  user_data = <<-EOF
              #!/bin/bash
              export DEBIAN_FRONTEND=noninteractive
              echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
              echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
              sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
              sudo apt-get update
              sudo apt-get install -y python3 python3-apt curl
              curl -fsSL https://tailscale.com/install.sh | sh
              sudo tailscale up --authkey=${var.tailscale_auth_key} --hostname=mysstic-warden --ssh --advertise-exit-node
              EOF
}

# ==========================================
# 4. DISASTER RECOVERY (DLM) & IAM
# ==========================================
data "aws_iam_policy_document" "dlm_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dlm_role" {
  name               = "${var.project_name}-dlm-role"
  assume_role_policy = data.aws_iam_policy_document.dlm_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "dlm_role_attach" {
  role       = aws_iam_role.dlm_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

resource "aws_dlm_lifecycle_policy" "backup_policy" {
  description        = "Backup diario para EC2 - Retencion 7 dias"
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