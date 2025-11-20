resource "aws_s3_bucket" "logs" {
  bucket = var.logs_bucket_name

  tags = {
    Project = var.project_name
    Env     = var.env
    Name    = "${var.project_name}-${var.env}-logs"
  }
}

resource "aws_s3_bucket_versioning" "logs" {
  bucket = aws_s3_bucket.logs.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    id     = "logs-transition-and-expire"
    status = "Enabled"

    transition {
      days          = var.lifecycle_transition_days
      storage_class = "STANDARD_IA"
    }

    expiration {
      days = var.lifecycle_expiration_days
    }
  }
}
