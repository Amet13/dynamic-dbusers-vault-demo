# Managing dynamic DB users with Vault (Demo)

[![Terraform checks](https://github.com/Amet13/dynamic-dbusers-vault-demo/actions/workflows/tf-checks.yml/badge.svg)](https://github.com/Amet13/dynamic-dbusers-vault-demo/actions/workflows/tf-checks.yml)

## Prerequisites

- Docker
- Terraform & Vault CLI tools:

```bash
brew install terraform vault
```

## Installation

Ensure that the Docker daemon is in running mode and deploy this demo environment with Terraform:

```bash
terraform -chdir=docker init && \
    terraform -chdir=docker apply -auto-approve
terraform -chdir=vault init && \
    terraform -chdir=vault apply -auto-approve
```

This demo creates a Vault server, Jumphost, multiple MySQL instances and Vault configuration.

Getting Vault root token and Jumphost IP that will be used in the Demo:

```bash
JUMPHOST_IP=$(terraform -chdir=docker output -raw jumphost_ip)
VAULT_ROOT_TOKEN=$(terraform -chdir=docker output -raw vault_root_token)
```

## Demo

UI Vault is accessible by the link: [`http://127.0.0.1:8200`](http://127.0.0.1:8200/ui/)

Log in to Vault CLI with token `VAULT_ROOT_TOKEN`:

```bash
export VAULT_ADDR=http://127.0.0.1:8200
vault login $VAULT_ROOT_TOKEN
```

### Scenario 1. Developer's read-only access to db1

A developer wants to connect to `db1` with read-only permissions.

1. Create a token with `mysql-ro` policy and log in to the user:

```bash
MYSQL_RO_TOKEN=$(vault token create -policy=mysql-ro -field token)
vault login $MYSQL_RO_TOKEN
```

2. Generate credentials for MySQL access to `db1`:

```bash
vault read mysql/creds/db1-ro
# Remember the output for password and username, it's our dynamic MySQL user creds
```

3. Generate SSH OTP for Jumphost for `developer`:

```bash
JUMPHOST_SSH_OTP=$(vault write -field=key \
    ssh/creds/ssh-developer \
    username=developer \
    ip=$JUMPHOST_IP)
```

4. Log in to Jumphost:

```bash
echo $JUMPHOST_SSH_OTP
ssh developer@localhost -p 2222
developer@localhost's password: <paste_otp_from_previous_step_output>
developer@jumphost:~$ 
```

5. We are inside the Jumphost and can connect to MySQL (`username` and `password` from step 2):

```bash
mysql -h db1 \
    -u <username> \
    -p<password>
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
vault login $VAULT_ROOT_TOKEN
```

2. Create a token with `mysql-rw` policy and log in to the user:

```bash
MYSQL_RW_TOKEN=$(vault token create -policy=mysql-ro -field token)
vault login $MYSQL_RW_TOKEN
```

3. Generate credentials for MySQL access to `db2`:

```bash
vault read mysql/creds/db2-rw
# Remember the output for password and username, it's our dynamic MySQL user creds
```

4. Generate SSH OTP for Jumphost for `admin`:

```bash
JUMPHOST_SSH_OTP=$(vault write -field=key \
    ssh/creds/ssh-admin \
    username=admin \
    ip=$JUMPHOST_IP)
```

5. Log in to Jumphost:

```bash
echo $JUMPHOST_SSH_OTP
ssh admin@localhost -p 2222
developer@localhost's password: <paste_otp_from_previous_step_output>
admin@jumphost:~$ sudo -i # admin user can be promoted to root
root@jumphost:~# exit
```

6. We are inside the Jumphost and we can connect to MySQL (`username` and `password` from step 2):

```bash
mysql -h db2 \
    -u <username> \
    -p<password>
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

terraform -chdir=vault destroy -auto-approve && terraform -chdir=docker destroy -auto-approve
```
