terraform {
  backend "s3" {
    bucket = "aliteya-letter-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "eu-north-1"
    # profile = "trainee"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}