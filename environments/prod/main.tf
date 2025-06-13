provider "aws" {
  region = "eu-central-1"
}

module "sqs" {
  source     = "../../modules/infrastructure/sqs"
  queue_name = var.sqs_queue_name
}

module "vpc" {
  source       = "../../modules/networking/vpc"
  vpc_name     = var.vpc_name
  vpc_cidr     = var.vpc_cidr
  subnet_cidr  = var.subnet_cidr
}

# module "elb" {
#   source     = "../../modules/networking/elb"
#   elb_name   = var.elb_name
#   subnet_id  = module.vpc.subnet_id
#   vpc_id     = module.vpc.vpc_id
# }

# module "ecs" {
#   source        = "../../modules/compute/ecs"
#   cluster_name  = var.ecs_cluster_name
#   s3_bucket_arn = module.s3_app.bucket_arn
#   sqs_queue_url = module.sqs.queue_url
#   subnet_id     = module.vpc.subnet_id
# }