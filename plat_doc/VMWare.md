# VMWare

## NAT 网络设置

### Vmware 网络设置

编辑 -> 虚拟网络编辑器

1. 勾选 NAT模式（与虚拟机共享主机的IP地址）
2. 取消勾选 使用本地 DHCP

VMnet8  NAT模式

```shell
# 子网IP
111.111.111.111.0
# 子网掩码
255.255.255.0
# NAT设置 网关
111.111.111.254
```

### 本机网卡设置

控制面板-> 网络共享中心 -> 更改wangluoshipeiq

VMware Network Adapter VMnet8 -> 属性

IPV4

```shell
# IP
111.111.111.1
# 子网掩码
255.255.255.0
网关
111.111.111.254
# DNS
8.8.8.8
```

### 虚拟机网卡

```shell
# IP
111.111.111.111
# 子网掩码
255.255.255.0
# 网关
111.111.111.254
# DNS
8.8.8.8
```





## 磁盘瘦身

### 系统命令

```shell
apt clean
journalctl --vacuum-time=7d
dd if=/dev/zero of=zero.fill bs=1M  || true
rm -f zero.fill
sync
```

### 主机设置

1. 关闭虚拟机
2. 打开虚拟机设置（不是编辑.vmx 文件）选中虚拟机 → 右键或点击菜单 → 选择「设置（Settings）」或「虚拟机设置（Virtual Machine Settings）」
3. 硬盘 (Hard Disk) -> (工具) Compact（压缩）

### 导出全新 .vmdk

```shell
# 导出新的磁盘注意.vmdk文件路径和文件名
# cmd
"C:\Program Files (x86)\VMware\VMware Workstation\vmware-vdiskmanager.exe" -r "E:\Virtual Machines\ubuntu18.04\Ubuntu18.04.vmdk" -t 0 "F:\tmp\Ubuntu18.04-slim.vmdk"

# powershell
& "C:\Program Files (x86)\VMware\VMware Workstation\vmware-vdiskmanager.exe" `
  -r "E:\Virtual Machines\ubuntu18.04\Ubuntu18.04.vmdk" `
  -t 0 `
  "F:\tmp\Ubuntu18.04-slim.vmdk"
# 整合单行命令
& "C:\Program Files (x86)\VMware\VMware Workstation\vmware-vdiskmanager.exe" -r "E:\Virtual Machines\ubuntu18.04\Ubuntu18.04.vmdk" -t 0 "F:\tmp\Ubuntu18.04-slim.vmdk"
# 将生成的文件替换原来的文件
```

