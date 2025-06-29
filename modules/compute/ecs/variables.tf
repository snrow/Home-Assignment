variable "cluster_name" { type = string }
variable "s3_bucket_arn" { type = string }
variable "sqs_queue_url" { type = string }
variable "private_subnet_ids" { type = list(string) }
variable "vpc_id" { type = string }
variable "alb_sg_id" { type = string }
variable "target_group_arn" { type = string }
variable "ecr_url_front" { type = string }
variable "ecr_url_worker" { type = string }
variable "frontend_image_tag" { type = string }
variable "queue_worker_image_tag" { type = string }
variable "unique_id" {
  description = "Unique identifier for ECS service names to avoid conflicts"
  type        = string
  default     = "" # Optional default, overridden in pipeline
}