variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "nat_instance_sg_id" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "llm_credentials" {
  type = map(string)
}

variable "repository_url" {
  type = map(string)
}

variable "sqs_arn" {
  type = string
}

variable "target_group_arn" {
  type = string
}
