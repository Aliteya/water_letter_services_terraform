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

variable "gitlab_tls_url" {
  type = string
}

variable "gitlab_url" {
  type = string
}

variable "aud_value" {
  type = string
}

variable "match_field" {
  type    = string
  default = "aud"
}

variable "match_value" {
  type = list(any)
}