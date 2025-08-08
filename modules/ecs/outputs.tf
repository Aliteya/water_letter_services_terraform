output "ecs_tasks_sg_id" {
  value = aws_security_group.ecs_tasks.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main_cluster.name
}