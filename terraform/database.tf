# ==========================================
# 0. Secrets vault (Zero Trust)
# ==========================================
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "mysstic_db_secret" {
  name                    = "mysstic-warden-db-credentials"
  recovery_window_in_days = 0 
}

resource "aws_secretsmanager_secret_version" "mysstic_db_secret_val" {
  secret_id     = aws_secretsmanager_secret.mysstic_db_secret.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.db_password.result
  })
}

# ==========================================  
# 1. RDS SECURITY GROUP
# ==========================================
resource "aws_security_group" "mysstic_db_sg" {
  name        = "mysstic-rds-sg"
  description = "Permitir trafico PostgreSQL SOLO desde la EC2"
  vpc_id      = aws_vpc.mysstic_vpc.id

  ingress {
    description     = "Conexion exclusiva desde el servidor MyssTic"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    
    security_groups = [aws_security_group.mysstic_sg.id] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysstic-db-sg-prime"
  }
}

# ==========================================
# 2. DATABASE ENGINE (PostgreSQL)
# ==========================================
resource "aws_db_instance" "mysstic_postgres" {
  identifier             = "mysstic-warden-db"
  engine                 = "postgres"
  engine_version         = "16"             
  instance_class         = "db.t3.micro"      
  allocated_storage      = 20                 
  
  db_subnet_group_name   = aws_db_subnet_group.mysstic_db_group.name
  vpc_security_group_ids = [aws_security_group.mysstic_db_sg.id]

  db_name  = "myssticwarden"
  username = "dbadmin"
  password = random_password.db_password.result

  publicly_accessible = false
  skip_final_snapshot = true 
}

# ==========================================
# 3. OUTPUT (URL)
# ==========================================
output "database_endpoint" {
  description = "La URL interna para que la EC2 se conecte a PostgreSQL"
  value       = aws_db_instance.mysstic_postgres.endpoint
}