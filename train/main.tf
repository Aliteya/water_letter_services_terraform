data "aws_caller_identity" "current" {}

module "ecr" {
  source   = "../modules/ecr"
  services = var.services
}

data "tls_certificate" "github" {
  url = "tls://${var.github_url}:443"
}

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://${var.github_url}"
  client_id_list = [var.aud_value]
  thumbprint_list = [
    data.tls_certificate.github.certificates[length(data.tls_certificate.github.certificates) - 1].sha1_fingerprint
  ]
}

module "oidc_tokens_backend" {
  source      = "../modules/oidc_tokens"
  github_url  = var.github_url
  aud_value   = var.aud_value
  match_field = var.match_field
  match_value = var.match_value_back
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
  openid_connect_provider_arn = aws_iam_openid_connect_provider.github.arn
}

module "s3" {
  source  = "../modules/s3"
}

module "oidc_tokens_frontend" {
  source      = "../modules/oidc_tokens"
  github_url  = var.github_url
  aud_value   = var.aud_value
  match_field = var.match_field
  match_value = var.match_value_front
  iam_policy_json = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "ListBucket",
        "Effect" : "Allow",
        "Action" : "s3:ListBucket",
        "Resource" : "arn:aws:s3:::${module.s3.bucket_id}"
      },
      {
        "Sid" : "WriteAndReadObjects",
        "Effect" : "Allow",
        "Action" : [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ],
        "Resource" : "arn:aws:s3:::${module.s3.bucket_id}/*"
      }
    ]
  })
  openid_connect_provider_arn = aws_iam_openid_connect_provider.github.arn
}