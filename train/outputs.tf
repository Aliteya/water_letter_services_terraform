output "ECS_ROLE_ARN" {
  value = module.oidc_tokens.ROLE_ARN
}

output "ECR_URL" {
  value = module.ecr.demo_apps_repo_urls
}