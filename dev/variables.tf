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

variable "github_url" {
  type    = string
  default = "token.actions.githubusercontent.com"
}

variable "aud_value" {
  type    = string
  default = "sts.amazonaws.com"
}

variable "match_field" {
  type    = string
  default = "sub"
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

variable "domain_name" {
  type = string
}

variable "validation_method" {
  type    = string
  default = "DNS"
}

variable "match_value_back" {
  type = map(string)
  default = {
    "publisher"  = "repo:Aliteya/publisher:ref:refs/heads/main",
    "processor"  = "repo:Aliteya/processor:ref:refs/heads/main",
    "subscriber" = "repo:Aliteya/subscriber:ref:refs/heads/main"
  }
}

variable "match_value_front" {
  type = map(string)
  default = {
    "frontend" = "repo:Aliteya/letter-frontend:ref:refs/heads/main"
  }
}

variable "services" {
  type        = list(string)
  description = "A list of service names"
  default     = ["processor", "publisher", "subscriber"]
}