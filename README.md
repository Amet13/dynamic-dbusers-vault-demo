# Managing dynamic DB users with Vault (Demo)

[![Terraform checks](https://github.com/Amet13/dynamic-dbusers-vault-demo/actions/workflows/tf-checks.yml/badge.svg)](https://github.com/Amet13/dynamic-dbusers-vault-demo/actions/workflows/tf-checks.yml)

## Prerequisites

- Docker
- Terraform & Vault CLI tools:

```bash
brew install terraform vault
```

## Demo installation

1. Ensure that the Docker daemon is in running mode
2. Deploy this demo environment with Terraform:

```bash
cd docker/
terraform init
terraform apply

cd ../vault/
terraform init
terraform apply
...
Outputs:
jumphost_ip = "<jumphost_ip>" # This is a Jumphost IP to be used later
```

These modules deploy multiple containers:

- `vault` — Vault server
- `jumphost` — Jumphost for getting access to our DB containers
- `db*` — MySQL containers

Besides, it also deploys a necessary Vault configuration for Demo.

## Demo

After installation, we can log in to Vault with the root token by address: [`http://127.0.0.1:8200`](http://127.0.0.1:8200)

Log in to Vault CLI with token `root_token`:

```bash
export VAULT_ADDR=http://127.0.0.1:8200
vault login root_token
```

### Scenario 1. Developer's read-only access to db1

A developer wants to connect to `db1` with read-only permissions.

1. Create a token with `mysql-ro` policy and log in to the user:

```bash
vault token create -policy=mysql-ro | grep 'hvs' | awk '{print $2}'
hvs.CAESIOZ...

vault login hvs.CAESIOZ...
```

2. Generate credentials for MySQL access to `db1`:

```bash
vault read mysql/creds/db1-ro | grep "user\|pass"
password           zTZ0-...
username           demo-db1-ro-1684351412-d2h
```

3. Generate credentials for access to Jumphost for `developer` (use `<jumphost_ip>` generated from terraform output):

```bash
vault write ssh/creds/ssh-developer \
    username=developer \
    ip=172.20.0.2 | grep "key "
key                d113707e-8474-...
```

4. Log in to Jumphost:

```bash
ssh developer@localhost -p 2222
developer@localhost's password: d113707e-8474-...
developer@jumphost:~$ 
```

5. We are inside the Jumphost and we can connect to MySQL (`username` and `password` from step 2):

```bash
mysql -h db1 \
    -u demo-db1-ro-1684351412-d2h \
    -pzTZ0-...
mysql> SHOW GRANTS FOR CURRENT_USER;
+---------------------------------------------------------+
| Grants for demo-db1-ro-1684351412-d2h@%                 |
+---------------------------------------------------------+
| GRANT SELECT ON *.* TO `demo-db1-ro-1684351412-d2h`@`%` |
+---------------------------------------------------------+
```

As we can see, our dynamic user has only permissions for doing `SELECT` operations, which means read-only.

### Scenario 2. Admin's all privileges access to db2

The administrator wants to connect to `db2` with all permissions.

1. Let's switch back to the root token:

```bash
vault login root_token
```

2. Create a token with `mysql-rw` policy and log in to the user:

```bash
vault token create -policy=mysql-rw | grep 'hvs' | awk '{print $2}'
hvs.CAESIBGX...

vault login hvs.CAESIBGX...
```

3. Generate credentials for MySQL access to `db2`:

```bash
vault read mysql/creds/db2-rw | grep "user\|pass"
password           FnY9-...
username           demo-db2-rw-1684353122-S4X
```

4. Generate credentials for access to Jumphost for `admin` (use `<jumphost_ip>` generated from terraform output):

```bash
vault write ssh/creds/ssh-admin \
    username=admin \
    ip=172.20.0.2 | grep "key "
key                df4d48ad-8b61-...
```

5. Log in to Jumphost:

```bash
ssh admin@localhost -p 2222
developer@localhost's password: df4d48ad-8b61-...
admin@jumphost:~$ sudo -i # admin user can be promoted to root on Jumphost
root@jumphost:~# exit
```

6. We are inside the Jumphost and we can connect to MySQL (`username` and `password` from step 2):

```bash
mysql -h db2 \
    -u demo-db2-rw-1684353122-S4X \
    -pFnY9-...
mysql> SHOW GRANTS FOR CURRENT_USER;
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| Grants for demo-db2-rw-1684353122-S4X@%                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, RELOAD, SHUTDOWN, PROCESS, FILE, REFERENCES, INDEX, ALTER, SHOW DATABASES, SUPER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EVENT, TRIGGER, CREATE TABLESPACE, CREATE ROLE, DROP ROLE ON *.* TO `demo-db2-rw-1684353122-S4X`@`%`                                                                                                                                                                                                                                                                                                                                                                                     |
| GRANT APPLICATION_PASSWORD_ADMIN,AUDIT_ABORT_EXEMPT,AUDIT_ADMIN,AUTHENTICATION_POLICY_ADMIN,BACKUP_ADMIN,BINLOG_ADMIN,BINLOG_ENCRYPTION_ADMIN,CLONE_ADMIN,CONNECTION_ADMIN,ENCRYPTION_KEY_ADMIN,FIREWALL_EXEMPT,FLUSH_OPTIMIZER_COSTS,FLUSH_STATUS,FLUSH_TABLES,FLUSH_USER_RESOURCES,GROUP_REPLICATION_ADMIN,GROUP_REPLICATION_STREAM,INNODB_REDO_LOG_ARCHIVE,INNODB_REDO_LOG_ENABLE,PASSWORDLESS_USER_ADMIN,PERSIST_RO_VARIABLES_ADMIN,REPLICATION_APPLIER,REPLICATION_SLAVE_ADMIN,RESOURCE_GROUP_ADMIN,RESOURCE_GROUP_USER,ROLE_ADMIN,SENSITIVE_VARIABLES_OBSERVER,SERVICE_CONNECTION_ADMIN,SESSION_VARIABLES_ADMIN,SET_USER_ID,SHOW_ROUTINE,SYSTEM_USER,SYSTEM_VARIABLES_ADMIN,TABLE_ENCRYPTION_ADMIN,TELEMETRY_LOG_ADMIN,XA_RECOVER_ADMIN ON *.* TO `demo-db2-rw-1684353122-S4X`@`%` |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
```

As we can see, our dynamic user has all permissions, which means admin access.

## Cleanup

```bash
vault login root_token
vault lease revoke -force -prefix mysql/creds/
vault delete sys/mounts/mysql

cd vault/
terraform destroy

cd docker/
terraform destroy
```
