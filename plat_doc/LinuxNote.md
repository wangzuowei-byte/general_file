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

mount

```shell
# 挂载ext4
mount xxx.img path/
# 挂载qnx系统镜像
mount -t qnx6 -o loop xxx.img path/
# linux 热挂载可读写
mount -o remount,rw path/
# qnx 热挂载可读写
mount -uw path/
```



## 系统服务

### Systemd

获取systemd 启动信息

```shell
dmesg |grep systemd
# 查看服务状态如ssh
systemctl ststus ssh
# 查看服务日志
journalctl -xeu ssh.servicesys
systemctl start ssh
systemctl stop ssh
systemctl restart ssh
```

### net-tools

查看端口占用

```shell
# linux
netstat -tulnp | grep :22
-> tcp   0   0 0.0.0.0:22   0.0.0.0:*   LISTEN   1234/sshd

ss -tuln | grep :22
lsof -i :22
-> sshd     1234   root   3u  IPv4  123456  TCP *:ssh (LISTEN)
fuser -n tcp 22

# qnx
sin net | grep 22
pidin net | grep 22
```



## DEV

### uart

```shell
# 打开minicom
minicom -D /dev/ttyUSB0 -b 115200

stty -F /dev/ttySTM1 115200 cs8 -cstopb -parenb
# 关闭回显示缓冲直接显示原始数据
stty -F /dev/ttySTM3 9600 cs8 -cstopb -parenb  raw -echo
stty -F /dev/ttymxc4 115200 cs8 -parenb -cstopb -ixon -ixoff raw -echo
# 纯数据通信（推荐）
stty -F /dev/ttymxc4 115200 cs8 -parenb -cstopb -crtscts -ixon -ixoff raw -echo
# 终端交互调试
stty -F /dev/ttymxc4 115200 cs8 -parenb -cstopb -crtscts -ixon -ixoff -echo

# 发送数据到串口
echo -n "Hello" > /dev/ttySTM2
# 读取串口
cat /dev/ttySTM2 | hexdump -C
cat /dev/ttySTM2

# 查看设备信息
dmesg | grep ttySTM2
dmesg | grep pinctrl
cat /sys/kernel/debug/pinctrl/*/pins | grep PB1
cat /sys/kernel/debug/pinctrl/*/pinmux-pins | grep 12
devmem 0x40011000
```

cs8	数据位 8 bits
-parenb	禁用奇偶校验（No Parity）
-cstopb	1 位停止位（如果设为 cstopb 则是 2 位停止位）
-ixon	禁用 输入（接收）软件流控（XON/XOFF）
-ixoff	禁用 输出（发送）软件流控（XON/XOFF）
raw	原始模式（禁用终端处理，直接传递原始数据，不解释特殊字符如 ^C）
-echo	禁用回显（不把接收到的数据回显到终端）

## 编译构建

### defconfog

```shell
# 添加initramfs
CONFIG_INITRAMFS_SOURCE="initramfs"
CONFIG_INITRAMFS_ROOT_UID=0
CONFIG_INITRAMFS_ROOT_GID=0
CONFIG_INITRAMFS_COMPRESSION_GZIP=y
CONFIG_RD_GZIP=y
CONFIG_RD_ZSTD=y

# ko.gz
CONFIG_MODULE_COMPRESS=y
CONFIG_MODULE_COMPRESS_GZIP=y
```

### initramfs

#### 构建initramfs

```shell
rm -rf ./initramfs/dev/console
rm -rf ./initramfs/dev/null

mknod -m 660 ./initramfs/dev/console c 5 1
mknod -m 660 ./initramfs/dev/null    c 1 3
```

#### 查看image 文件构成

