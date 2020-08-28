module "kubernetes" {
  source               = "./kubernetes/terraform/gcp"
  environment          = "kubernetes"
  region               = "us-west1"
  zone                 = "us-west1-b"
  address_prefix       = "10.240.0.0/24"
  internal_cidr        = ["10.240.0.0/24", "10.200.0.0/16"]
  external_cidr        = ["0.0.0.0/0"]
  vm_size              = "custom-1-8192-ext"
  controller_ip_list   = ["10.240.0.10", "10.240.0.11", "10.240.0.12"]
  controller_node_tags = ["kubernetes-the-hard-way", "controller"]
  worker_ip_list       = ["10.240.0.20", "10.240.0.21", "10.240.0.22"]
  worker_node_tags     = ["kubernetes-the-hard-way", "worker"]
  pod_address_prefix   = ["10.200.0.0/24", "10.200.1.0/24", "10.200.2.0/24"]
}
