resource "aws_s3_bucket" "state_bucket" {
  bucket = var.state_bucket_name

  lifecycle {
    prevent_destroy = true  # Protects bucket from terraform destroy
  }

  tags = {
    Name = var.state_bucket_name
  }
}

resource "aws_s3_bucket_versioning" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state_bucket" {
  bucket = aws_s3_bucket.state_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state_bucket" {
  bucket                  = aws_s3_bucket.state_bucket.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}