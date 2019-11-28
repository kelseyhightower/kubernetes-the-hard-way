## MAIN Variables

variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "name" {
  type        = string
  description = "The name that will be tagged on all the AWS resources"
  default     = "k8s"
}

variable "prefix" {
  type        = string
  description = "The prefix to add the name"
  default     = "jibakurei"
}

variable "etcd_member_count" {
  type        = string
  description = "The number of etcd instances in the cluster"
  default     = "1"
}
