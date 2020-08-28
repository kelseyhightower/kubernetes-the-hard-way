output "controller_nodes" {
  value = module.kubernetes.controller_private_ip
}

output "worker_nodes" {
  value = module.kubernetes.worker_private_ip
}
