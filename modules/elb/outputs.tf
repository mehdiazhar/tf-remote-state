
output "clb_dns" {
  value = aws_elb.internal_lb.dns_name
}

output "clb_sg" {
  value = aws_security_group.clb_sg.id
}

