variable "alb_name" { type = string }
variable "public_subnet_ids" { type = list(string) }
variable "vpc_id" { type = string }
variable "private_subnet_cidrs" { type = list(string) }