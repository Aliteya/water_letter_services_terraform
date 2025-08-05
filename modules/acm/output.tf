output "certificate_arn" {
  value =  aws_acm_certificate_validation.letter.certificate_arn
}

output "zone_id" {
  value = data.cloudflare_zones.letter_domain.result[0].id
}