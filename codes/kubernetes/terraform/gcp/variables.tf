variable "environment" {
  description = "Name of this lab"
}

variable "address_prefix" {
  description = "Network CIDR"
}

variable "region" {
  description = "Region of this lab"
}

variable "zone" {
  description = "Zone of VM"
}

variable "internal_cidr" {
  description = "CIDR Allowed internal"
}

variable "external_cidr" {
  description = "CIDR Allowed external"
}

variable "vm_size" {
  description = "The machine type to create."
}

variable "boot_disk_type" {
  description = "The GCE disk type. Can be either pd-ssd, local-ssd, or pd-standard"
  default     = "pd-standard"
}

variable "boot_disk_size" {
  type        = number
  description = "The size of the image in gigabytes"
  default     = 200
}

variable "controller_count" {
  type        = number
  description = "Number of controller nodes"
  default     = 3
}

variable "worker_count" {
  type        = number
  description = "Number of worker nodes"
  default     = 3
}

variable "controller_ip_list" {
  type        = list(string)
  description = "list of controller ip"
}

variable "worker_ip_list" {
  type        = list(string)
  description = "list of worker ip"
}

variable "controller_scopes" {
  type        = list(string)
  description = "Scopes of controller Nodes"
  default     = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
}

variable "worker_scopes" {
  type        = list(string)
  description = "Scopes of Worker Nodes"
  default     = ["compute-rw", "storage-ro", "service-management", "service-control", "logging-write", "monitoring"]
}

variable "controller_node_tags" {
  type        = list(string)
  description = "A list of network tags to attach to the instance."
}

variable "worker_node_tags" {
  type        = list(string)
  description = "A list of network tags to attach to the instance."
}

variable "pod_address_prefix" {
  type        = list(string)
  description = "Pod Address Space prefix"
}
