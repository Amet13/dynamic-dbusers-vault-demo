# Docker images
resource "docker_image" "vault" {
  name = var.docker_image_vault
}

resource "docker_image" "mysql" {
  name = var.docker_image_mysql
}

resource "docker_image" "ssh" {
  name = "vault-dbusers-demo-ssh:latest"
  build {
    context = "${path.module}/files/"
  }
  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset(path.module, "${path.module}/files/Dockerfile") : filesha1(f)]))
  }
}

# Docker network
resource "docker_network" "demo" {
  name = "dynamic-dbusers-vault-demo"
}

# Docker containers
resource "docker_container" "vault" {
  name         = "vault"
  image        = docker_image.vault.image_id
  hostname     = "vault"
  network_mode = docker_network.demo.name
  restart      = "unless-stopped"

  ports {
    internal = 8200
    external = 8200
  }

  env = [
    "VAULT_ADDR=http://0.0.0.0:8200",
    "VAULT_DEV_ROOT_TOKEN_ID=${var.vault_root_token}"
  ]

  capabilities {
    add = ["IPC_LOCK"]
  }
}

resource "docker_container" "databases" {
  for_each = var.databases

  name         = each.key
  image        = docker_image.mysql.image_id
  hostname     = each.key
  network_mode = docker_network.demo.name
  restart      = "unless-stopped"

  env = [
    "MYSQL_DATABASE=mysql",
    "MYSQL_ROOT_PASSWORD=${each.value.password}"
  ]

  capabilities {
    add = ["SYS_NICE"]
  }
}

resource "docker_container" "jumphost" {
  name         = "jumphost"
  image        = docker_image.ssh.image_id
  hostname     = "jumphost"
  network_mode = docker_network.demo.name
  restart      = "unless-stopped"

  ports {
    internal = 22
    external = 2222
  }
}
