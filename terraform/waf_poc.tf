# ==========================================
# 1. REDES Y BALANCEADOR (Recreación temporal)
# ==========================================
resource "aws_subnet" "public_subnet_2_poc" {
  # checkov:skip=CKV_AWS_130: "IP pública automática requerida para subred de ALB Público"
  vpc_id                  = module.networking.vpc_id
  cidr_block              = "10.0.99.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true
  tags                    = { Name = "mysstic-alb-subnet-poc" }
}

resource "aws_route_table_association" "public_assoc_poc" {
  subnet_id      = aws_subnet.public_subnet_2_poc.id
  route_table_id = data.aws_route_table.public_rt.id
}

data "aws_route_table" "public_rt" {
  subnet_id = module.networking.public_subnet_id
}

resource "aws_security_group" "alb_sg_poc" {
  # checkov:skip=CKV_AWS_260: "Permitir HTTP temporalmente para la PoC"
  # checkov:skip=CKV2_AWS_5: "SG atado correctamente al ALB"
  # checkov:skip=CKV_AWS_382: "SG atado correctamente al ALB"
  # checkov:skip=CKV_AWS_23: "SG atado correctamente al ALB"
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

resource "aws_lb" "main_poc" {
  # checkov:skip=CKV_AWS_150: "Deletion protection DESACTIVADO (PoC)"
  # checkov:skip=CKV_AWS_91: "Access logging desactivado (FinOps)"
  # checkov:skip=CKV2_AWS_20: "Redirección HTTP omitida en PoC"
  # checkov:skip=CKV2_AWS_76: "Redirección HTTP omitida en PoC"

  name                       = "mysstic-alb-poc"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg_poc.id]
  subnets                    = [module.networking.public_subnet_id, aws_subnet.public_subnet_2_poc.id]
  drop_invalid_header_fields = true
}

resource "aws_lb_target_group" "tg_poc" {
  # checkov:skip=CKV_AWS_378: "Redirección HTTP omitida en PoC"

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
    matcher             = "200-499"
  }
}

resource "aws_lb_listener" "http_poc" {
  # checkov:skip=CKV_AWS_2: "HTTPS/SSL omitido para PoC"
  # checkov:skip=CKV_AWS_103: "TLS/HTTPS omitido para PoC"
  # checkov:skip=CKV2_AWS_20: "Redirección HTTP omitida en PoC"
  load_balancer_arn = aws_lb.main_poc.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_poc.arn
  }
}

resource "aws_lb_target_group_attachment" "ec2_attach_poc" {
  target_group_arn = aws_lb_target_group.tg_poc.arn
  target_id        = module.compute.ec2_instance_id
  port             = 80
}

# ==========================================
# 2. WEB APPLICATION FIREWALL (WAFv2)
# ==========================================
resource "aws_wafv2_web_acl" "waf_poc" {
  # checkov:skip=CKV_AWS_192: "Redirección HTTP omitida en PoC"
  # checkov:skip=CKV2_AWS_31: "Redirección HTTP omitida en PoC"


  name        = "mysstic-waf-poc"
  description = "Escudo protector contra inyecciones SQL"
  scope       = "REGIONAL" # Necesario para balanceadores

  default_action {
    allow {} # Por defecto, deja pasar todo el tráfico sano
  }

  rule {
    name     = "BlockSQLInjection"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "waf-sqli-metric"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "waf-main-metric"
    sampled_requests_enabled   = true
  }
}

# Pegamos el WAF al Balanceador
resource "aws_wafv2_web_acl_association" "waf_alb_assoc" {
  resource_arn = aws_lb.main_poc.arn
  web_acl_arn  = aws_wafv2_web_acl.waf_poc.arn
}

output "waf_alb_url" {
  value       = aws_lb.main_poc.dns_name
  description = "URL del ALB protegido por WAF"
}
