output "ECS_ROLE_ARN" {
  value = module.oidc_tokens_backend.ROLE_ARN
}

output "S3_ROLE_ARN" {
  value = module.oidc_tokens_frontend.ROLE_ARN
}

output "S3_BUCKET_NAME" {
  value = module.s3.bucket_id
}

output "ECR_URL" {
  value = module.ecr.demo_apps_repo_urls
}

output "bucket_arn" {
  value = module.s3.bucket_arn
}

output "bucket_regional_domain_name" {
  value = module.s3.bucket_regional_domain_name
}