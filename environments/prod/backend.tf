terraform {
  backend "s3" {
    bucket  = "terraform-state-bucket-eliran-prod"
    key     = "prod/terraform.tfstate"
    region  = "eu-central-1"
  }
}