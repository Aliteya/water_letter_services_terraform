variable "vpc_id" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "lambda_sg_id" {
  type = string
}

variable "nat_instance_sg_id" {
  type = string
}

variable "database_credentials" {
  type = map(string)
}