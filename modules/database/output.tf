output "rds_endpoint" {
  description = "The endpoint of the RDS instance."
  value       = aws_db_instance.log_db.address
}

output "rds_password" {
  description = "The password for the RDS instance."
  value       = aws_db_instance.log_db.password
  sensitive   = true
}

output "rds_port" {
  description = "The port of the RDS instance."
  value       = aws_db_instance.log_db.port
}

output "rds_name" {
  description = "The username for the RDS instance."
  value       = aws_db_instance.log_db.db_name
  sensitive   = true
}

output "rds_username" {
  description = "The username for the RDS instance."
  value       = aws_db_instance.log_db.username
  sensitive   = true
}