output "output" {
  value = {
    application_route_table = aws_route_table.application
    application_subnets     = local.application_subnets
    public_route_table      = aws_route_table.public
    data_subnet_group       = aws_db_subnet_group.data_subnet_group
    data_route_table        = aws_route_table.data_subnets
    internet_gateway        = aws_internet_gateway.igw
    nat_elastic_ip          = aws_eip.nat_gw
    public_subnets          = local.public_subnets
    data_subnets            = local.data_subnets
    nat_gateway             = aws_nat_gateway.nat_gw
    flow_logs               = var.flow_log_settings["enable_flow_log"] ? aws_flow_log.logs : null
    vpc                     = aws_vpc.vpc
  }
}