resource "aws_ssm_parameter" "service2_url" {
  name  = "${local.name_prefix}/SERVICE_2_URL"
  type  = "SecureString"
  value = "http://${aws_service_discovery_service.local["processor"].name}.${aws_service_discovery_private_dns_namespace.local.name}/createLetter/"
}

resource "aws_ssm_parameter" "llm_parameters" {
  for_each = var.llm_credentials
  name     = "${local.name_prefix}/${each.key}"
  type     = "SecureString"
  value    = each.value
}