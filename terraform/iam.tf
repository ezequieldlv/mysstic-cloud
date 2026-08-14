
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = ["1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

resource "aws_iam_role" "github_actions_role" {
  name        = "mysstic-github-actions-role"
  description = "Rol asumido por GitHub Actions de forma efimera para CI/CD de MyssTic Warden"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = [
              "repo:ezequieldlv/mysstic-cloud:*",
              "repo:ezequieldlv/portfolio-sre:*"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_admin_attach" {
  # checkov:skip=CKV_AWS_274: "AdminAccess temporal para bootstrapping. Protegido por OIDC estricto"

  role       = aws_iam_role.github_actions_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "github_actions_role_arn" {
  description = "ARN del rol de IAM a configurar en el workflow de GitHub"
  value       = aws_iam_role.github_actions_role.arn
}

# ==========================================
# AUDITORÍA CONTINUA (ZERO TRUST)
# ==========================================
resource "aws_accessanalyzer_analyzer" "account_analyzer" {
  analyzer_name = "${local.project_name}-security-analyzer"
  type          = "ACCOUNT"

  tags = {
    Name        = "${local.project_name}-iam-analyzer"
    Environment = "DevSecOps"
  }
}
