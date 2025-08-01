locals {
  name_prefix = "/sqs"
}

resource "aws_sqs_queue" "log_queue" {
  name                      = "service3-sqs"
  delay_seconds             = 20
  max_message_size          = 1096
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
}

resource "aws_ssm_parameter" "queue_url" {
  name  = "${local.name_prefix}/SQS_QUEUE_URL"
  type  = "SecureString"
  value = aws_sqs_queue.log_queue.url
}