```shell
# 查看Image 构成
binwalk Image
: '
字段解析
DECIMAL	HEXADECIMAL	DESCRIPTION
0	0x0	Linux kernel ARM64 image：表示内核镜像的开始，通常指示该区域是一个 ARM64 架构的 Linux 内核镜像。
13725696	0xD17000	ELF, 64-bit LSB shared object：表示一个 64 位的 ELF 可执行文件或共享库，SYSV 表示 System V 格式。它可能是某个系统模块或库。
13747056	0xD1C370	gzip compressed data：gzip 压缩的文件。数据来源可能是某个文件，显示为使用最大压缩率的 gzip 压缩数据。
14045016	0xD64F58	Base64 standard index table：Base64 编码的索引表。通常用于加密或者是某种文件格式的编码。
14045376	0xD650C0	SHA256 hash constants：这是 SHA256 哈希常量，通常用于加密算法中。
14062720	0xD69480	CRC32 polynomial table：CRC32 校验和多项式表，用于生成 CRC32 校验和。
14281320	0xD9EA68	Intel x86 or x64 microcode：这是 Intel x86 或 x64 架构的微码更新数据。用于修复或增强处理器功能。
14898359	0xE354B7	Intel x86 or x64 microcode：另一个微码更新数据。
14913858	0xE39142	Intel x86 or x64 microcode：另一个微码更新数据。
15059323	0xE5C97B	Neighborly text：表示某些邻接文本信息，可能是与网络邻接或网络协议相关的调试信息。
15220290	0xE83E42	Unix path：路径 /var/run/rpcbind.sock，表示一个 Unix 域套接字路径。
15243392	0xE89880	LZO compressed data：LZO 压缩数据格式，常用于压缩文件。
17300456	0x107FBE8	Unix path：路径 /dev/vc/0，表示一个虚拟控制台设备。
17450872	0x10A4778	xz compressed data：XZ 压缩数据，通常具有更高的压缩比。
17453898	0x10A534A	Ubiquiti firmware header：Ubiquiti 固件的头部数据，标明这是一个来自 Ubiquiti 设备的固件，带有 CRC32 校验。
17682965	0x10DD215	Unix path：路径 /dev/xen/evtchn，表示 Xen 虚拟化环境的事件通道设备路径。
17712586	0x10E45CA	Unix path：路径 /sys/kernel/debug/dri.，表示系统中与图形驱动调试相关的路径。
17724904	0x10E75E8	Neighborly text：又一段邻接文本信息。
17766528	0x10F1880	Unix path：路径 /sys/kernel/debug/VIRT_CRTC-[x]/pattern，与虚拟显示器相关的路径。
17829567	0x1100EBF	Unix path：路径 /dev/disk/by-id/，指向磁盘设备的路径。
17917357	0x11165AD	PARity archive data - Index file：与一个归档文件相关的索引文件，通常用于存档数据的存取。
18102927	0x1143A8F	Copyright string：版权信息，表明某些文件的版权归 Rodolfo Giometti 所有。
18139313	0x114C8B1	Copyright string：另一个版权信息，表示 Pierre Ossman 的版权。
18166504	0x11532E8	Unix path：路径 /sys/firmware/devicetree/base，指向设备树的路径。
18170153	0x1154129	Unix path：路径 /sys/firmware/fdt，指出设备树文件路径，并显示了 CRC 校验失败的错误。
18258833	0x1169B91	Neighborly text：更多的邻接文本信息，可能与网络问题相关。
18318984	0x1178688	Neighborly text：更多的邻接信息，可能涉及邻接广告或请求等。
18319008	0x11786A0	Neighborly text：更多的邻接文本。
18324170	0x1179ACA	Neighborly text：邻接信息，描述某种网络状态。
19626096	0x12B7870	gzip compressed data：另一个 gzip 压缩的数据块。
27559424	0x1A48600	AES S-Box：表示 AES 算法中的 S-Box 表，用于加密和解密数据。
27559680	0x1A48700	AES Inverse S-Box：表示 AES 算法中的反向 S-Box 表，用于解密数据。
35973474	0x224E962	MySQL MISAM index file Version 9：MySQL 数据库的索引文件，格式为 MISAM，版本 9。
35974970	0x224EF3A	MySQL MISAM index file Version 9：另一个 MISAM 格式的 MySQL 索引文件。
'
dd if=Image of=initramfs_full.gz bs=1 skip=19626096 count=31457280
gunzip initramfs_full.gz
mkdir initramfs_root && cd initramfs_root

cpio -idv < ../initramfs_full

```

#### 查看image中initramfs文件系统

```shell
# 查看编译文件中是否包含 initramfs
grep -i initramfs System.map
# 如果是非压缩的initramfs 查找 cpio头
grep -a -b -o '070701' Image
17186648:070701
# 提取 17186648 地址开始的的cpio文件
dd if=Image bs=1 skip=17186648 of=initramfs.cpio
mkdir initramfs_root
cd initramfs_root
cpio -idmv < ../initramfs.cpio

# 获取压缩版的initramfs 文件 skip 取上面binwalk Image的输出 19626096	0x12B7870	gzip compressed data
dd if=Image of=initramfs_full.gz bs=1 skip=19626096 count=31457280
# 或
dd if=Image of=initramfs_full.gz bs=1 skip=19626096
# 解压
gunzip initramfs_full.gz
mkdir initramfs_root
cd initramfs_root
# 提取 cpio 问价内容
cpio -idv < ../initramfs_full
```

### 构建 Image.ibt

编写配置文件 kernel.its

