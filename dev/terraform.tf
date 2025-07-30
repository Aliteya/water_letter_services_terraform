terraform {
    required_providers {
      aws = {
        source = "hashicorp/aws"
        version = "~> 6.2.0"
      }
    }
    required_version = "~> 1.12.1"
}

provider "aws" {
    profile = var.profile
    region = var.region
    default_tags {
      tags = {
        Owner = "Alina Lukashevich"
        Env = var.env
      }
    }
}