variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "github_url" {
  type = string
}

variable "aud_value" {
  type = string
}

variable "match_field" {
  type = string
}

variable "match_value" {
  type = map(string)
}

variable "iam_policy_json" {
  type = string
}

variable "openid_connect_provider_arn" {
  type = string
}