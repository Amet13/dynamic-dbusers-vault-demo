variable "databases" {
  type = map(object({
    username = string
    password = string
    host     = string
  }))
}
