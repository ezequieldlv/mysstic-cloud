resource "aws_route53_zone" "main" {
# checkov:skip=CKV2_AWS_39: "DNS query logging omitido por costos (FinOps)"
# checkov:skip=CKV2_AWS_38: "DNSSEC requiere KMS de pago, omitido por FinOps"

  name = var.domain_name
  tags = { Name = "mysstic-dns-zone" }
}

resource "aws_route53_record" "root" {
# checkov:skip=CKV2_AWS_23: "El registro A se asocia dinámicamente a la IP de EC2"

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