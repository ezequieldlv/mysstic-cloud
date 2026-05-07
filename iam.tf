# 1. LA POLÍTICA DE CONFIANZA
# Le decimos a AWS que los servidores EC2 pueden asumir este rol.
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

# 2. EL ROL 
resource "aws_iam_role" "mysstic_ec2_role" {
  name               = "mysstic-ec2-s3-readonly-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust_policy.json
}

# 3. LOS PERMISOS (Adjuntamos la política de Solo Lectura de S3)
resource "aws_iam_role_policy_attachment" "s3_readonly_attach" {
  role       = aws_iam_role.mysstic_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# 4. EL ENCHUFE (El Instance Profile)
# Esto es lo que físicamente conectamos al servidor Debian
resource "aws_iam_instance_profile" "mysstic_ec2_profile" {
  name = "mysstic-ec2-profile"
  role = aws_iam_role.mysstic_ec2_role.name
}

# 5. EL PERMISO DEL ROBOT DLM (IAM Role)
data "aws_iam_policy_document" "dlm_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["dlm.amazonaws.com"] # El guardia de IAM solo deja pasar al robot DLM
    }
  }
}

resource "aws_iam_role" "dlm_role" {
  name               = "mysstic-dlm-backup-role"
  assume_role_policy = data.aws_iam_policy_document.dlm_trust_policy.json
}

# AWS ya tiene una política oficial pre-creada para que DLM haga backups, se la pegamos al rol:
resource "aws_iam_role_policy_attachment" "dlm_role_attach" {
  role       = aws_iam_role.dlm_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSDataLifecycleManagerServiceRole"
}