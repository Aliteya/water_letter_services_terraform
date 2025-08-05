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

variable "cloudflare_id" {
  type = string
}

variable "cloudflare_api_token" {
  type = string
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

variable "repository_url" {
  type = map(string)
}


variable "lambda_repository_url" {
  type = map(string)
}

variable "domain_name" {
  type = string
}

variable "validation_method" {
  type = string
}