output "output" {
  value = {
    alb_sg          = aws_security_group.alb.id
    service_asg     = aws_security_group.service.id
  }
}
