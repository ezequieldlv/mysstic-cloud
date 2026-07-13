# ==========================================
# 1. SUBRED PÚBLICA TEMPORAL (Requisito Multi-AZ ALB)
# ==========================================
resource "aws_subnet" "public_subnet_2_poc" {
  # checkov:skip=CKV_AWS_130: "IP pública automática requerida para subred de ALB Público"
  vpc_id                  = module.networking.vpc_id
  cidr_block              = "10.0.99.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = { Name = "mysstic-alb-subnet-poc" }
}

# Asociar la nueva subred a tu tabla de enrutamiento pública actual
resource "aws_route_table_association" "public_assoc_poc" {
  subnet_id = aws_subnet.public_subnet_2_poc.id
  # Como tu modulo no exporta el route_table_id, buscamos la tabla de la vpc dinamicamente:
  route_table_id = data.aws_route_table.public_rt.id
}

data "aws_route_table" "public_rt" {
  subnet_id = module.networking.public_subnet_id
}

# ==========================================
# 2. SECURITY GROUP DEL ALB
# ==========================================
resource "aws_security_group" "alb_sg_poc" {
  # checkov:skip=CKV_AWS_260: "Permitir HTTP (Puerto 80) global temporalmente para la PoC"
  # checkov:skip=CKV2_AWS_5: "SG atado correctamente al ALB"

  name        = "mysstic-alb-sg-poc"
  description = "Permitir HTTP de internet al ALB"
  vpc_id      = module.networking.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================
# 3. EL BALANCEADOR DE CARGA (ALB)
# ==========================================
resource "aws_lb" "main_poc" {
  # checkov:skip=CKV_AWS_150: "Deletion protection DESACTIVADO porque es una PoC efímera"
  # checkov:skip=CKV_AWS_91: "Access logging a S3 desactivado por costos (FinOps)"
  # checkov:skip=CKV2_AWS_28: "WAF no adjuntado en esta fase, se hará en la siguiente PoC"

  name                       = "mysstic-alb-poc"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg_poc.id]
  subnets                    = [module.networking.public_subnet_id, aws_subnet.public_subnet_2_poc.id]
  drop_invalid_header_fields = true # Buena práctica de ciberseguridad activada
}

# ==========================================
# 4. TARGET GROUP & HEALTH CHECK
# ==========================================
resource "aws_lb_target_group" "tg_poc" {
  name     = "mysstic-tg-poc"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.networking.vpc_id

  health_check {
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
  }
}

# ==========================================
# 5. LISTENER (El oído del ALB)
# ==========================================
resource "aws_lb_listener" "http_poc" {
  # checkov:skip=CKV_AWS_2: "HTTPS/SSL omitido temporalmente para la PoC efímera"
  # checkov:skip=CKV_AWS_103: "TLS/HTTPS omitido para PoC"
  # checkov:skip=CKV2_AWS_20: "Redirección HTTP a HTTPS omitida en PoC"

  load_balancer_arn = aws_lb.main_poc.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_poc.arn
  }
}

# ==========================================
# 6. ATTACHMENT & OUTPUT
# ==========================================
resource "aws_lb_target_group_attachment" "ec2_attach_poc" {
  target_group_arn = aws_lb_target_group.tg_poc.arn
  target_id        = module.compute.ec2_instance_id
  port             = 80
}

output "alb_url" {
  value       = aws_lb.main_poc.dns_name
  description = "URL generada por AWS para el ALB"
}
