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

data "aws_iam_policy_document" "assume-role-policy" {
  for_each = var.match_value
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringLike"
      variable = "${var.github_url}:${var.match_field}"
      values   = [each.value]
    }
  }
}

resource "aws_iam_policy" "ecs_policy" {
  name = "github-ci-ecr-push-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        "Action" : ["ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability", "ecr:CompleteLayerUpload", "ecr:InitiateLayerUpload", "ecr:PutImage", "ecr:UploadLayerPart"]
        "Effect" : "Allow"
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_role" "github_ci" {
  for_each           = var.match_value
  name               = "githubci-role-${each.key}"
  assume_role_policy = data.aws_iam_policy_document.assume-role-policy[each.key].json
}

resource "aws_iam_role_policy_attachment" "ecs_acceses" {
  for_each   = aws_iam_role.github_ci
  role       = each.value.name
  policy_arn = aws_iam_policy.ecs_policy.arn
}