locals {
  app_port = 80
}

resource "aws_security_group" "alb" {
  name   = "alb-security-group"
  vpc_id = var.vpc_id
  # ingress {
  #   protocol    = "tcp"
  #   from_port   = 80
  #   to_port     = local.app_port
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  dynamic "ingress" {
    for_each = [80, 443]
    content {
      protocol    = "tcp"
      from_port   = ingress.value
      to_port     = ingress.value
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "apologize_alb" {
  name               = "apologize-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids
}

resource "aws_lb_target_group" "target_ip_group" {
  name        = "ecs-target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200-299"
    timeout             = "3"
    path                = "/health"
    unhealthy_threshold = "2"
  }
}

resource "aws_alb_listener" "listener" {
  load_balancer_arn = aws_lb.apologize_alb.arn
  port              = local.app_port
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.target_ip_group.arn
    type             = "forward"
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = var.validation_method

  lifecycle {
    create_before_destroy = true
  }
}