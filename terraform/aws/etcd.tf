locals {
  service = "${var.prefix}-${var.name}-etcd"
}

module "asg" {
  count = "${var.etcd_member_count}"
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"

  name = "${local.service}-asg"

  # Launch configuration
  lc_name = "${local.service}-lc"

  image_id        = "ami-ebd02392" ## need to set a up data source for this.
  instance_type   = "t3.micro"
  security_groups = ["sg-12345678"] ## need to create this

  root_block_device = [
    {
      volume_size = "20"
      volume_type = "gp2"
    },
  ]

  # Auto scaling group
  asg_name                  = "${local.service}-asg"
  vpc_zone_identifier       = ["subnet-1235678", "subnet-87654321"]
  health_check_type         = "EC2"
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = "dev"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "megasecret"
      propagate_at_launch = true
    },
  ]

  tags_as_map = {
    extra_tag1 = "extra_value1"
    extra_tag2 = "extra_value2"
  }
}
