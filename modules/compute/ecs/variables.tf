variable "cluster_name" { type = string }
variable "s3_bucket_arn" { type = string }
variable "sqs_queue_url" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "vpc_id" { type = string }
variable "alb_sg_id" { type = string }
variable "target_group_arn" { type = string }