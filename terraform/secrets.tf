data "aws_secretsmanager_secret" "core_secrets" {
  name = "mysstic-core-secrets"
}

data "aws_secretsmanager_secret_version" "current_secrets" {
  secret_id = data.aws_secretsmanager_secret.core_secrets.id
}

locals {
  core_secrets = jsondecode(data.aws_secretsmanager_secret_version.current_secrets.secret_string)
}