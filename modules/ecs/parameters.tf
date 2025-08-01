resource "aws_ssm_parameter" "service2_url" {
  name  = "${local.name_prefix}/SERVICE_2_URL"
  type  = "SecureString"
  value = "temp_url"
}

resource "aws_ssm_parameter" "llm_parameters" {
  for_each = var.llm_credentials
  name     = "${local.name_prefix}/${each.key}"
  type     = "SecureString"
  value    = each.value
}