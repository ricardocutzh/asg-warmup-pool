output "output" {
  value = {
    # launch_configuration = aws_launch_configuration.launch_config
    autoscaling_group    = aws_autoscaling_group.asg
  }
}