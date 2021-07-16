module "vpc" {
    source                  = "./modules/vpc"
    multi_nat_gw            = false
    vpc_settings            = {
        application_subnets = ["10.30.16.0/22", "10.30.20.0/22"]
        public_subnets      = ["10.30.0.0/22", "10.30.4.0/22"]
        dns_hostnames       = true
        data_subnets        = []
        dns_support         = true
        tenancy             = "default"
        cidr                = "10.30.0.0/16"
    }
    identifier              = var.identifier
    region                  = "us-west-2"
    tags                    = {
        Owner = "ricardo"
        env   = terraform.workspace
    }
}

module "security_group" {
    source                      = "./modules/securitygroups"
    identifier                  = var.identifier
    vpc                         = module.vpc.output.vpc.id
}

# module "asg" {
#     source                      = "./modules/asg"
#     identifier                  = var.identifier
#     associate_public_ip_address = false
#     iam_instance_profile        = null
#     user_data_base64            = ""
# }