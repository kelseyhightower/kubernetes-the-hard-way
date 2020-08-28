output "controller_private_ip" {
  value = google_compute_instance.controller.*.network_interface.0.network_ip
}

output "worker_private_ip" {
  value = google_compute_instance.worker.*.network_interface.0.network_ip
}
