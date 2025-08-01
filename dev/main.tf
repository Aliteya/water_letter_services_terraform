locals {
  all_traffic = "0.0.0.0/0"
}

module "vpc" {
  source = "../modules/vpc"
}

module "bastion" {
  source             = "../modules/bastion"
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "sqs" {
  source = "../modules/sqs"
}

module "lambda" {
  source = "../modules/lambda"
  region             = var.region
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  sqs_arn = module.sqs.sqs_arn
  repository_url = var.lambda_repository_url
}

module "database" {
  source               = "../modules/database"
  vpc_id               = module.vpc.vpc_id
  nat_instance_sg_id   = module.bastion.nat_instance_sg_id
  public_subnet_ids    = module.vpc.public_subnet_ids
  private_subnet_ids   = module.vpc.private_subnet_ids
  database_credentials = var.database_credentials
  lambda_sg_id = module.lambda.lambda_sg_id
}

module "ecs" {
  source             = "../modules/ecs"
  region             = var.region
  vpc_id             = module.vpc.vpc_id
  llm_credentials    = var.llm_credentials
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  nat_instance_sg_id = module.bastion.nat_instance_sg_id
  repository_url     = var.repository_url
  sqs_arn = module.sqs.sqs_arn
}

resource "aws_route_table" "private_route_table" {
  vpc_id = module.vpc.vpc_id
  route {
    cidr_block           = local.all_traffic
    network_interface_id = module.bastion.network_interface_id
  }
}

resource "aws_route_table_association" "private_subnet_asso" {
  route_table_id = aws_route_table.private_route_table.id
  count          = length(module.vpc.private_subnet_ids)
  subnet_id      = module.vpc.private_subnet_ids[count.index]
}
