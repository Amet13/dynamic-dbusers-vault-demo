module "docker" {
  source = "./modules/docker"

  databases        = var.databases
  vault_root_token = var.vault_root_token
}

# Uncomment this block before second `terraform apply`
# module "vault" {
#   source     = "./modules/vault"
#   depends_on = [module.docker]

#   databases = var.databases
# }
