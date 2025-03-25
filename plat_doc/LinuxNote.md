# Linux Note

## Shell 

### 获取路径

```shell
# 返回物理路径
TOOLCHAIN_PATH=$(readlink -f "$(dirname "$0")")
# 返回物理路径
TOOLCHAIN_PATH="$(cd "$(dirname "$0")" && pwd -P)"
# 返回执行路径（不解析软连接）
TOOLCHAIN_PATH="$(cd "$(dirname "$0")" && pwd -L)"
```

## 系统服务

### Systemd

获取systemd 启动信息

```shell
dmesg |grep systemd
```



