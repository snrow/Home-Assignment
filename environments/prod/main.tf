provider "aws" {
  region = "eu-central-1"
}

data "terraform_remote_state" "root" {
  backend = "s3"
  config = {
    bucket = "terraform-state-bucket-eliran"
    key    = "global/terraform.tfstate"
    region = "eu-central-1"
  }
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

module "ecs" {
  source            = "../../modules/compute/ecs"
  cluster_name      = var.ecs_cluster_name
  s3_bucket_arn     = data.terraform_remote_state.root.outputs.app_data_bucket_arn
  sqs_queue_url     = module.sqs.queue_url
  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id            = module.vpc.vpc_id
  alb_sg_id         = module.alb.alb_sg_id
  target_group_arn  = module.alb.target_group_arn
  ecr_url_front     = var.ecr_url_front
  ecr_url_worker    = var.ecr_url_worker
  frontend_image_tag = var.frontend_image_tag
  queue_worker_image_tag = var.queue_worker_image_tag
  depends_on        = [module.vpc, module.alb]
}