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

variable "database_credentials" {
  type = map(string)
  default = {
    "DATABASE_USER" = "postgres"
    "DATABASE_NAME" = "postgres"
    "DATABASE_PORT" = "5432"
  }
}

variable "llm_credentials" {
  type = map(string)
}

variable "gitlab_url" {
  type = string
}

variable "aud_value" {
  type = string
}

variable "match_field" {
  type = string
}

variable "match_value" {
  type = list(any)
}