variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "nat_instance_sg_id" {
  type = string
}

variable "llm_credentials" {
  type = map(string)
}

variable "repository_url" {
  type = map(string)
}
