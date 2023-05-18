variable "databases" {
  type = map(object({
    username = string
    password = string
    host     = string
  }))
}

variable "vault_root_token" {
  type = string
}

variable "docker_image_vault" {
  type    = string
  default = "vault:1.13.2"
}

variable "docker_image_mysql" {
  type    = string
  default = "mysql:8.0.33"
}
