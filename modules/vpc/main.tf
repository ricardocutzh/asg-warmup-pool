data "aws_availability_zones" "available" {}
locals {
  identifier = var.append_workspace ? "${var.identifier}-${terraform.workspace}" : var.identifier
  default_tags = {
    Environment = terraform.workspace
    Name        = local.identifier
  }
  kubernetes_public_tags = tomap({
    "kubernetes.io/cluster/${local.identifier}" = "shared",
    "kubernetes.io/role/elb"                    = 1
  })
  kubernetes_private_tags = tomap({
    "kubernetes.io/cluster/${local.identifier}" = "shared",
    "kubernetes.io/role/internal-elb"           = 1
  })

  tags = merge(local.default_tags, var.tags)

  ### Created Subnets from for_each loop, so we can reference them easily
  application_subnets = values(aws_subnet.application_subnets)
  route_table_list    = concat([aws_route_table.public.id], aws_route_table.data_subnets.*.id, aws_route_table.application.*.id)
  public_subnets      = values(aws_subnet.public_subnets)
  data_subnets        = values(aws_subnet.data_subnets)
  ### AZ count used for multi nat gw setups
  multi_nat = var.multi_nat_gw ? local.az_count : 1
  az_count  = length(var.vpc_settings["public_subnets"]) > length(data.aws_availability_zones.available.names) ? length(data.aws_availability_zones.available.names) : length(var.vpc_settings["public_subnets"])
}

resource "aws_vpc" "vpc" {
  enable_dns_hostnames = var.vpc_settings["dns_hostnames"]
  enable_dns_support   = var.vpc_settings["dns_support"]
  instance_tenancy     = var.vpc_settings["tenancy"]
  cidr_block           = var.vpc_settings["cidr"]
  tags                 = local.tags
}

resource "aws_subnet" "public_subnets" {
  for_each = toset(var.vpc_settings["public_subnets"])

  map_public_ip_on_launch = false
  availability_zone = element(
    data.aws_availability_zones.available.names,
    index(var.vpc_settings["public_subnets"], each.key) % length(data.aws_availability_zones.available.names),
  )
  cidr_block = each.key
  vpc_id     = aws_vpc.vpc.id

  tags = merge(local.tags, { Name = "${local.identifier}-public-${index(var.vpc_settings["public_subnets"], each.key)}" }, { Tier = "Public" },var.kubernetes_tagging ? local.kubernetes_public_tags : {})
}

resource "aws_subnet" "application_subnets" {
  for_each = toset(var.vpc_settings["application_subnets"])

  map_public_ip_on_launch = false
  availability_zone = element(
    data.aws_availability_zones.available.names,
    index(var.vpc_settings["application_subnets"], each.key) % length(data.aws_availability_zones.available.names),
  )
  cidr_block = each.key
  vpc_id     = aws_vpc.vpc.id

  tags = merge(local.tags, { Name = "${local.identifier}-application-${index(var.vpc_settings["application_subnets"], each.key)}" }, { Tier = "Application" },var.kubernetes_tagging ? local.kubernetes_private_tags : {})
}

resource "aws_subnet" "data_subnets" {
  for_each = toset(var.vpc_settings["data_subnets"])

  map_public_ip_on_launch = false
  availability_zone = element(
    data.aws_availability_zones.available.names,
    index(var.vpc_settings["data_subnets"], each.key) % length(data.aws_availability_zones.available.names),
  )
  cidr_block = each.key
  vpc_id     = aws_vpc.vpc.id

  tags = merge(local.tags, { Name = "${local.identifier}-data-${index(var.vpc_settings["data_subnets"], each.key)}" }, { Tier = "Data" },var.kubernetes_tagging ? local.kubernetes_private_tags : {})
}

resource "aws_db_subnet_group" "data_subnet_group" {
  count      = length(var.vpc_settings["data_subnets"]) > 0 ? 1 : 0
  subnet_ids = local.data_subnets.*.id
  name       = "${terraform.workspace}-data-subnet-group"

  tags = merge(local.tags, { Name = "${local.identifier}-data-${count.index}" }, var.kubernetes_tagging ? local.kubernetes_private_tags : {})
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = local.tags
}

resource "aws_eip" "nat_gw" {
  count = local.multi_nat
  tags  = local.tags
  vpc   = true

  depends_on = [aws_subnet.application_subnets, aws_subnet.data_subnets]
}

resource "aws_nat_gateway" "nat_gw" {
  count         = local.multi_nat
  allocation_id = aws_eip.nat_gw[count.index].id
  subnet_id     = local.public_subnets[count.index].id
  tags          = merge(local.tags, { Name = "${local.identifier}-nat-gw-${count.index}" })

  depends_on = [aws_subnet.application_subnets, aws_subnet.data_subnets, aws_subnet.public_subnets]
}

