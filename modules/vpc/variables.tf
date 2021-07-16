variable "vpc_settings" {
  description = "Map of AWS VPC settings"
  default = {
    application_subnets = ["172.20.16.0/22", "172.20.20.0/22"]
    public_subnets      = ["172.20.0.0/22", "172.20.4.0/22"]
    dns_hostnames       = true
    data_subnets        = ["172.20.8.0/22", "172.20.12.0/22"]
    dns_support         = true
    tenancy             = "default"
    cidr                = "172.20.0.0/16"
  }
  type = object({
    application_subnets = list(string)
    public_subnets      = list(string)
    data_subnets        = list(string)
    dns_hostnames       = bool,
    dns_support         = bool,
    tenancy             = string,
    cidr                = string
  })
}

variable "description" {
  description = "A description for the VPC"
  default     = "VPC created by terraform"
  type        = string
}

variable "identifier" {
  description = "Name of the VPC"
  type        = string
}

variable "region" {
  description = "Region where the VPC will be deployed"
  type        = string
}

variable "kubernetes_tagging" {
  description = "Set to true to enable kubernetes required tags for subnets"
  default     = false
  type        = bool
}

variable "tags" {
  description = "Tags to be applied to the resource"
  default     = {}
  type        = map
}

variable "multi_nat_gw" {
  description = "Set to true to create a nat gateway per availability zone, symmetrical subnets are required for best performance, try to avoid different subnet count between layers"
  default     = false
  type        = bool
}

variable "flow_log_settings" {
  description = "Map of VPC Flow Logs settings"
  default = {
    log_destination_type = "s3"
    enable_flow_log      = false
    traffic_type         = "ALL"
  }
  type = object({
    log_destination_type = string,
    enable_flow_log      = bool,
    traffic_type         = string,
  })
}

variable "s3_flow_log_bucket" {
  description = "S3 bucket where flow logs will be sent"
  default     = ""
  type        = string
}

variable "append_workspace" {
  description = "Appends the terraform workspace at the end of resource names, <identifier>-<worspace>"
  default     = true
  type        = bool
}