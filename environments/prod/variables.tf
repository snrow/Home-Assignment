variable "tf_state_bucket_name_prod" { type = string }
variable "tf_app_data_bucket_name_prod" { type = string }
variable "sqs_queue_name" { type = string }
variable "vpc_name" { type = string }
variable "vpc_cidr" { type = string }
variable "subnet_cidr" { type = string }
variable "alb_name" { type = string }
# variable "ecs_cluster_name" { type = string }