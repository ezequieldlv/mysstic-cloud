terraform {
  backend "s3" {
    bucket  = "mysstic-warden-tfstate-ez"         # Nuevo bucket
    key     = "terraform/state/terraform.tfstate" # La "ruta/carpeta" 
    region  = "us-east-2"                         # La región del bucket
    encrypt = true           
    dynamodb_table = "mysstic-terraform-locks"                     # Encriptación activada
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# 1. EL PROVEEDOR 
provider "aws" {
  region = "us-east-2" # Ohio
}

# 2. EL RECURSO
resource "aws_vpc" "mysstic_vpc" {
  cidr_block           = "10.0.0.0/16" # El tamaño de la red (65,536 IPs)
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "mysstic-vpc-prime"
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}

# 3. LA SUBRED (Una zona específica dentro de la VPC)
resource "aws_subnet" "mysstic_public_subnet" {
  vpc_id                  = aws_vpc.mysstic_vpc.id 
  cidr_block              = "10.0.1.0/24"          # Un bloque más chico (256 IPs) para servidores web
  map_public_ip_on_launch = true                   # Todo lo que nazca acá recibe IP pública
  availability_zone       = "us-east-2a"           # Elegimos un centro de datos físico específico en Ohio

  tags = {
    Name = "mysstic-public-subnet"
  }
}

# 4. EL INTERNET GATEWAY (La puerta hacia el mundo exterior)
resource "aws_internet_gateway" "mysstic_igw" {
  vpc_id = aws_vpc.mysstic_vpc.id

  tags = {
    Name = "mysstic-igw"
  }
}

# 5. TABLA DE RUTEO (El GPS de la red)
resource "aws_route_table" "mysstic_public_rt" {
  vpc_id = aws_vpc.mysstic_vpc.id

  route {
    cidr_block = "0.0.0.0/0"                # "Cualquier destino fuera de mi red"
    gateway_id = aws_internet_gateway.mysstic_igw.id # "Mandalo por el Internet Gateway"
  }

  tags = {
    Name = "mysstic-public-route-table"
  }
}

# 6. ASOCIACIÓN (Vincular el mapa a la subred)
resource "aws_route_table_association" "mysstic_public_assoc" {
  subnet_id      = aws_subnet.mysstic_public_subnet.id
  route_table_id = aws_route_table.mysstic_public_rt.id
}

# 7. SECURITY GROUP (El Firewall del servidor)
resource "aws_security_group" "mysstic_sg" {
  name        = "mysstic-allow-ssh"
  description = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.mysstic_vpc.id

  # INGRESS (Reglas de Entrada)
  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  # EGRESS (Reglas de Salida)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # El "-1" significa TODOS los protocolos (TCP, UDP, ICMP)
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysstic-sg-prime"
  }
}

# 8. EL SERVIDOR (La Instancia EC2)
resource "aws_instance" "mysstic_server" {
  ami           = "ami-0e68dc81dc36750a1" # El disco base de Debian 13 (us-east-2)
  instance_type = "t3.micro"              # El tamaño de la máquina (Free Tier)
  iam_instance_profile = aws_iam_instance_profile.mysstic_ec2_profile.name

  # Conectamos el servidor a la VPC
  subnet_id                   = aws_subnet.mysstic_public_subnet.id
  vpc_security_group_ids      = [aws_security_group.mysstic_sg.id] # Nota: Esto es una lista []
  associate_public_ip_address = true # Obligamos a AWS a darnos una IP pública

  # La llave de acceso (SSH)
  key_name = "mysstic-key" 

  # Configuración del Disco Duro (EBS)
  root_block_device {
    volume_size           = 8           
    volume_type           = "gp3"       # gp3 es la última generación, más rápida y barata
    encrypted             = true        # DevSecOps: Encriptación AES-256 obligatoria
    delete_on_termination = true        # Si destruimos la EC2, el disco se destruye (el backup vivirá en otro lado)
  }

  tags = {
    Name   = "mysstic-warden-node"
    Backup = "True"   # <--- Esta etiqueta es el láser que guía al robot DLM
  }

  # ------------------------------------------------------
  # LA FÁBRICA AUTOMÁTICA (Cloud-Init / UserData)
  # ------------------------------------------------------
  user_data = <<-EOF
              #!/bin/bash
              # Todo lo que pasa acá adentro se ejecuta como Root en el primer booteo

              # 1. Actualizar el sistema base
              apt-get update && apt-get upgrade -y

              # 2. Instalar herramientas de red y monitoreo base
              apt-get install -y ca-certificates curl gnupg htop ufw

              # 3. DevSecOps: Levantar el firewall interno (UFW) y permitir solo SSH por ahora
              ufw allow 22/tcp
              ufw --force enable

              # 4. Instalar Docker y Docker Compose 
              install -m 0755 -d /etc/apt/keyrings
              curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
              chmod a+r /etc/apt/keyrings/docker.gpg
              echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
              
              apt-get update
              apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

              # 5. Asegurar que el motor de contenedores arranque siempre con el sistema
              systemctl enable docker
              systemctl start docker
              EOF
}

# 9. OUTPUTS
output "server_public_ip" {
  description = "La IP publica para conectarnos por SSH"
  value       = aws_instance.mysstic_server.public_ip
}

# 10. Bucket S3 para el estado de Terraform
resource "aws_s3_bucket" "mysstic_terraform_state" {
  bucket = "mysstic-warden-tfstate-ez" #
  
  # Evita borrar este bucket por accidente en el futuro
  lifecycle {
    prevent_destroy = true 
  }

  tags = {
    Name        = "mysstic-tfstate-bucket"
    Environment = "DevSecOps"
  }
}

# 11. EL CANDADO DEL BUCKET (Versionado)
# Esto guarda un historial. Si pisás un archivo por error, podés recuperar la versión anterior.
resource "aws_s3_bucket_versioning" "mysstic_state_versioning" {
  bucket = aws_s3_bucket.mysstic_terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 12. EL CANDADO LÓGICO (Tabla DynamoDB para Lock del State)
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "mysstic-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "mysstic-tf-lock-table"
    Environment = "DevSecOps"
  }
}

# 13. EL CEREBRO DEL ROBOT (La Política de DLM)
resource "aws_dlm_lifecycle_policy" "mysstic_backup_policy" {
  description        = "Backup diario para MyssTic Warden - Retencion 7 dias"
  execution_role_arn = aws_iam_role.dlm_role.arn
  state              = "ENABLED"

  policy_details {
    resource_types = ["INSTANCE"] # Va a buscar Servidores enteros, no discos sueltos

    schedule {
      name = "Daily-3AM-Backup"

      create_rule {
        interval      = 24
        interval_unit = "HOURS"
        times         = ["03:00"] # A las 3:00 AM UTC saca la foto
      }

      retain_rule {
        count = 7 # Guarda las últimas 7 fotos. La octava borra la más vieja automáticamente.
      }

      tags_to_add = {
        SnapshotCreator = "DLM-Robot"
      }

      copy_tags = true # Copia las etiquetas de la EC2 original a la foto
    }

    # ¡LA MIRA LÁSER! El robot solo le saca fotos a los servidores que tengan esta etiqueta exacta:
    target_tags = {
      Backup = "True"
    }
  }
}