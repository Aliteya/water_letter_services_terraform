resource "aws_ecr_repository" "services" {
  for_each             = var.services
  name                 = "demo-${each.key}"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }
}
