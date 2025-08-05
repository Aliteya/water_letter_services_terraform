output "alb_sg_id" {
  value = aws_security_group.alb.id
}

output "target_group_arn" {
  value = aws_lb_target_group.target_ip_group.arn
}

output "alb_url" {
  value = aws_lb.apologize_alb.dns_name
}