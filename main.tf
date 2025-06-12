provider "aws" {
  region = "eu-central-1"
}

module "s3_state" {
  source            = "./modules/infrastructure/s3_state"
  state_bucket_name = var.tf_state_bucket_name
}