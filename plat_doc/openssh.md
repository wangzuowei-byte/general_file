# openssh

## build

```shell
# 源码获取
# https://www.openssh.com/
# 获取源码
apt-get source openssh
# git 获取
git clone https://github.com/openssh/openssh-portable.git

# 安装依赖
apt-get update
apt-get install build-essential zlib1g-dev libssl-dev

# 编译
cd openssh/
./autoreconf -i

mkdir build && cd build

../configure                       \
--host=aarch64-bst-linux           \
--with-entropy-source=/dev/urandom \
--without-openssl-header-check     \
--disable-strip                    \
--disable-pam                      \
--disable-lastlog                  \
--disable-utmp                     \
--disable-wtmp                     \
--disable-libutil                  \
--disable-pututline                \
--disable-pututxline               \
--without-shadow                   \
--without-selinux                  \
--without-zlib                     \
--sysconfdir=/etc/ssh              \
--localstatedir=/var               \
--with-privsep-path=/var/empty     \
ac_cv_func_setpgrp_void=yes        \
ac_cv_func_getpgrp_void=yes        \
ac_cv_func_getaddrinfo=yes         \
ac_cv_have_decl_AI_NUMERICSERV=yes \
CC="${CC} --sysroot=${SYSROOT}"    \
CXX="${CXX} --sysroot=${SYSROOT}"  \
--prefix=/usr 

make INSTALL_SSH_KEYGEN=no -j16
make DESTDIR=${PRJ_INSTALL_PATH} install
```

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

## 移植

```shell
├── etc
│   ├── passwd
│   ├── shadow
│   ├── ssh
│   │   ├── moduli
│   │   ├── ssh_config
│   │   ├── ssh_host_ecdsa_key
│   │   ├── ssh_host_ecdsa_key.pub
│   │   ├── ssh_host_ed25519_key
│   │   ├── ssh_host_ed25519_key.pub
│   │   ├── ssh_host_rsa_key
│   │   ├── ssh_host_rsa_key.pub
│   │   └── sshd_config
│   └── systemd
│       └── system
│           └── sockets.target.wants
│               └── ssh.service -> /usr/lib/systemd/system/ssh.service
├── home
│   └── root
│       └── .ssh
│           └── authorized_keys
└── usr
    ├── bin
    │   ├── ffe_client_adas_cpu6
    │   ├── scp
    │   ├── sftp
    │   ├── ssh
    │   ├── ssh-add
    │   ├── ssh-agent
    │   ├── ssh-keygen
    │   └── ssh-keyscan
    ├── lib
    │   ├── libssl.so -> libssl.so.1.1
    │   ├── libssl.so.1.1
    │   ├── libssl3.so
    │   ├── systemd
    │   │   └── system
    │   │       └── ssh.service
    ├── libexec
    │   ├── openssh
    │   │   └── sshd_check_keys
    │   ├── sftp-server
    │   ├── ssh-keysign
    │   ├── ssh-pkcs11-helper
    │   ├── ssh-sk-helper
    │   ├── sshd-auth
    │   └── sshd-session
    └── sbin
        └── sshd

```



### 配置 passwd

生成密码

```shell
openssl passwd -6 '123456'
$6$0/pD247YqaXdr8CR$M.W79Jx27NqkzpJTSpHvBPgQWWcZWigqfdRM6bp0uxc0B5toRyoLNajr2i8gl3NImKXsox8nbGYcckT9PNmew0
```

/etc/passwd

```
# 设置密码 root::0:0:root:/home/root:/bin/sh
root:$6$0/pD247YqaXdr8CR$M.W79Jx27NqkzpJTSpHvBPgQWWcZWigqfdRM6bp0uxc0B5toRyoLNajr2i8gl3NImKXsox8nbGYcckT9PNmew0:0:0:root:/home/root:/bin/sh
# 配置sshd
sshd:x:74:74:Privilege-separated SSH:/var/empty/sshd:/sbin/nologin
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
games:x:5:60:games:/usr/games:/usr/sbin/nologin
man:x:6:12:man:/var/cache/man:/usr/sbin/nologin
lp:x:7:7:lp:/var/spool/lpd:/usr/sbin/nologin
mail:x:8:8:mail:/var/mail:/usr/sbin/nologin
news:x:9:9:news:/var/spool/news:/usr/sbin/nologin
uucp:x:10:10:uucp:/var/spool/uucp:/usr/sbin/nologin
proxy:x:13:13:proxy:/bin:/usr/sbin/nologin
www-data:x:33:33:www-data:/var/www:/usr/sbin/nologin
backup:x:34:34:backup:/var/backups:/usr/sbin/nologin
list:x:38:38:Mailing List Manager:/var/list:/usr/sbin/nologin
irc:x:39:39:ircd:/run/ircd:/usr/sbin/nologin
_apt:x:42:65534::/nonexistent:/usr/sbin/nologin
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
messagebus:x:999:999::/var/lib/dbus:/bin/false
test:x:1000:1001::/home/test:/bin/sh
```

