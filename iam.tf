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