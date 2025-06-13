provider "aws" {
  region = "eu-central-1"
}

module "s3_state_prod" {
  source            = "./modules/infrastructure/s3_state"
  state_bucket_name = var.tf_state_bucket_name_prod
}

module "s3_app_data_prod" {
  source            = "./modules/infrastructure/s3_state"
  state_bucket_name = var.tf_app_data_bucket_name_prod
}