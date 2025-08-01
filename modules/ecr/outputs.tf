output "demo_apps_repo_urls" {
  value = { for k, repo in aws_ecr_repository.services : k => repo.repository_url }
}
