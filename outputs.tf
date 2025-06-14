output "state_bucket_name" {
  value       = module.s3_state_prod.state_bucket_name
  description = "Name of the S3 bucket used for Terraform state files"
}

output "app_data_bucket_arn" {
  value       = module.s3_app_data_prod.bucket_arn
  description = "ARN of the S3 bucket used for application data"
}