```shell
/*
 * U-Boot uImage source file with multiple kernels, ramdisks and FDT blobs
 */

/dts-v1/;

/ {
	description = "Various kernels, ramdisks and FDT blobs";
	#address-cells = <1>;

	images {
		kernel {
			description = "Image linux-6.1.64 from BST C1200";
			data = /incbin/("./build/arch/arm64/boot/Image.gz");
			type = "kernel";
			arch = "arm64";
			os = "linux";
			compression = "gzip";
			load = <0x84000000>;
			entry = <0x84000000>;
			/*hash-1 {
				algo = "md5";
			};
			hash-2 {
				algo = "sha1";
			};*/
		};
		
		fdt-platform-L {
			description = "bstc1200-platform-L fdt";
			data = /incbin/("./build/arch/arm64/boot/dts/bst/bstc1236-cdcu1.0-adas_8c4g.dtb");
			type = "flat_dt";
			arch = "arm64";
			compression = "none";
			hash-1 {
				algo = "crc32";
			};
		};
		fdto-platform-L {
			description = "bstc1200-platform-L fdt overlay";
			data = /incbin/("./build/arch/arm64/boot/dts/bst/overlay/isp-jica/c1200-cdcu/4hkx3f_2hkx8b_1hkx3c.dtbo");
			type = "flat_dt";
			arch = "arm64";
			compression = "none";
			hash-1 {
				algo = "crc32";
			};
		};
	};

	configurations {
		default = "config-platform-L";
		
		config-platform-L {
			description = "bstc1200 platform-L configuration";
			kernel = "kernel";
			fdt = "fdt-platform-L";
			fdt-overlay = "fdto-platform-L";
		};
	};
};
```

配置 Makefile

arch/arm64/boot/Makefile

```makefile
OBJCOPYFLAGS_Image :=-O binary -R .note -R .note.gnu.build-id -R .comment -S

targets := Image Image.bz2 Image.gz Image.lz4 Image.lzma Image.lzo Image.zst Image.itb

quiet_cmd_mkitb = MKITB   $@
      cmd_mkitb = mkimage -f $< $@ #> /dev/null 2>&1

quiet_cmd_copy_itb = COPY    $@
	  cmd_copy_itb = cp $< $@ $(objtree)


ifeq ($(CONFIG_ARCH_BSTC1200),y)
$(obj)/Image.itb: $(srctree)/kernel_jica.its FORCE
	$(call cmd,mkitb)
	$(call cmd,copy_itb)
endif


$(obj)/Image: vmlinux FORCE
	$(call if_changed,objcopy)

$(obj)/Image.bz2: $(obj)/Image FORCE
	$(call if_changed,bzip2)

$(obj)/Image.gz: $(obj)/Image FORCE
	$(call if_changed,gzip)

$(obj)/Image.lz4: $(obj)/Image FORCE
	$(call if_changed,lz4)

$(obj)/Image.lzma: $(obj)/Image FORCE
	$(call if_changed,lzma)

$(obj)/Image.lzo: $(obj)/Image FORCE
	$(call if_changed,lzo)

$(obj)/Image.zst: $(obj)/Image FORCE
	$(call if_changed,zstd)

EFI_ZBOOT_PAYLOAD	:= Image
EFI_ZBOOT_BFD_TARGET	:= elf64-littleaarch64
EFI_ZBOOT_MACH_TYPE	:= ARM64
```

arch/arm64/Makefile

```shell
...
ifndef KBUILD_MIXED_TREE
all:	Image.lz4 Image.itb #Image_a.raw Image_b.raw
endif


Image.itb: Image.gz dtbs
	$(Q)$(MAKE) $(build)=$(boot) $(boot)/$@

Image vmlinuz.efi: vmlinux
	$(Q)$(MAKE) $(build)=$(boot) $(boot)/$@

Image.%: Image
	$(Q)$(MAKE) $(build)=$(boot) $(boot)/$@

install: KBUILD_IMAGE := $(boot)/Image
install zinstall:
	$(call cmd,install)
...
```

### rootfs

设置默认密码

```shell
# 生成加密密码
openssl passwd -6 'root'
# 将生成的密码写入文件
etc/shadow

# e.g.
openssl passwd -6 'root'
# 生成密码如：
$6$K4Dc3g76W.fZjKLO$bf3o5l7AeWnT...UHRNHs9goOxUyxNN9
vim etc/shadow
# 找到如下内容，一般是第一行
root:$6$fBKXLhCmHSVDE7Kp$kTtcoQoE6KPw28GI3Xt5p8ZuFIVM/xQ8wzIqPToxVrLDeJDyuEeARu61yiQ6.IQr5f4ixfbtlg3YgQ4n6lYKd0:20084:0:99999:7:::
# 修改为
root:$6$K4Dc3g76W.fZjKLO$bf3o5l7AeWnT...UHRNHs9goOxUyxNN9:20084:0:99999:7:::
# 取消登录密码
root::20084:0:99999:7:::
```



