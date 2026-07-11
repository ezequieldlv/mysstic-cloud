output "logs_bucket_id" {
  value = aws_s3_bucket.logs_bucket.id
}

output "logs_bucket_arn" {
  value = aws_s3_bucket.logs_bucket.arn
}
