resource "aws_s3_bucket" "logs_bucket" {
  # checkov:skip=CKV_AWS_145: "Usamos cifrado AES-256 nativo de AWS, KMS es de pago (FinOps)"
  # checkov:skip=CKV_AWS_18: "Access logging recursivo omitido para bucket de logs"
  # checkov:skip=CKV_AWS_144: "Replicación Cross-Region omitida por costos (FinOps)"
  # checkov:skip=CKV_AWS_21: "Versionado innecesario para logs inmutables"
  # checkov:skip=CKV2_AWS_62: "Notificaciones de eventos no requeridas en esta fase"
  bucket = "${var.project_name}-security-logs"

  tags = {
    Name = "${var.project_name}-logs"
  }
}

resource "aws_s3_bucket_public_access_block" "logs_bucket_block" {
  bucket                  = aws_s3_bucket.logs_bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "force_https_policy" {
  statement {
    sid    = "AllowSSLRequestsOnly"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.logs_bucket.arn,
      "${aws_s3_bucket.logs_bucket.arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "logs_bucket_policy" {
  bucket = aws_s3_bucket.logs_bucket.id
  policy = data.aws_iam_policy_document.force_https_policy.json
}

resource "aws_s3_bucket_lifecycle_configuration" "logs_lifecycle" {
  bucket = aws_s3_bucket.logs_bucket.id

  rule {
    id     = "archive_and_delete_logs"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    transition {
      days          = 30
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 90
    }
  }
}
