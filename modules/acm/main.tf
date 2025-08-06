terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
  }
  required_version = "~> 1.12.1"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = var.validation_method

  lifecycle {
    create_before_destroy = true
  }
}


data "cloudflare_zones" "letter_domain" {
  account = {
    id = var.account_id
  }
  name = var.domain_name
}

resource "cloudflare_dns_record" "verification_record" {
  zone_id = data.cloudflare_zones.letter_domain.result[0].id
  ttl     = 3600
  type    = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_type
  name    = trimsuffix(tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name, ".${var.domain_name}")
  comment = "Domain Verification record"
  content = tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_value
  proxied = false
}

resource "aws_acm_certificate_validation" "letter" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [tolist(aws_acm_certificate.cert.domain_validation_options)[0].resource_record_name]
}
