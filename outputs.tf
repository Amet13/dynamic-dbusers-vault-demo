output "jumphost_ip" {
  value       = module.docker.jumphost_ip
  description = "The private IP address of the Jumphost."
}
