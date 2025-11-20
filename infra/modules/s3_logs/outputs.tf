output "logs_bucket_name" {
  description = "Name of the S3 bucket used for logs."
  value       = aws_s3_bucket.logs.bucket
}

output "logs_bucket_arn" {
  description = "ARN of the S3 bucket used for logs."
  value       = aws_s3_bucket.logs.arn
}
