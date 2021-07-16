locals {
  default_tags = {
    Environment = terraform.workspace
    Name        = "${var.identifier}-${terraform.workspace}"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "aws_lb" "main" {
  security_groups = var.security_groups
  internal        = var.lb_is_internal #tfsec:ignore:AWS005
  subnets         = var.subnet_ids
  name            = "${var.identifier}-${terraform.workspace}"

  tags = local.tags
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.main.id
  protocol          = "HTTP"
  port              = "80"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

}

resource "aws_lb_target_group" "tg" {
  name     = "${var.identifier}-${terraform.workspace}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}