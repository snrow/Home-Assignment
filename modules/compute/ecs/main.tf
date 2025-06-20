resource "aws_ecs_cluster" "cluster" {
  name = var.cluster_name
  tags = { Name = var.cluster_name }
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = var.vpc_id
  name   = "${var.cluster_name}-sg"

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }
  ingress {
    from_port       = 5001
    to_port         = 5001
    protocol        = "tcp"
    security_groups = [var.alb_sg_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.cluster_name}-sg" }
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.cluster_name}-task-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.cluster_name}-execution-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "ecs_task_policy" {
  role = aws_iam_role.ecs_task_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["sqs:*"]
        Resource = "arn:aws:sqs:eu-central-1:048999592382:prod-data-queue"
      },
      {
        Effect   = "Allow"
        Action   = ["s3:*"]
        Resource = "${var.s3_bucket_arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters"]
        Resource = "arn:aws:ssm:eu-central-1:048999592382:parameter/app/frontend/token"
      }
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  role = aws_iam_role.ecs_task_execution_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter", "ssm:GetParameters"]
        Resource = "arn:aws:ssm:eu-central-1:048999592382:parameter/app/frontend/token"
      }
    ]
  })
}

# frontend_service
resource "aws_ecs_task_definition" "frontend_service" {
  family                   = "frontend-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([{
    name  = "frontend"
    image = "${var.ecr_url_front}:${var.frontend_image_tag}"
    portMappings = [{ containerPort = 5000, hostPort = 5000, protocol = "tcp" }]
    essential = true
    environment = [
      { name = "AWS_REGION", value = "eu-central-1" },
      { name = "SQS_QUEUE_URL", value = "https://sqs.eu-central-1.amazonaws.com/048999592382/prod-data-queue" }
    ]
    secrets = [
      { name = "TOKEN", valueFrom = "arn:aws:ssm:eu-central-1:048999592382:parameter/app/frontend/token" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/frontend-service"
        "awslogs-region"        = "eu-central-1"
        "awslogs-stream-prefix" = "frontend"
      }
    }
  }])
}

resource "aws_cloudwatch_log_group" "frontend_service" {
  name              = "/ecs/frontend-service"
  retention_in_days = 7
  tags = { Name = "frontend-service-logs" }
}

resource "aws_ecs_service" "frontend_service" {
  name                              = "frontend-service"
  cluster                           = aws_ecs_cluster.cluster.id
  task_definition                   = aws_ecs_task_definition.frontend_service.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds = 120
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "frontend"
    container_port   = 5000
  }
  depends_on = [aws_iam_role_policy.ecs_task_execution_policy, aws_iam_role_policy.ecs_task_policy]
}

# queue_worker_service
resource "aws_ecs_task_definition" "queue_worker_service" {
  family                   = "queue-worker-service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([{
    name  = "sqs-puller"
    image = "${var.ecr_url_worker}:${var.queue_worker_image_tag}"
    portMappings = [{ containerPort = 5001, hostPort = 5001, protocol = "tcp" }]
    essential = true
    environment = [
      { name = "AWS_REGION", value = "eu-central-1" },
      { name = "SQS_QUEUE_URL", value = "https://sqs.eu-central-1.amazonaws.com/048999592382/prod-data-queue" }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/queue-worker-service"
        "awslogs-region"        = "eu-central-1"
        "awslogs-stream-prefix" = "sqs-puller"
      }
    }
  }])
}

resource "aws_cloudwatch_log_group" "queue_worker_service" {
  name              = "/ecs/queue-worker-service"
  retention_in_days = 7
  tags = { Name = "queue-worker-service-logs" }
}

resource "aws_ecs_service" "queue_worker_service" {
  name                              = "queue-worker-service"
  cluster                           = aws_ecs_cluster.cluster.id
  task_definition                   = aws_ecs_task_definition.queue_worker_service.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
  depends_on = [aws_iam_role_policy.ecs_task_execution_policy, aws_iam_role_policy.ecs_task_policy]
}