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
}