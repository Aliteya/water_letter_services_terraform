output "demo_apps_repo_urls" {
  value = { for k, repo in aws_ecr_repository.services : k => repo.repository_url }
}

output "ecs_tasks_sg_id" {
  value = aws_security_group.ecs_tasks.id
}

output "ROLE_ARN" {
  description = "Role that needs to be assumed by GitLab CI. We will use this as a GitLab CI Variable."
  value       = aws_iam_role.gitlab_ci.arn
}