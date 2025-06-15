resource "aws_security_group" "alb_sg" {
  vpc_id = var.vpc_id
  name   = "${var.alb_name}-sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 5000  # Allow outbound to Microservice 1
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = var.private_subnet_cidrs  # Restrict to private subnets
  }

  tags = { Name = "${var.alb_name}-sg" }
}

resource "aws_lb" "main" {
  name               = var.alb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids
  enable_deletion_protection = false
  tags = { Name = var.alb_name }
}

resource "aws_lb_target_group" "frontend_service_tg" {
  name        = "${var.alb_name}-tg"
  port        = 5000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"
  health_check {
    enabled             = true
    path                = "/"
    port                = "5000"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  tags = { Name = "${var.alb_name}-tg" }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_service_tg.arn
  }
}