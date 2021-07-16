resource "aws_network_acl" "public_layer" {
  count = length(var.vpc_settings["public_subnets"])

  subnet_ids = [local.public_subnets[count.index].id]
  vpc_id     = aws_vpc.vpc.id
  tags       = merge(local.tags, { Name = "${local.identifier}-public-nacl" })
}

resource "aws_network_acl" "data_layer" {
  count = length(var.vpc_settings["data_subnets"])

  subnet_ids = [local.data_subnets[count.index].id]
  vpc_id     = aws_vpc.vpc.id
  tags       = merge(local.tags, { Name = "${local.identifier}-data-nacl" })
}

resource "aws_network_acl" "application_layer" {
  count = length(var.vpc_settings["application_subnets"])

  subnet_ids = [local.application_subnets[count.index].id]
  vpc_id     = aws_vpc.vpc.id
  tags       = merge(local.tags, { Name = "${local.identifier}-application-nacl" })
}

### This allow all ephemeral ports on private subnets
resource "aws_network_acl_rule" "ingress-all-ephemmeral-tcp-data" {
  count = length(var.vpc_settings["data_subnets"])

  network_acl_id = aws_network_acl.data_layer[count.index].id
  rule_action    = "allow"
  rule_number    = 100
  cidr_block     = "0.0.0.0/0" #tfsec:ignore:AWS049
  from_port      = 1024
  protocol       = "tcp"
  to_port        = 65535
  egress         = false
}

resource "aws_network_acl_rule" "ingress-all-ephemmeral-tcp-app" {
  count = length(var.vpc_settings["application_subnets"])

  network_acl_id = aws_network_acl.application_layer[count.index].id
  rule_action    = "allow"
  rule_number    = 100
  cidr_block     = "0.0.0.0/0" #tfsec:ignore:AWS049
  from_port      = 1024
  protocol       = "tcp"
  to_port        = 65535
  egress         = false
}

resource "aws_network_acl_rule" "ingress-all-ephemmeral-udp-data" {
  count = length(var.vpc_settings["data_subnets"])

  network_acl_id = aws_network_acl.data_layer[count.index].id
  rule_action    = "allow"
  rule_number    = 101
  cidr_block     = "0.0.0.0/0" #tfsec:ignore:AWS049
  from_port      = 1024
  protocol       = "udp"
  to_port        = 65535
  egress         = false
}

resource "aws_network_acl_rule" "ingress-all-ephemmeral-udp-app" {
  count = length(var.vpc_settings["application_subnets"])

  network_acl_id = aws_network_acl.application_layer[count.index].id
  rule_action    = "allow"
  rule_number    = 101
  cidr_block     = "0.0.0.0/0" #tfsec:ignore:AWS049
  from_port      = 1024
  protocol       = "udp"
  to_port        = 65535
  egress         = false
}

### This allow all internal traffic
resource "aws_network_acl_rule" "ingress-all-internal-data" {
  count = length(var.vpc_settings["data_subnets"])

  network_acl_id = aws_network_acl.data_layer[count.index].id
  rule_action    = "allow"
  rule_number    = 1000
  cidr_block     = var.vpc_settings["cidr"]
  from_port      = 0
  protocol       = -1
  to_port        = 0
  egress         = false
}

### This allow all internal traffic
resource "aws_network_acl_rule" "ingress-all-internal-app" {
  count = length(var.vpc_settings["application_subnets"])

  network_acl_id = aws_network_acl.application_layer[count.index].id
  rule_action    = "allow"
  rule_number    = 1000
  cidr_block     = var.vpc_settings["cidr"]
  from_port      = 0
  protocol       = -1
  to_port        = 0
  egress         = false
}


### This allow all egress traffic
resource "aws_network_acl_rule" "egress-all-app" {
  count = length(var.vpc_settings["application_subnets"])

  network_acl_id = aws_network_acl.application_layer[count.index].id
  rule_action    = "allow"
  rule_number    = 1000
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  protocol       = -1
  to_port        = 0
  egress         = true
}

### This allow all egress traffic
resource "aws_network_acl_rule" "egress-all-data" {
  count = length(var.vpc_settings["data_subnets"])

  network_acl_id = aws_network_acl.data_layer[count.index].id
  rule_action    = "allow"
  rule_number    = 1000
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  protocol       = -1
  to_port        = 0
  egress         = true
}


### This allow all ephemeral ports ingress traffic to public subnets
resource "aws_network_acl_rule" "ingress-all-ephemmeral-tcp-public" {
  count = length(var.vpc_settings["public_subnets"])

  network_acl_id = aws_network_acl.public_layer[count.index].id
  rule_action    = "allow"
  rule_number    = 100
  cidr_block     = "0.0.0.0/0"
  from_port      = 1024
  protocol       = -1
  to_port        = 65535
  egress         = false
}

### This allow all egress traffic from public subnets
resource "aws_network_acl_rule" "egress-all-public" {
  count = length(var.vpc_settings["public_subnets"])

  network_acl_id = aws_network_acl.public_layer[count.index].id
  rule_action    = "allow"
  rule_number    = 1000
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  protocol       = -1
  to_port        = 0
  egress         = true
}