### Route Table definition

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.tags, { Name = "${local.identifier}-public" })
}

resource "aws_route_table" "application" {
  count  = length(var.vpc_settings["application_subnets"])
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.tags, { Name = "${local.identifier}-application-${count.index}" })
}

resource "aws_route_table" "data_subnets" {
  count  = length(var.vpc_settings["data_subnets"])
  vpc_id = aws_vpc.vpc.id
  tags   = merge(local.tags, { Name = "${local.identifier}-data-${count.index}" })
}

### Default Route definition per layer

resource "aws_route" "internet_gateway_route" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
  route_table_id         = aws_route_table.public.id
  depends_on             = [aws_route_table.public]
}

resource "aws_route" "application_nat_gateway_route" {
  count                  = length(var.vpc_settings["application_subnets"])
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw[count.index % local.multi_nat].id
  route_table_id         = aws_route_table.application[count.index].id
  depends_on             = [aws_route_table.application]
}

resource "aws_route" "data_nat_gateway_route" {
  count                  = length(var.vpc_settings["data_subnets"])
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gw[count.index % local.multi_nat].id
  route_table_id         = aws_route_table.data_subnets[count.index].id
  depends_on             = [aws_route_table.data_subnets]
}

### route table association

resource "aws_route_table_association" "application_subnets" {
  count          = length(var.vpc_settings["application_subnets"])
  route_table_id = aws_route_table.application[count.index].id
  subnet_id      = local.application_subnets[count.index].id
}

resource "aws_route_table_association" "data_subnets" {
  count          = length(var.vpc_settings["data_subnets"])
  route_table_id = aws_route_table.data_subnets[count.index].id
  subnet_id      = local.data_subnets[count.index].id
}

resource "aws_route_table_association" "public_subnet" {
  count          = length(var.vpc_settings["public_subnets"])
  route_table_id = aws_route_table.public.id
  subnet_id      = local.public_subnets[count.index].id
}

### VPC Endpoints definition

resource "aws_vpc_endpoint" "s3" {
  route_table_ids = local.route_table_list
  service_name    = "com.amazonaws.${var.region}.s3"
  vpc_id          = aws_vpc.vpc.id
  tags            = local.tags

  depends_on = [aws_subnet.application_subnets]
}

resource "aws_vpc_endpoint" "ecs" {
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  vpc_endpoint_type   = "Interface"
  service_name        = "com.amazonaws.${var.region}.ecs"
  subnet_ids          = local.application_subnets.*.id
  vpc_id              = aws_vpc.vpc.id
  tags                = local.tags

  depends_on = [aws_subnet.application_subnets]
}

data "aws_vpc_endpoint_service" "ssm" {
  service = "ssm"
}

resource "aws_vpc_endpoint" "ssm" {
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  vpc_endpoint_type   = "Interface"
  service_name        = data.aws_vpc_endpoint_service.ssm.service_name
  subnet_ids          = local.application_subnets.*.id
  vpc_id              = aws_vpc.vpc.id
  tags                = local.tags

  depends_on = [aws_subnet.application_subnets]
}

data "aws_vpc_endpoint_service" "ecr_api" {
  service = "ecr.api"
}

resource "aws_vpc_endpoint" "ecr_api" {
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  vpc_endpoint_type   = "Interface"
  service_name        = data.aws_vpc_endpoint_service.ecr_api.service_name
  subnet_ids          = local.application_subnets.*.id
  vpc_id              = aws_vpc.vpc.id
  tags                = local.tags

  depends_on = [aws_subnet.application_subnets]
}

data "aws_vpc_endpoint_service" "ecr_dkr" {
  service = "ecr.dkr"
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  private_dns_enabled = true
  vpc_endpoint_type   = "Interface"
  service_name        = data.aws_vpc_endpoint_service.ecr_dkr.service_name
  subnet_ids          = local.application_subnets.*.id
  vpc_id              = aws_vpc.vpc.id
  security_group_ids  = [aws_security_group.endpoint_sg.id]
  tags                = local.tags

  depends_on = [aws_subnet.application_subnets]
}

resource "aws_security_group" "endpoint_sg" {
  description = "endpoint sg security group"
  vpc_id      = aws_vpc.vpc.id
  name        = local.identifier

  ingress {
    cidr_blocks = [var.vpc_settings["cidr"]]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  egress {
    cidr_blocks = [var.vpc_settings["cidr"]]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  tags = local.tags
}

### VPC flow logs

resource "aws_flow_log" "logs" {
  count                = var.flow_log_settings["enable_flow_log"] ? 1 : 0
  log_destination      = var.s3_flow_log_bucket
  log_destination_type = var.flow_log_settings["log_destination_type"]
  traffic_type         = var.flow_log_settings["traffic_type"]
  vpc_id               = aws_vpc.vpc.id
}