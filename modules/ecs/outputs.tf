output "demo_apps_repo_urls" {
  value = { for k, repo in aws_ecr_repository.services : k => repo.repository_url }
}

output "ecs_tasks_sg_id" {
  value = aws_security_group.ecs_tasks.id
}