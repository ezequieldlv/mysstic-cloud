resource "aws_s3_bucket" "logs_bucket" {
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

    transition {
      days          = 30
      storage_class = "DEEP_ARCHIVE"
    }

    expiration {
      days = 90
    }
  }
}
