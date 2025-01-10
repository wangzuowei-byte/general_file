# 安装 openssl

## 卸载现有的 OpenSSL

```shell
apt-get remove --purge openssl libssl-dev
apt-get autoremove
apt-get clean
```

## 重新安装 OpenSSL

```shell
apt-get update
apt-get install openssl libssl-dev
openssl version
```

## 源码安装

​		OpenSSL :  https://www.openssl.org/source/

```shell
wget https://www.openssl.org/source/openssl-1.1.1l.tar.gz
tar -xvzf openssl-1.1.1l.tar.gz
cd openssl-1.1.1l

./config
make
sudo make install
openssl version
```

# 升级 glibc

## 升级glibc到 2.35

执行 do-release-upgrade 遇到键入选择输入:y

```shell
apt-get update
apt-get install ubuntu-release-upgrader-core
apt-get upgrade
do-release-upgrade

```

```
ldd --version
ldd (Ubuntu GLIBC 2.35-0ubuntu3.8) 2.35
Copyright (C) 2022 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
Written by Roland McGrath and Ulrich Drepper.
```

## 安装错误处理

### do-release-upgrade 无法链接无服务

## 检查网络

```shell
ping -c 4 google.com
ping -c 4 changelogs.ubuntu.com
curl -I https://changelogs.ubuntu.com/meta-release
```

## 添加DNS

```shell
cat /etc/resolv.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
```

## 替换源

```shell
mv /etc/apt/sources.list /etc/apt/sources.list-bk
vim /etc/apt/sources.list
# 输入如下内容 注意版本选择对应源， 下面是 20.04对应的源
deb http://archive.ubuntu.com/ubuntu focal main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu focal-updates main restricted universe multiverse
deb http://archive.ubuntu.com/ubuntu focal-backports main restricted universe multiverse
deb http://security.ubuntu.com/ubuntu focal-security main restricted universe multiverse

apt-get update
apt-get upgrade -y
```

## 手动升级

​		**注意：** 手动升级可能会导致依赖问题，需要小心处理

```shell
# 18.04
sed -i 's/bionic/focal/g' /etc/apt/sources.list
# 20.04
sed -i 's/focal/jammy/g' /etc/apt/sources.list
apt-get update
apt-get upgrade -y
apt dist-upgrade -y
```



