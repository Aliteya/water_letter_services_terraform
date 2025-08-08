output "CLOUDFRONT_DISTRIBUTION_ID" {
  value = aws_cloudfront_distribution.this.id
}

output "cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.this.arn
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}