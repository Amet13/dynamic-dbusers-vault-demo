# Dynamic DB users with Vault (DEMO)

## Prerequisites

- Docker
- Terraform & Vault CLI tools (`brew install terraform vault`)

## Installation

Ensure that the Docker daemon is in running mode.

Deploy demo env with terraform:

```bash
terraform init
terraform apply
```

This module deploys multiple containers:

- `vault` with Vault server
- `jumphost` that we can use to access our DB containers
- `db*` (depends on values in `terraform.tfvars`) MySQL containers

Go to `main.tf` and uncomment lines 9-14 (`vault` module block) and run apply again:

```bash
terraform apply
...
Outputs:
jumphost_ip = "<IP>" # This is a Jumphost IP to be used later
```

This module deploys Vault connections, policies, roles, etc.

## Demo

After installation, we can log in to Vault with the root token by address http://127.0.0.1:8200

Log in with (by default token is `root_token`):

```bash
export VAULT_ADDR=http://127.0.0.1:8200
vault login root_token
```

### Scenario 1. Developer's read-only access to db1

A developer wants to connect to `db1` with read-only permissions.

1. Create a token with `mysql-ro` policy and log in to the user:

```bash
vault token create -policy=mysql-ro | grep 'hvs' | awk '{print $2}'
hvs.CAESIOZwtgzKSBsN6plLQFgM-sc85OPvY-zLXRK6drnkDlNFGh4KHGh2cy5sUGloR1lWa25hVkpwbnk2NnMwYVBIZG0

vault login hvs.CAESIOZwtgzKSBsN6plLQFgM-sc85OPvY-zLXRK6drnkDlNFGh4KHGh2cy5sUGloR1lWa25hVkpwbnk2NnMwYVBIZG0
```

2. Generate credentials for MySQL access to `db1`:

```bash
vault read mysql/creds/db1-ro | grep "user\|pass"
password           zTZ0-RMnEgwLbj6OW9cx
username           demo-db1-ro-1684351412-d2h
```

3. Generate credentials for access to Jumphost for `developer` (use `<jumphost_ip>` generated from terraform output):

```bash
vault write ssh/creds/ssh-developer username=developer ip=172.20.0.2 | grep "key "
key                d113707e-8474-5243-6c54-41c754ce1f9f
```

4. Log in to Jumphost:

```bash
ssh developer@localhost -p 2222
developer@localhost's password: d113707e-8474-5243-6c54-41c754ce1f9f
developer@jumphost:~$ 
```

5. We are inside the Jumphost and we can connect to MySQL (`username` and `password` from step 2):

```bash
mysql -h db1 -u demo-db1-ro-1684351412-d2h -pzTZ0-RMnEgwLbj6OW9cx
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
hvs.CAESIBGXasnvE9nVNMcF3M_Qq1YB5WPzCmRvnmQJF9HKMWuPGh4KHGh2cy5TemRTQm5UVWhsVWFXQjIxc2dSRHJMbVE
...

vault login hvs.CAESIBGXasnvE9nVNMcF3M_Qq1YB5WPzCmRvnmQJF9HKMWuPGh4KHGh2cy5TemRTQm5UVWhsVWFXQjIxc2dSRHJMbVE
```

3. Generate credentials for MySQL access to `db2`:

```bash
vault read mysql/creds/db2-rw | grep "user\|pass"
password           F-nY92hxYW7hQjeQfm7Z
username           demo-db2-rw-1684353122-S4X
```

4. Generate credentials for access to Jumphost for `admin` (use `<jumphost_ip>` generated from terraform output):

```bash
vault write ssh/creds/ssh-admin username=admin ip=172.20.0.2 | grep "key "
key                df4d48ad-8b61-9172-6924-1d470b066537
```

5. Log in to Jumphost:

```bash
ssh admin@localhost -p 2222
developer@localhost's password: key                df4d48ad-8b61-9172-6924-1d470b066537
admin@jumphost:~$ sudo -i # admin user can impersonate root
root@jumphost:~# exit
```

6. We are inside the Jumphost and we can connect to MySQL (`username` and `password` from step 2):

```bash
mysql -h db2 -u demo-db2-rw-1684353122-S4X -pF-nY92hxYW7hQjeQfm7Z
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

terraform destroy
# comment vault module block in main.tf
```
