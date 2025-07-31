output "ROLE_ARN" {
  description = "Role that needs to be assumed by Github CI. We will use this as a Github CI Variable."
  value       = { for key, role in aws_iam_role.github_ci : key => role.arn }
}