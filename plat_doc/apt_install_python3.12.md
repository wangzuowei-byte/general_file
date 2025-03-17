

# apt install python

## install python bash

```shell
apt-get update
# 18.04
apt-get install python
# 20.04 ->
apt-get install python2
apt-get install python3

ln -sf /usr/bin/python3 /usr/bin/python
```

## install python env pack

```shell
apt install python3-pip -y
# 方法一 直接替换指定版本
pip3 install --upgrade protobuf==3.20.*
# 方法二 如果有多个版本先卸载protobuf
pip uninstall protobuf -y
pip3 uninstall protobuf -y
pip show protobuf
pip3 show protobuf
# 版本依然存在手动清除，对应版本的文件如[python3.10,python3.12]
rm -rf /usr/local/lib/python3.10/dist-packages/protobuf*
rm -rf /usr/local/lib/python3.12/site-packages/protobuf*
# 安装指定版本
pip install protobuf==3.20.3
pip3 install protobuf==3.20.3
# 也可指定paython版本安装
pip3 install pandas # 或 python3 -m pip install pandas
pip3 install openpyxl
pip3 install mako # python3 -m pip install mako
pip3 install networkx # python3 -m pip install networkx
```

## install mingw64

```shell
apt-get install -y mingw-w64
update-alternatives --set x86_64-w64-mingw32-gcc /usr/bin/x86_64-w64-mingw32-gcc-posix
update-alternatives --set x86_64-w64-mingw32-g++ /usr/bin/x86_64-w64-mingw32-g++-posix

```



## apt install python3.12

### 基础工具安装

```shell
apt-get update
apt-get install -y software-properties-common
```

```shell
add-apt-repository ppa:deadsnakes/ppa
apt-get update
apt-get install python3.12 python3.12-venv python3.12-dev
```

### 恢复环境

```shell
which python3.12
ls -l /usr/bin/python3.12

rm -f /usr/local/bin/python3.12
hash -r  # 清除 shell 记忆的旧路径
python3.12 --version

ln -sf /usr/bin/python3.12 /usr/bin/python3
ln -sf /usr/bin/python3 /usr/bin/python
# 安装3.12 python 版本的protobuf
python3.12 -m pip install protobuf==3.20.3
```

