
# output "alb_tg" {
#   value = aws_alb_target_group.alb_tg
# }

# output "alb_sg" {
#   value = aws_security_group.alb_sg.id
# }

locals {
  alb_output = {
    alb_arn = aws_alb.alb.arn
    alb_tg  = aws_alb_target_group.alb_tg.arn
    alb_sg  = aws_security_group.alb_sg.id
  }
}

output "alb_out" {
  value = local.alb_output
}
