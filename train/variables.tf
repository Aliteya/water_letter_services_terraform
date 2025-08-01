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

variable "profile" {
  type    = string
  default = "trainee"
}

variable "region" {
  type    = string
  default = "eu-north-1"
}

variable "env" {
  type    = string
  default = "dev"
}

variable "services" {
  type = map(any)
  description = "A map of service configurations"
}