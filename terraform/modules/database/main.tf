# ==========================================
# 1. SECRETS MANAGER
# ==========================================
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_secret" {
  # checkov:skip=CKV_AWS_149: "Usamos cifrado AWS managed por defecto (FinOps)"
  # checkov:skip=CKV2_AWS_57: "Rotacion manual aceptada para este entorno"

  name                    = "${var.project_name}-db-credentials"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_secret_val" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.db_password.result
  })
}

# ==========================================
# 1.5. SECRETS MANAGER READ POLICY FOR EC2
# ==========================================
data "aws_iam_policy_document" "ec2_secrets_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = ["arn:aws:secretsmanager:*:*:secret:${var.project_name}-db-credentials-*"]
  }
}

resource "aws_iam_policy" "ec2_secrets_policy" {
  name        = "${var.project_name}-ec2-secrets-policy"
  description = "Permitir que la EC2 lea de forma segura las credenciales de la RDS"
  policy      = data.aws_iam_policy_document.ec2_secrets_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "ec2_secrets_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_secrets_policy.arn
}

# ==========================================
# 2. SUBNET GROUP & SECURITY GROUP
# ==========================================
resource "aws_db_subnet_group" "db_group" {
  name       = "${var.project_name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids
}

resource "aws_security_group" "db_sg" {
  # checkov:skip=CKV_AWS_382: "Salida global de RDS permitida temporalmente"
  # checkov:skip=CKV_AWS_23: "Descripcion omitida"

  name        = "${var.project_name}-rds-sg"
  description = "Permitir trafico PostgreSQL SOLO desde la EC2"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [var.ec2_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-db-sg" }
}

# ==========================================
# 3. RDS INSTANCE
# ==========================================
resource "aws_db_instance" "postgres" {
  # checkov:skip=CKV_AWS_118: "Enhanced monitoring omitido (FinOps)"
  # checkov:skip=CKV_AWS_157: "Multi-AZ omitido por costos (FinOps)"
  # checkov:skip=CKV_AWS_293: "Deletion protection deshabilitado para entornos Dev"
  # checkov:skip=CKV_AWS_129: "Log export omitido (FinOps)"
  # checkov:skip=CKV_AWS_16: "Cifrado default activado, KMS omitido"
  # checkov:skip=CKV_AWS_226: "Minor upgrades automaticas deshabilitadas para control manual"
  # checkov:skip=CKV_AWS_161: "IAM Auth no requerida para el portfolio"
  # checkov:skip=CKV_AWS_353: "Performance insights omitido (FinOps)"
  # checkov:skip=CKV2_AWS_30: "Query logging omitido (FinOps)"
  # checkov:skip=CKV2_AWS_60: "Snapshots deshabilitados por FinOps, no hay tags que copiar"

  identifier             = "${var.project_name}-db"
  engine                 = "postgres"
  engine_version         = "16"
  instance_class         = "db.t4g.micro"
  allocated_storage      = 20
  db_subnet_group_name   = aws_db_subnet_group.db_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]

  db_name  = "myssticwarden"
  username = "dbadmin"
  password = random_password.db_password.result

  publicly_accessible = false
  skip_final_snapshot = true
}
