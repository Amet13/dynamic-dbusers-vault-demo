# Audit log
resource "vault_audit" "log" {
  type = "file"

  options = {
    file_path = "/tmp/vault-audit.log"
  }
}


# DB engine
resource "vault_mount" "mysql" {
  path = "mysql"
  type = "database"
}

# Roles
resource "vault_database_secret_backend_role" "ro" {
  for_each = var.databases

  backend             = vault_mount.mysql.path
  name                = "${each.key}-ro"
  db_name             = each.key
  creation_statements = ["CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}'; GRANT SELECT ON *.* TO '{{name}}'@'%';"]

  depends_on = [
    vault_mount.mysql
  ]
}

resource "vault_database_secret_backend_role" "rw" {
  for_each = var.databases

  backend             = vault_mount.mysql.path
  name                = "${each.key}-rw"
  db_name             = each.key
  creation_statements = ["CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}'; GRANT ALL PRIVILEGES ON *.* TO '{{name}}'@'%';"]

  depends_on = [
    vault_database_secret_backend_connection.databases
  ]
}

# Connections
resource "vault_database_secret_backend_connection" "databases" {
  for_each = var.databases

  name          = each.key
  backend       = vault_mount.mysql.path
  allowed_roles = ["${each.key}-ro", "${each.key}-rw"]

  mysql {
    username       = each.value.username
    password       = each.value.password
    connection_url = "{{username}}:{{password}}@tcp(${each.value.host}:3306)/"

    username_template = "demo-{{.RoleName}}-{{unix_time}}-{{random 3}}"
  }

  depends_on = [
    vault_mount.mysql
  ]
}

# Policies
resource "vault_policy" "ro" {
  name = "${vault_mount.mysql.path}-ro"
  policy = templatefile("${path.module}/files/policy.tpl", {
    databases   = var.databases,
    path        = vault_mount.mysql.path,
    permissions = "ro"
  })
}

resource "vault_policy" "rw" {
  name = "${vault_mount.mysql.path}-rw"
  policy = templatefile("${path.module}/files/policy.tpl", {
    databases   = var.databases,
    path        = vault_mount.mysql.path,
    permissions = "rw"
  })
}
