provider "aws" {
  region = "eu-central-1"
}

module "sqs" {
  source     = "../../modules/infrastructure/sqs"
  queue_name = var.sqs_queue_name
}

module "vpc" {
  source              = "../../modules/networking/vpc"
  vpc_name            = var.vpc_name
  vpc_cidr            = var.vpc_cidr
  subnet_cidr_a       = var.subnet_cidr_a
  subnet_cidr_b       = var.subnet_cidr_b
  subnet_cidr_private_a = var.subnet_cidr_private_a
  subnet_cidr_private_b = var.subnet_cidr_private_b
  region              = var.region
}

module "alb" {
  source              = "../../modules/networking/alb"
  alb_name            = var.alb_name
  public_subnet_ids   = module.vpc.public_subnet_ids
  vpc_id              = module.vpc.vpc_id
  private_subnet_cidrs = [var.subnet_cidr_private_a, var.subnet_cidr_private_b]
  depends_on          = [module.vpc]
}

# module "ecs" {
#   source            = "../../modules/compute/ecs"
#   cluster_name      = var.ecs_cluster_name
#   s3_bucket_arn     = module.s3_app.bucket_arn
#   sqs_queue_url     = module.sqs.queue_url
#   private_subnet_ids = module.vpc.private_subnet_ids
#   vpc_id            = module.vpc.vpc_id
#   alb_sg_id         = module.alb.alb_sg_id
# }