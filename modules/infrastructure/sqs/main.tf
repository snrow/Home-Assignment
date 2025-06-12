resource "aws_sqs_queue" "data_queue" {
  name = var.queue_name
}