terraform {
  backend "s3" {
    bucket = "aliteya-letter-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "eu-north-1"
    # profile = "trainee"
    encrypt        = true
    lock_table {
        name = "terraform-lock"
    }
  }
}