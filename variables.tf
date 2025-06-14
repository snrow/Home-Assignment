variable "tf_state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  type        = string
}

variable "tf_app_data_bucket_name" {
  description = "Name of the S3 bucket for application data"
  type        = string
}