/etc/shadow

```shell
# 配置密码 root::19863:0:99999:7:::
root:$6$0/pD247YqaXdr8CR$M.W79Jx27NqkzpJTSpHvBPgQWWcZWigqfdRM6bp0uxc0B5toRyoLNajr2i8gl3NImKXsox8nbGYcckT9PNmew0:19863:0:99999:7:::
sshd:*:1:0:99999:7:::
daemon:*:19863:0:99999:7:::
bin:*:19863:0:99999:7:::
sys:*:19863:0:99999:7:::
sync:*:19863:0:99999:7:::
games:*:19863:0:99999:7:::
man:*:19863:0:99999:7:::
lp:*:19863:0:99999:7:::
mail:*:19863:0:99999:7:::
news:*:19863:0:99999:7:::
uucp:*:19863:0:99999:7:::
proxy:*:19863:0:99999:7:::
www-data:*:19863:0:99999:7:::
backup:*:19863:0:99999:7:::
list:*:19863:0:99999:7:::
irc:*:19863:0:99999:7:::
gnats:*:19863:0:99999:7:::
systemd-bus-proxy:!:19863:0:99999:7:::
messagebus:!:19863:0:99999:7:::
bst:$6$vtZGI/TckI7/MtZv$ifX8/AcMR2UmQebyZqKKkXrRO8d.BG22Ws5X0IjZRJFmLhyL4z4zm4vojTOq9zsjlV1.DAAoXRcFx2y81S1wz0:19863:0:99999:7:::
nobody:*:19863:0:99999:7:::
```

/home/root/.ssh/authorized_keys

```shell
chmod 700 /home/root
chmod 700 /home/root/.ssh
chmod 600 /home/root/.ssh/authorized_keys
chown -R root:root /home/root

# 生成密钥
ssh-keygen -t rsa -b 2048
cat ~/.ssh/id_rsa.pub # 将内容写入 authorized_keys
```

/e t c/ssh/sshd_config

```shell
Port 22
PermitRootLogin yes
PasswordAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
```

/usr/lib/systemd/system/ssh.service

```shell
[Unit]
Description=OpenBSD Secure Shell server
Documentation=man:sshd(8) man:sshd_config(5)
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/etc/ssh/sshd_not_to_be_run

[Service]
EnvironmentFile=-/etc/default/ssh
ExecStartPre=/bin/sleep 6
ExecStartPre=/bin/mkdir -p /var/run/sshd
#ExecStartPre=/bin/mkdir -p /var/empty
ExecStartPre=/usr/sbin/sshd -t
ExecStart=/usr/sbin/sshd -D
ExecReload=/usr/sbin/sshd -t
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-abort
RestartSec=5s
RestartPreventExitStatus=255
Type=notify
RuntimeDirectory=sshd
RuntimeDirectoryMode=0755

[Install]
WantedBy=multi-user.target
Alias=sshd.service
```

打包条件

```shell
# 创建服务链接
ln -sf /usr/lib/systemd/system/ssh.service /etc/systemd/system/sockets.target.wants/ssh.service

# 针对只读文件系统预处理必要目录结构
mkdir -p  ${LIBFS_PATH}/var/run/sshd
chmod 755 ${LIBFS_PATH}/var/run/sshd
mkdir -p ${LIBFS_PATH}/var/empty
chown root:root ${LIBFS_PATH}/var/empty
chmod 755 ${LIBFS_PATH}/var/empty
# 构建密钥
ssh-keygen -t rsa -f ${LIBFS_PATH}/etc/ssh/ssh_host_rsa_key -N ""
ssh-keygen -t ecdsa -f ${LIBFS_PATH}/etc/ssh/ssh_host_ecdsa_key -N ""
ssh-keygen -t ed25519 -f ${LIBFS_PATH}/etc/ssh/ssh_host_ed25519_key -N ""
```

## vs code remote

win

```shell
ssh-keygen -t rsa -b 4096 -C "zuowei.wang@ecarxgroup.com"
# 查看密钥
cat ~/.ssh/id_rsa.pub
# 查看路径
pwd
```

server

```shell
mkdir -p ~/.ssh
chmod 700 ~/.ssh
# 将 win ssh key 写入文件
vim ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

vscode cfg

```shell
# 自定义名称
Host dev-88-3622
	# 服务器IP
    HostName 10.43.60.88
    # 用户名
    User root
    # 端口
    Port 3622
    # pwd 查看的本机密钥
    IdentityFile c:/Users/zuowei.wang.ECARX/.ssh/id_rsa
```

