locals {
  service = "cp-${var.prefix}"
}

data "aws_subnet_ids" "private" {
  vpc_id = "${module.vpc.vpc_id}"
  tags = {
    Tier = "Private"
  }
}

data "aws_ami" "base" {
  owners           = ["self"]
  most_recent = true

  filter {
    name   = "tag:Name"
    values = ["jibakurei-amzn2-base"]
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 3.0"
  name = "${local.service}-leader-asg"

  # Launch configuration
  lc_name = "${local.service}-lc"

  image_id        = "${data.aws_ami.base.id}"
  instance_type   = "t3.micro"
  security_groups = ["sg-007aac50c4850d797"]

  root_block_device = [
    {
      volume_size = "8"
      volume_type = "gp2"
    },
  ]

  # Auto scaling group
  asg_name                  = "${local.service}-leader-asg"
  vpc_zone_identifier       = [join(",", data.aws_subnet_ids.private.ids)]
  health_check_type         = "EC2"
  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = "${local.environment}"
      propagate_at_launch = true
    },
    {
      key                 = "Name"
      value               = "${var.prefix}-${var.name}"
      propagate_at_launch = true
    },
  ]

  # tags_as_map = {
  #   extra_tag1 = "extra_value1"
  #   extra_tag2 = "extra_value2"
  # }
}
