# MySQL User Creation and Permissions

## Single Database Permissions

### Read-only access:

```sql
CREATE USER 'read_only_user'@'localhost' IDENTIFIED BY 'password';
GRANT SELECT ON database1.* TO 'read_only_user'@'localhost';
FLUSH PRIVILEGES;
```
### Read and Write access:

```sql
CREATE USER 'read_write_delete_user'@'localhost' IDENTIFIED BY 'password';
GRANT SELECT, INSERT, UPDATE, DELETE ON database1.* TO 'read_write_delete_user'@'localhost';
FLUSH PRIVILEGES;
```
## More than one database

### Read-only access:

```sql
CREATE USER 'multi_db_user'@'localhost' IDENTIFIED BY 'password';
GRANT SELECT ON database1.* TO 'multi_db_user'@'localhost';
GRANT SELECT ON database2.* TO 'multi_db_user'@'localhost';
FLUSH PRIVILEGES;
```
### Read and Write access:

```sql
GRANT SELECT, INSERT, UPDATE, DELETE ON database1.* TO 'multi_db_user'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON database2.* TO 'multi_db_user'@'localhost';
GRANT SELECT, INSERT, UPDATE, DELETE ON database3.* TO 'multi_db_user'@'localhost';
```



