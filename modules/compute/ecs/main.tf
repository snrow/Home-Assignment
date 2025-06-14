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
      { Effect = "Allow", Action = ["sqs:*"], Resource = var.sqs_queue_url },
      { Effect = "Allow", Action = ["s3:*"], Resource = "${var.s3_bucket_arn}/*" },
      { Effect = "Allow", Action = ["ssm:GetParameter"], Resource = "*" }
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
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_ecs_task_definition" "ms1" {
  family                   = "${var.cluster_name}-ms1"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  container_definitions = jsonencode([{
    name  = "microservice-1"
    image = "amazon/amazon-ecs-sample:latest"  # Replace with your ECR image
    portMappings = [{ containerPort = 5000, hostPort = 5000 }]
    essential = true
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/${var.cluster_name}-ms1"
        "awslogs-region"        = "eu-central-1"
        "awslogs-stream-prefix" = "ms1"
      }
    }
  }])
}

resource "aws_cloudwatch_log_group" "ms1" {
  name              = "/ecs/${var.cluster_name}-ms1"
  retention_in_days = 7
  tags = { Name = "${var.cluster_name}-ms1-logs" }
}

resource "aws_ecs_service" "ms1" {
  name            = "${var.cluster_name}-ms1"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.ms1.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "microservice-1"
    container_port   = 5000
  }
  depends_on = [aws_iam_role_policy.ecs_task_execution_policy]
}