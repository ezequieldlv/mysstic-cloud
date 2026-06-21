# checkov:skip=CKV2_AWS_39: "DNS query logging omitido por costos (FinOps)"
resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = { Name = "mysstic-dns-zone" }
}

# checkov:skip=CKV2_AWS_23: "El registro A se asocia dinámicamente a la IP de EC2"
resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = "300"
  records = [var.ec2_public_ip]
}

resource "aws_route53_record" "wildcard" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "*.${var.domain_name}"
  type    = "CNAME"
  ttl     = "300"
  records = [var.domain_name]
}