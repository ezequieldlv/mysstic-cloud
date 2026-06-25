resource "aws_ecr_repository" "portfolio_repo" {
  # checkov:skip=CKV_AWS_136: Usamos cifrado AES-256 por defecto de AWS (más barato y suficiente)
  # checkov:skip=CKV_AWS_51: Habilitamos mutabilidad para entornos de desarrollo/stage dinámicos
  name                 = "portfolio-sre"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
