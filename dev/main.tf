locals {
  all_traffic   = "0.0.0.0/0"
  subdomen_name = "api"
}

data "aws_caller_identity" "current" {}

module "ecr" {
  source   = "../modules/ecr"
  services = var.services
}

data "tls_certificate" "github" {
  url = "tls://${var.github_url}:443"
}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}
# resource "aws_iam_openid_connect_provider" "github" {
#   url            = "https://${var.github_url}"
#   client_id_list = [var.aud_value]
#   thumbprint_list = [
#     data.tls_certificate.github.certificates[length(data.tls_certificate.github.certificates) - 1].sha1_fingerprint
#   ]
# }

data "aws_iam_policy_document" "github_backend_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ecs:UpdateService"
    ]
    resources = ["arn:aws:ecs:${var.region}:${data.aws_caller_identity.current.account_id}:service/${module.ecs.ecs_cluster_name}/*"]
  }
}

module "oidc_tokens_backend" {
  source                      = "../modules/oidc_tokens"
  github_url                  = var.github_url
  aud_value                   = var.aud_value
  match_field                 = var.match_field
  match_value                 = var.match_value_back
  iam_policy_json             = data.aws_iam_policy_document.github_backend_policy_doc.json
  openid_connect_provider_arn = data.aws_iam_openid_connect_provider.github.arn
}

module "s3" {
  source = "../modules/s3"
}

data "aws_iam_policy_document" "github_frontend_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [module.s3.bucket_arn]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject"
    ]
    resources = ["${module.s3.bucket_arn}/*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation"
    ]
    resources = [module.cloudfront.cloudfront_distribution_arn]
  }
}

module "oidc_tokens_frontend" {
  source                      = "../modules/oidc_tokens"
  github_url                  = var.github_url
  aud_value                   = var.aud_value
  match_field                 = var.match_field
  match_value                 = var.match_value_front
  iam_policy_json             = data.aws_iam_policy_document.github_frontend_policy_doc.json
  openid_connect_provider_arn = data.aws_iam_openid_connect_provider.github.arn
}

module "vpc" {
  source = "../modules/vpc"
}

module "bastion" {
  source            = "../modules/bastion"
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
}

module "sqs" {
  source = "../modules/sqs"
}

module "lambda" {
  source             = "../modules/lambda"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  sqs_arn            = module.sqs.sqs_arn
  repository_url     = { "subscriber" : module.ecr.demo_apps_repo_urls["subscriber"] }
}

module "database" {
  source               = "../modules/database"
  vpc_id               = module.vpc.vpc_id
  nat_instance_sg_id   = module.bastion.nat_instance_sg_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  database_credentials = var.database_credentials
  lambda_sg_id         = module.lambda.lambda_sg_id
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
  vpc_id             = module.vpc.vpc_id
  llm_credentials    = var.llm_credentials
  private_subnet_ids = module.vpc.private_subnet_ids
  nat_instance_sg_id = module.bastion.nat_instance_sg_id
  repository_url     = { "processor" : module.ecr.demo_apps_repo_urls["processor"], "publisher" = module.ecr.demo_apps_repo_urls["publisher"] }
  sqs_arn            = module.sqs.sqs_arn
  target_group_arn   = module.alb.target_group_arn
  alb_sg_id          = module.alb.alb_sg_id
}

module "cloudfront" {
  source                      = "../modules/cloudfront"
  bucket_id                   = module.s3.bucket_id
  bucket_arn                  = module.s3.bucket_arn
  bucket_regional_domain_name = module.s3.bucket_regional_domain_name
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
