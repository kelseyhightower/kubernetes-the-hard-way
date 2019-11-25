data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${var.prefix}-${var.name}"]
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

# module "asg" {
#   source  = "terraform-aws-modules/autoscaling/aws"
#   version = "~> 3.0"
#   name = "cp-leader"

#   # Launch configuration
#   lc_name = "example-lc"

#   image_id        = "ami-ebd02392"
#   instance_type   = "t2.micro"
#   security_groups = ["sg-12345678"]

#   root_block_device = [
#     {
#       volume_size = "8"
#       volume_type = "gp2"
#     },
#   ]

#   # Auto scaling group
#   asg_name                  = "example-asg"
#   vpc_zone_identifier       = ["subnet-1235678", "subnet-87654321"]
#   health_check_type         = "EC2"
#   min_size                  = 1
#   max_size                  = 1
#   desired_capacity          = 1
#   wait_for_capacity_timeout = 0

#   tags = [
#     {
#       key                 = "Environment"
#       value               = "dev"
#       propagate_at_launch = true
#     },
#     {
#       key                 = "Project"
#       value               = "megasecret"
#       propagate_at_launch = true
#     },
#   ]

#   tags_as_map = {
#     extra_tag1 = "extra_value1"
#     extra_tag2 = "extra_value2"
#   }
# }
