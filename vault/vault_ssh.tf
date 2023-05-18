# SSH engine
resource "vault_mount" "ssh" {
  type = "ssh"
  path = "ssh"
}

# SSH roles
resource "vault_ssh_secret_backend_role" "developer" {
  name          = "ssh-developer"
  backend       = vault_mount.ssh.path
  key_type      = "otp"
  default_user  = "developer"
  allowed_users = "developer"
  cidr_list     = "0.0.0.0/0"

  depends_on = [
    vault_mount.ssh
  ]
}

resource "vault_ssh_secret_backend_role" "admin" {
  name          = "ssh-admin"
  backend       = vault_mount.ssh.path
  key_type      = "otp"
  default_user  = "admin"
  allowed_users = "admin"
  cidr_list     = "0.0.0.0/0"

  depends_on = [
    vault_mount.ssh
  ]
}
