# Linux 常见报错解决办法

## SSH 权限高导致无法登录问题

### 报错信息

```shell
Starting sshd: @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0644 for '/etc/ssh/ssh_host_rsa_key' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
Error loading host key "/etc/ssh/ssh_host_rsa_key": bad permissions
Could not load host key: /etc/ssh/ssh_host_rsa_key

Permissions 0644 for '/etc/ssh/ssh_host_ecdsa_key' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
Error loading host key "/etc/ssh/ssh_host_ecdsa_key": bad permissions
Could not load host key: /etc/ssh/ssh_host_ecdsa_key

Permissions 0644 for '/etc/ssh/ssh_host_ed25519_key' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
Error loading host key "/etc/ssh/ssh_host_ed25519_key": bad permissions
Could not load host key: /etc/ssh/ssh_host_ed25519_key
sshd: no hostkeys available -- exiting.
```



### 修改私钥权限

```shell
chmod 600 /etc/ssh/ssh_host_rsa_key
chmod 600 /etc/ssh/ssh_host_ecdsa_key
chmod 600 /etc/ssh/ssh_host_ed25519_key
```

### 检查权限

```shell
ls -l /etc/ssh/ssh_host_rsa_key
ls -l /etc/ssh/ssh_host_ecdsa_key
ls -l /etc/ssh/ssh_host_ed25519_key
# 输出如下：
-rw------- 1 root root 1675 10月  1 12:34 /etc/ssh/ssh_host_rsa_key
-rw------- 1 root root  227 10月  1 12:34 /etc/ssh/ssh_host_ecdsa_key
-rw------- 1 root root   96 10月  1 12:34 /etc/ssh/ssh_host_ed25519_key
```

### 重启服务

```shell
systemctl restart sshd
service ssh restart
/etc/init.d/sshd restart

systemctl status sshd
```

