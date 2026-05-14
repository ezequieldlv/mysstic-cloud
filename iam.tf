# ==========================================
# 1. EC2 IAM ROLE & PROFILE
# ==========================================
data "aws_iam_policy_document" "ec2_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "mysstic_ec2_role" {
  name               = "mysstic-ec2-s3-readonly-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "s3_readonly_attach" {
  role       = aws_iam_role.mysstic_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

resource "aws_iam_instance_profile" "mysstic_ec2_profile" {
  name = "mysstic-ec2-profile"
  role = aws_iam_role.mysstic_ec2_role.name
}

# ==========================================
# 2. DLM IAM ROLE
# ==========================================
data "aws_iam_policy_document" "dlm_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "dlm_role" {
  name               = "mysstic-dlm-backup-role"
  assume_role_policy = data.aws_iam_policy_document.dlm_trust_policy.json
}

resource "aws_iam_role_policy_attachment" "dlm_role_attach" {
  role       = aws_iam_role.dlm_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}

# ==========================================
# 3. LAMBDA IAM ROLE (TELEGRAM ALERTER)
# ==========================================
resource "aws_iam_role" "lambda_exec_role" {
  name = "mysstic_lambda_telegram_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Logs permission
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}