locals {
  all_traffic = "0.0.0.0/0"
  image_tag   = "latest"
  variables = {
    "DATABASE_USER"     = "/database/DATABASE_USER",
    "DATABASE_NAME"     = "/database/DATABASE_NAME",
    "DATABASE_PORT"     = "/database/DATABASE_PORT",
    "DATABASE_HOST"     = "/database/DATABASE_HOST",
    "DATABASE_PASSWORD" = "/database/DATABASE_PASSWORD"
  }
}
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_security_group" "lambda_sg" {
  vpc_id = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.all_traffic]
  }

}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole"
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        }

      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name = "lambda_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        "Effect" : "Allow"
        "Action" : ["ssm:GetParameters", "ssm:GetParameter"]
        "Resource" : "arn:aws:ssm:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:parameter/database/*"
      },
      {
        "Effect" : "Allow",
        "Action" : ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueUrl", "sqs:GetQueueAttributes"]
        "Resource" : var.sqs_arn
      },
      {
        "Effect" : "Allow",
        "Action" : ["ec2:CreateNetworkInterface", "ec2:DescribeNetworkInterfaces", "ec2:DescribeSubnets", "ec2:DeleteNetworkInterface", "ec2:AssignPrivateIpAddresses", "ec2:UnassignPrivateIpAddresses"]
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_sqs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "subscriber" {
  function_name = "subscriber"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "${var.repository_url["subscriber"]}:${local.image_tag}"
  timeout       = 30
  memory_size   = 512
  environment {
    variables = local.variables
  }
  vpc_config {
    subnet_ids         = var.private_subnet_ids
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = var.sqs_arn
  function_name    = aws_lambda_function.subscriber.arn
  batch_size       = 5

  scaling_config {
    maximum_concurrency = 50
  }
}