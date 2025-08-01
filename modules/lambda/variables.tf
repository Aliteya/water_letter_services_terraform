variable "region" {
    type = string
}

variable "vpc_id" {
    type = string
}

variable "private_subnet_ids" {
    type = list(string)
}

variable "repository_url" {
    type = map(string)
}

variable "sqs_arn" {
  type = string
}
