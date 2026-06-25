resource "aws_ecr_repository" "portfolio_repo" {
  name                 = "portfolio-sre"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}
