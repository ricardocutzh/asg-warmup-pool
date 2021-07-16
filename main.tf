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

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "${var.identifier}-${terraform.workspace}-files"
  acl    = "private"
}

data "archive_file" "app" {
  type        = "zip"
  source_dir  = "./docker"
  output_path = "./docker/zip/app.zip"
}

resource "aws_s3_bucket_object" "app_zip" {
  key        = "app.zip"
  bucket     = aws_s3_bucket.s3_bucket.id
  source     = "./docker/zip/app.zip"
}

data "template_file" "user_data" {
  template = file("templates/user_data.tmpl")
  vars = {
    bucket_name = aws_s3_bucket.s3_bucket.id
  }
}

module "alb" {
    source                      = "./modules/alb"
    identifier                  = var.identifier
    lb_is_internal              = false
    vpc_id                      = module.vpc.output.vpc.id
    security_groups             = [module.security_group.output.alb_sg]
    subnet_ids                  = module.vpc.output.public_subnets.*.id

}

module "asg" {
    source                      = "./modules/asg"
    identifier                  = var.identifier
    associate_public_ip_address = false
    iam_instance_profile        = aws_iam_instance_profile.ssh_profile.arn
    user_data_base64            = base64encode(data.template_file.user_data.rendered)
    security_groups             = [module.security_group.output.service_asg]
    image_id                    = "ami-03d5c68bab01f3496"
    key_name                    = "ricardokey"
    volume_size                 = 30
    subnets                     = module.vpc.output.application_subnets.*.id
    min_size                    = var.min_size
    max_size                    = var.max_size
    target_group_arn            = module.alb.output.tg
    pool_min_size               = var.warm_pool_min_size
    max_group_prepared_capacity = var.warm_pool_max_size
    pool_state                  = var.warm_pool_state
}