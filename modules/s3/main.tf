resource "random_pet" "bucket_suffix" {
  length = 2
}

resource "aws_s3_bucket" "this" {
  bucket        = "aliteya-frontend-${random_pet.bucket_suffix.id}"
  force_destroy = true
}