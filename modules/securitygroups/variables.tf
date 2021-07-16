variable "vpc" {}

variable "identifier" {
  description = "Name of the VPC"
  type        = string
}

variable "alb_ingress_rule_list" {
  description = "List of security group ingress rules"
  default     = [
    {
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"]
      description              = "All Web Traffic (443)"
      from_port                = 443
      protocol                 = "tcp"
      to_port                  = 443
    },
    {
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"]
      description              = "All Web Traffic (80)"
      from_port                = 80
      protocol                 = "tcp"
      to_port                  = 80
    }
  ]
  type = list(object({
    source_security_group_id = string
    cidr_blocks              = list(string),
    description              = string,
    from_port                = number,
    protocol                 = string,
    to_port                  = number
  }))
}

variable "alb_egress_rule_list" {
  description = "List of security group egress rules"
  default = [
    {
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"],
      description              = "Default egress rule",
      from_port                = 0,
      protocol                 = "all",
      to_port                  = 65535
    }
  ]
  type = list(object({
    source_security_group_id = string
    cidr_blocks              = list(string),
    description              = string,
    from_port                = number,
    protocol                 = string,
    to_port                  = number
  }))
}

variable "service_ingress_rule_list" {
  description = "List of security group ingress rules"
  default     = [
    {
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"]
      description              = "All Web Traffic (8080)"
      from_port                = 8080
      protocol                 = "tcp"
      to_port                  = 8080
    },
    {
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"]
      description              = "All Web Traffic (8080)"
      from_port                = 22
      protocol                 = "tcp"
      to_port                  = 22
    }
  ]
  type = list(object({
    source_security_group_id = string
    cidr_blocks              = list(string),
    description              = string,
    from_port                = number,
    protocol                 = string,
    to_port                  = number
  }))
}

variable "service_egress_rule_list" {
  description = "List of security group egress rules"
  default = [
    {
      source_security_group_id = null
      cidr_blocks              = ["0.0.0.0/0"],
      description              = "Default egress rule",
      from_port                = 0,
      protocol                 = "all",
      to_port                  = 65535
    }
  ]
  type = list(object({
    source_security_group_id = string
    cidr_blocks              = list(string),
    description              = string,
    from_port                = number,
    protocol                 = string,
    to_port                  = number
  }))
}

variable "tags" {
  description = "Tags to be applied to the resource"
  default     = {}
  type        = map
}