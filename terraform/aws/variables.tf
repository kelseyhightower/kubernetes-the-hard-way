## MAIN Variables

variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "name" {
  type        = string
  description = "The name that will be tagged on all the AWS resources"
  default     = "tfcloud"
}

variable "prefix" {
  type        = string
  description = "The prefix to add the name"
  default     = "jibakurei"
}

variable "prefix" {
  type        = string
  description = "The prefix to add the name"
  default     = "jibakurei"
}
