locals {
  all_traffic    = "0.0.0.0/0"
  instance_class = "db.t3.micro"
  name_prefix    = "/database"
  engine         = "postgres"
  engine_version = "17.5"
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_ssm_parameter" "db_password_ssm" {
  name  = "/database/DATABASE_PASSWORD"
  type  = "SecureString"
  value = random_password.db_password.result
}

resource "aws_db_subnet_group" "apologize_subnet" {
  name       = "log-subnet"
  subnet_ids = var.private_subnet_ids
  tags = {
    Name = "Apologize DB subnet group"
  }
}

resource "aws_ssm_parameter" "database_credentials" {
  for_each = var.database_credentials
  name     = "${local.name_prefix}/${each.key}"
  type     = "SecureString"
  value    = each.value
  lifecycle {
    ignore_changes = [
      value,
    ]
  }
}

resource "aws_security_group" "allow_postgres_traffic" {
  vpc_id = var.vpc_id
  ingress {
    description = "Allow Postgres"
    from_port   = tonumber(var.database_credentials["DATABASE_PORT"])
    to_port     = tonumber(var.database_credentials["DATABASE_PORT"])
    protocol    = "tcp"
    # ПОТОМ ПОМЕНЯТЬ ФИЛЬТРАЦИЮ ПО CIDR НА ФИЛЬТРАЦИЮ ПО SG ECS
    # cidr_blocks = var.private_subnet_cidrs
    security_groups = [var.ecs_tasks_sg_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.all_traffic]
  }
  tags = {
    Name = "Allow Postgres"
  }
}

resource "aws_db_instance" "log_db" {
  allocated_storage      = 10
  identifier             = "postgres-test2"
  db_name                = var.database_credentials["DATABASE_NAME"]
  db_subnet_group_name   = aws_db_subnet_group.apologize_subnet.name
  instance_class         = local.instance_class
  engine                 = local.engine
  engine_version         = local.engine_version
  username               = var.database_credentials["DATABASE_USER"]
  password               = aws_ssm_parameter.db_password_ssm.value
  vpc_security_group_ids = [aws_security_group.allow_postgres_traffic.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
}

resource "aws_ssm_parameter" "endpoint_parameter" {
  name  = "${local.name_prefix}/endpoint"
  type  = "String"
  value = aws_db_instance.log_db.address
}