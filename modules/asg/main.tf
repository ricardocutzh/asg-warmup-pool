locals {
  default_tags = {
    Environment = terraform.workspace
    Name        = "${var.identifier}-${terraform.workspace}"
  }
  tags = merge(local.default_tags, var.tags)
}

resource "aws_launch_template" "launch_template" {
  ebs_optimized               = var.ebs_optimized
  instance_type               = var.instance_type
  user_data                   = var.user_data_base64
  key_name                    = var.key_name
  image_id                    = var.image_id
  name                        = "${var.identifier}-${terraform.workspace}-lt"

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    security_groups             = var.security_groups
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = var.volume_size
    }
  }

  tags = local.tags
}

resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier  = var.subnets
  desired_capacity     = var.min_size
  name                 = "${var.identifier}-${terraform.workspace}-sg"
  max_size             = var.max_size
  min_size             = var.min_size

  depends_on = [aws_launch_template.launch_template]

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances"
  ]

  launch_template {
    id      = aws_launch_template.launch_template.id
    version = aws_launch_template.launch_template.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 100
    }
    triggers = ["tags"]
  }

  dynamic "tag" {
    for_each = local.tags
    content {
      propagate_at_launch = true
      value               = tag.value
      key                 = tag.key
    }
  }
}