output "jumphost_ip" {
  value       = docker_container.jumphost.network_data[0].ip_address
  description = "The private IP address of the Jumphost."
}

output "vault_root_token" {
  value       = var.vault_root_token
  description = "Vault root token."
}
