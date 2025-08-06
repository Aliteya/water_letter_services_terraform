module "ecr" {
  source   = "../modules/ecr"
  services = var.services
}
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