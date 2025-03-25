# shell 

### 获取路径

```shell
# 返回物理路径
TOOLCHAIN_PATH=$(readlink -f "$(dirname "$0")")
# 返回物理路径
TOOLCHAIN_PATH="$(cd "$(dirname "$0")" && pwd -P)"
# 返回执行路径（不解析软连接）
TOOLCHAIN_PATH="$(cd "$(dirname "$0")" && pwd -L)"
```

### dd 远程更新linux EMMC 整体镜像

```shell
dd if=EMMC_SOCA.img | ssh -o "StrictHostKeyChecking=no" -o "HostkeyAlgorithms=+ssh-rsa" root@172.20.30.8 dd of=/dev/mmcblk0
```

