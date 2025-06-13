output "prod_state_bucket_name" {
  value       = module.s3_state_prod.state_bucket_name
  description = "Name of the S3 bucket used for Terraform state files in the prod environment"
}

output "prod_app_data_bucket_name" {
  value       = module.s3_app_data_prod.state_bucket_name
  description = "Name of the S3 bucket used for application data in the prod environment"
}