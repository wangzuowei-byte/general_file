# openssh

## build



## install dir

```
    ├── bin
    │   ├── scp
    │   ├── sftp
    │   ├── ssh
    │   ├── ssh-add
    │   ├── ssh-agent
    │   ├── ssh-keygen
    │   └── ssh-keyscan
    ├── etc
    │   ├── moduli
    │   ├── ssh_config
    │   └── sshd_config
    ├── libexec
    │   ├── sftp-server
    │   ├── ssh-keysign
    │   ├── ssh-pkcs11-helper
    │   ├── ssh-sk-helper
    │   ├── sshd-auth
    │   └── sshd-session
    ├── sbin
    │   └── sshd
    └── share
        └── man
            ├── man1
            │   ├── scp.1
            │   ├── sftp.1
            │   ├── ssh-add.1
            │   ├── ssh-agent.1
            │   ├── ssh-keygen.1
            │   ├── ssh-keyscan.1
            │   └── ssh.1
            ├── man5
            │   ├── moduli.5
            │   ├── ssh_config.5
            │   └── sshd_config.5
            └── man8
                ├── sftp-server.8
                ├── ssh-keysign.8
                ├── ssh-pkcs11-helper.8
                ├── ssh-sk-helper.8
                └── sshd.8
```

## 必须打包内容

​	二进制

```
bin/
├── scp
├── sftp
├── ssh
├── ssh-add
├── ssh-agent
├── ssh-keygen
└── ssh-keyscan

sbin/sshd

libexec/
├── sftp-server
├── ssh-keysign
└── ssh-pkcs11-helper (如果使用PKCS#11)
```

​	配置文件

```
etc/
├── moduli
├── ssh_config
└── sshd_config
```

## 配置

必须将以下目录挂载为可写(使用 tmpfs 或单独的可写分区)：

```
/var/run/sshd       # 用于PID文件
/var/empty/sshd     # 特权分离目录
/etc/ssh/ssh_host*  # 主机密钥(如果不想预生成)
/home/<user>/.ssh   # 用户授权密钥目录
```



/etc/passwd

```
sshd:x:74:74:Privilege-separated SSH:/var/empty/sshd:/sbin/nologin
```

/etc/fstab

```
tmpfs /var/run tmpfs mode=0755,size=1m 0 0
tmpfs /var/empty/sshd tmpfs mode=0755,size=1m 0 0
tmpfs /etc/ssh tmpfs mode=0755,size=1m 0 0  # 如果允许运行时生成密钥
```

打包时构建密钥

```
ssh-keygen -t rsa -f ${ROOTFS}/etc/ssh/ssh_host_rsa_key -N ""
ssh-keygen -t ecdsa -f ${ROOTFS}/etc/ssh/ssh_host_ecdsa_key -N ""
ssh-keygen -t ed25519 -f ${ROOTFS}/etc/ssh/ssh_host_ed25519_key -N ""
```

/e t c/ssh/sshd_config

```

PermitRootLogin no (推荐)
PasswordAuthentication yes (如果要用密码登录)
PubkeyAuthentication yes (如果要用密钥登录)
AuthorizedKeysFile .ssh/authorized_keys
UsePrivilegeSeparation yes
StrictModes yes
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key
```

systemd

```

复制
[Unit]
Description=OpenSSH Daemon
After=network.target
ConditionPathIsReadWrite=/var/run

[Service]
EnvironmentFile=-/etc/default/ssh
ExecStartPre=/bin/mkdir -p /var/run/sshd
ExecStartPre=/bin/chmod 0755 /var/run/sshd
ExecStart=/usr/sbin/sshd -D $SSHD_OPTS
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

