output "BASTION_PUBLIC_IP" {
  description = "Public IP of the bastion host to connect via SSH."
  value       = module.bastion.bastion_public_ip
}

output "SSH_COMMAND" {
  description = "Example SSH command to connect to the bastion."
  value       = "ssh ec2-user@${module.bastion.bastion_public_ip}"
}

output "DB_ENDPOINT" {
  description = "Endpoint of the private RDS database."
  value       = module.database.rds_endpoint
}

output "DB_USERNAME" {
  description = "Username for the RDS database."
  value       = module.database.rds_username
  sensitive   = true
}

output "DB_PASSWORD" {
  description = "Password for the RDS database. Use 'terraform output -raw DB_PASSWORD' to view."
  value       = module.database.rds_password
  sensitive   = true
}

output "AWS_DEFAULT_REGION" {
  value = var.region
}
