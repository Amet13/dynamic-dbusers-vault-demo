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
