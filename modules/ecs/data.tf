data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_ssm_parameter" "ecs_node_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

data "aws_iam_policy_document" "ecs_node_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ecs_task_doc" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "custom_task_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter"
    ]
    resources = ["arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
      "sqs:SendMessage"
    ]
    resources = [var.sqs_arn]

  }
}

data "aws_iam_policy_document" "custom_exec_task_document" {
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameters",
      "ssm:GetParameter"
    ]
    resources = ["arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/*"]
  }
}

data "aws_iam_policy" "ecs_basic_execution" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

data "aws_iam_policy" "ecs_node_role_document" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}