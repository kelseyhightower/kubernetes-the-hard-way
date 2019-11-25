locals {
  environment = "${terraform.workspace == "default" ? "dev" : terraform.workspace}"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.prefix}-${var.name}"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  single_nat_gateway  = true

  tags = {
    Name = "${var.prefix}-${var.name}"
    Terraform = "true"
    Environment = "${local.environment}"
  }

  private_subnet_tags = {
    Name = "private-${var.prefix}-${var.name}"
    Terraform = "true"
    Environment = "${local.environment}"
    Tier = "Private"
  }

  public_subnet_tags = {
    Name = "public-${var.prefix}-${var.name}"
    Terraform = "true"
    Environment = "${local.environment}"
    Tier = "Public"
  }

}
