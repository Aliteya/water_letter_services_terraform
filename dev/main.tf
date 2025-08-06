locals {
  all_traffic   = "0.0.0.0/0"
  subdomen_name = "api"
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

# module "lambda" {
#   source             = "../modules/lambda"
#   region             = var.region
#   vpc_id             = module.vpc.vpc_id
#   private_subnet_ids = module.vpc.private_subnet_ids
#   sqs_arn            = module.sqs.sqs_arn
#   repository_url     = var.lambda_repository_url
# }

# module "database" {
#   source               = "../modules/database"
#   vpc_id               = module.vpc.vpc_id
#   nat_instance_sg_id   = module.bastion.nat_instance_sg_id
#   public_subnet_ids    = module.vpc.public_subnet_ids
#   private_subnet_ids   = module.vpc.private_subnet_ids
#   database_credentials = var.database_credentials
#   lambda_sg_id         = module.lambda.lambda_sg_id
# }

module "oidc_tokens" {
  source      = "../modules/oidc_tokens"
  github_url  = var.github_url
  aud_value   = var.aud_value
  match_field = var.match_field
  match_value = var.match_value
  iam_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Effect" : "Allow"
        "Action" : ["ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability", "ecr:CompleteLayerUpload", "ecr:InitiateLayerUpload", "ecr:PutImage", "ecr:UploadLayerPart"]
        "Resource" : "*"
      },
      {
        "Effect" : "Allow"
        "Action" : ["ecs:UpdateService"]
        "Resource" : "arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/demo-cluster/*"
      }
    ]
  })
}

module "acm" {
  source            = "../modules/acm"
  domain_name       = var.domain_name
  validation_method = var.validation_method
  account_id        = var.cloudflare_id
}

module "alb" {
  source            = "../modules/alb"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  certificate_arn   = module.acm.certificate_arn
}

resource "cloudflare_dns_record" "alb_record" {
  zone_id = module.acm.zone_id
  ttl     = 1
  name    = local.subdomen_name
  type    = "CNAME"
  comment = "General proxy record"
  content = module.alb.alb_url
  proxied = true
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
  sqs_arn            = module.sqs.sqs_arn
  target_group_arn   = module.alb.target_group_arn
  alb_sg_id          = module.alb.alb_sg_id
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
