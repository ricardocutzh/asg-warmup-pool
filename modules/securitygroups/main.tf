locals {
  default_tags = {
    Environment = terraform.workspace
    Name        = "${var.identifier}-${terraform.workspace}"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "aws_security_group" "alb" {
  name        = "${var.identifier}-alb-${terraform.workspace}"
  description = "Allow TLS inbound traffic"
  vpc_id      = var.vpc
  tags        = local.tags
}

resource "aws_security_group_rule" "alb_ingress_rules" {

  count                    = length(var.alb_ingress_rule_list)
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = var.alb_ingress_rule_list[count.index].source_security_group_id
  cidr_blocks              = var.alb_ingress_rule_list[count.index].cidr_blocks
  description              = var.alb_ingress_rule_list[count.index].description
  from_port                = var.alb_ingress_rule_list[count.index].from_port
  protocol                 = var.alb_ingress_rule_list[count.index].protocol
  to_port                  = var.alb_ingress_rule_list[count.index].to_port
  type                     = "ingress"
}

resource "aws_security_group_rule" "alb_egress_rules" {
  count                    = length(var.alb_egress_rule_list)

  source_security_group_id = var.alb_egress_rule_list[count.index].source_security_group_id
  security_group_id        = aws_security_group.alb.id
  cidr_blocks              = var.alb_egress_rule_list[count.index].cidr_blocks
  description              = var.alb_egress_rule_list[count.index].description
  from_port                = var.alb_egress_rule_list[count.index].from_port
  protocol                 = var.alb_egress_rule_list[count.index].protocol
  to_port                  = var.alb_egress_rule_list[count.index].to_port
  type                     = "egress"
}

resource "aws_security_group" "service" {
  name        = "${var.identifier}-service-${terraform.workspace}"
  description = "Allow inbound traffic"
  vpc_id      = var.vpc
  tags        = local.tags
}

resource "aws_security_group_rule" "service_ingress_rules" {

  count                    = length(var.service_ingress_rule_list)
  security_group_id        = aws_security_group.service.id
  source_security_group_id = var.service_ingress_rule_list[count.index].source_security_group_id
  cidr_blocks              = var.service_ingress_rule_list[count.index].cidr_blocks
  description              = var.service_ingress_rule_list[count.index].description
  from_port                = var.service_ingress_rule_list[count.index].from_port
  protocol                 = var.service_ingress_rule_list[count.index].protocol
  to_port                  = var.service_ingress_rule_list[count.index].to_port
  type                     = "ingress"
}

resource "aws_security_group_rule" "service_egress_rules" {
  count                    = length(var.service_egress_rule_list)

  source_security_group_id = var.service_egress_rule_list[count.index].source_security_group_id
  security_group_id        = aws_security_group.service.id
  cidr_blocks              = var.service_egress_rule_list[count.index].cidr_blocks
  description              = var.service_egress_rule_list[count.index].description
  from_port                = var.service_egress_rule_list[count.index].from_port
  protocol                 = var.service_egress_rule_list[count.index].protocol
  to_port                  = var.service_egress_rule_list[count.index].to_port
  type                     = "egress"
}