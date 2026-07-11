resource "aws_ecr_repository" "frontend_repo" {
  # checkov:skip=CKV_AWS_136: Usamos cifrado AES-256 por defecto
  # checkov:skip=CKV_AWS_51: Mutabilidad habilitada para pipelines
  name                 = "portfolio-sre-frontend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "backend_repo" {
  # checkov:skip=CKV_AWS_136: Usamos cifrado AES-256 por defecto
  # checkov:skip=CKV_AWS_51: Mutabilidad habilitada para pipelines
  name                 = "portfolio-sre-backend"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}
