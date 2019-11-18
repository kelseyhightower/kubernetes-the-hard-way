provider "aws" {
  version                 = "~> 2.0"
  region                  = "us-west-2"
  access_key = "${var.aws_access_key}"
  secret_key = "${var.aws_secret_key}"
}

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "jibakurei"

    workspaces {
      prefix = "kthw-"
    }
  }
}
