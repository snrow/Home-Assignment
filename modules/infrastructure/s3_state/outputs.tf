output "state_bucket_name" {
  value       = aws_s3_bucket.state_bucket.bucket
  description = "Name of the S3 bucket for Terraform state"
}