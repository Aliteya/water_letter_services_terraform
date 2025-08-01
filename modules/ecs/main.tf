locals {
  name_prefix   = "/llm"
  region        = var.region
  app_port      = 80
  instance_type = "t3.micro"
  image_id      = data.aws_ssm_parameter.ecs_node_ami.value
  services = {
    processor = {
      family         = "demo-processor"
      container_port = 80
      image_tag      = "latest"
      log_prefix     = "processor"
      secrets = [
        { "name" = "PROVIDER", "valueFrom" = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/llm/PROVIDER" },
        { "name" = "MODEL_NAME", "valueFrom" = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/llm/MODEL_NAME" },
        { "name" = "OPENROUTER_TOKEN", "valueFrom" = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/llm/OPENROUTER_TOKEN" }
      ]
    }
    publisher = {
      family         = "demo-publisher"
      container_port = 80
      image_tag      = "latest"
      log_prefix     = "publisher"
      secrets = [
        { "name" = "PROVIDER", "valueFrom" = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/llm/PROVIDER" },
        { "name" = "MODEL_NAME", "valueFrom" = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/llm/MODEL_NAME" },
        { "name" = "OPENROUTER_TOKEN", "valueFrom" = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/llm/OPENROUTER_TOKEN" },
        { "name" = "SQS_QUEUE_URL", "valueFrom" = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/llm/SQS_QUEUE_URL" },
        { "name" = "SERVICE_2_URL", "valueFrom" = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/llm/SERVICE_2_URL" }
      ]
    }
    subscriber = {
      family         = "demo-subscriber"
      container_port = 80
      image_tag      = "latest"
      log_prefix     = "subscriber"
      secrets = [
        { "name" = "DATABASE_USER", "valueFrom" = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/database/DATABASE_USER" },
        { "name" = "DATABASE_NAME", "valueFrom" = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/database/DATABASE_NAME" },
        { "name" = "DATABASE_PORT", "valueFrom" = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/database/DATABASE_PORT" },
        { "name" = "DATABASE_PASSWORD", "valueFrom" = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/database/DATABASE_PASSWORD" },
        { "name" = "SQS_QUEUE_URL", "valueFrom" = "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/llm/SQS_QUEUE_URL" }
      ]
    }
  }
}

resource "aws_sqs_queue" "log_queue" {
  name                      = "service3-sqs"
  delay_seconds             = 20
  max_message_size          = 1096
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

resource "aws_ecs_cluster" "main_cluster" {
  name = "demo-cluster"
}

resource "aws_iam_role" "ecs_node_role" {
  name_prefix        = "demo-ecs-node-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_node" {
  name_prefix = "demo-ecs-node-profile"
  path        = "/ecs/instance/"
  role        = aws_iam_role.ecs_node_role.name
}

resource "aws_security_group" "ecs_node_sg" {
  name_prefix = "demo-ecs-node-sg-"
  vpc_id      = var.vpc_id
  # ingress {
  #     from_port       = 0 
  #     to_port         = 65535
  #     protocol        = "tcp"
  #     security_groups = [var.alb_sg_id]
  # }
  ingress {
    description     = "Allow all traffic from the NAT instance"
    protocol        = "-1"
    from_port       = 0
    to_port         = 0
    security_groups = [var.nat_instance_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "apologize-dev-lt" {
  name_prefix            = "apologize-dev"
  image_id               = local.image_id
  instance_type          = local.instance_type
  vpc_security_group_ids = [aws_security_group.ecs_node_sg.id]
  key_name               = "bastion-key"
  iam_instance_profile {
    arn = aws_iam_instance_profile.ecs_node.arn
  }
  monitoring { enabled = true }
  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.main_cluster.name} >> /etc/ecs/ecs.config;
    EOF
  )
}

resource "aws_autoscaling_group" "ecs" {
  name_prefix               = "demo-ecs-asg-"
  vpc_zone_identifier       = var.private_subnet_ids
  min_size                  = 3
  max_size                  = 3
  health_check_grace_period = 0
  health_check_type         = "EC2"
  protect_from_scale_in     = false

  launch_template {
    id      = aws_launch_template.apologize-dev-lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "demo-ecs-cluster"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}

resource "aws_ecs_capacity_provider" "main-cp" {
  name = "apologize-dev"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"
  }
}

resource "aws_ecs_cluster_capacity_providers" "main-cp" {
  cluster_name       = aws_ecs_cluster.main_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.main-cp.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main-cp.name
    base              = 1
    weight            = 100
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name_prefix        = "demo-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_policy" "task_policy" {
  name = "tasks_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow"
        "Action" : ["ssm:GetParameters", "ssm:GetParameter"]
        "Resource" : "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/*"
      },
      {
        "Effect" : "Allow"
        "Action" : ["sqs:DeleteMessage", "sqs:GetQueueUrl", "sqs:GetQueueAttributes", "sqs:ReceiveMessage", "sqs:SendMessage"]
        "Resource" : aws_sqs_queue.log_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.task_policy.arn
}

resource "aws_iam_role" "ecs_exec_role" {
  name_prefix        = "demo-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_policy" "exec_task_policy" {
  name = "exec_tasks_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow"
        "Action" : ["ssm:GetParameters"]
        "Resource" : "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy_custom" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = aws_iam_policy.exec_task_policy.arn
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/demo"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "apps" {
  for_each           = local.services
  family             = each.value.family
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  network_mode       = "awsvpc"
  cpu                = 256
  memory             = 256

  container_definitions = jsonencode([{
    name  = each.key
    image = "${var.repository_url[each.key]}:latest"
    # image = "public.ecr.aws/docker/library/hello-world:latest"
    essential    = true
    portMappings = [{ containerPort = 80, hostPort = 80 }]
    secrets      = each.value.secrets

    logConfiguration = {
      logDriver = "awslogs",
      options = {
        "awslogs-region"        = "eu-north-1",
        "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
        "awslogs-stream-prefix" = each.value.log_prefix
      }
    },
  }])
}

resource "aws_security_group" "ecs_tasks" {
  name   = "ecs-security-group"
  vpc_id = var.vpc_id

  # ingress {
  #     protocol = "tcp"
  #     from_port = local.app_port
  #     to_port = local.app_port
  #     security_groups = [var.alb_sg_id]
  # }
  # ingress {
  #     from_port       = 0 
  #     to_port         = 0
  #     protocol        = "-1"
  #     cidr_blocks = ["0.0.0.0/0"]
  # }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "apps" {
  for_each             = local.services
  cluster              = aws_ecs_cluster.main_cluster.id
  name                 = each.key
  task_definition      = aws_ecs_task_definition.apps[each.key].arn
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    security_groups = [aws_security_group.ecs_tasks.id]
    subnets         = var.private_subnet_ids
  }

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.main-cp.name
    base              = 1
    weight            = 100
  }

  ordered_placement_strategy {
    type  = "spread"
    field = "attribute:ecs.availability-zone"
  }

}