terraform {
  backend "s3" {
    bucket      = "terraform-state-bucket-eliran"
    key         = "prod/terraform.tfstate"
    region      = "eu-central-1"
    use_lockfile = true
  }
}