#! /bin/bash

dd if=/dev/zero of=EMMC_SOCA.img bs=1M count=16
dd if=/dev/zero of=EMMC_SOCA.img bs=1M count=16 seek=14864

# 清除现有分区并初始化为 GPT
sgdisk --zap-all EMMC_SOCA.img

# 创建新的 GPT 分区表
sgdisk -n 0:16M:+16M -c 1:ESS_A EMMC_SOCA.img
sgdisk -n 0:32M:+16M -c 2:ESS_B EMMC_SOCA.img
sgdisk -n 0:48M:+80M -c 3:OTA_ST EMMC_SOCA.img
sgdisk -n 0:128M:+10M -c 4:RAW_DATA0 EMMC_SOCA.img
sgdisk -n 0:138M:+50M -c 5:RAW_DATA1 EMMC_SOCA.img
sgdisk -n 0:188M:+50M -c 6:RAW_DATA2 EMMC_SOCA.img
sgdisk -n 0:238M:+274M -c 7:RESVED0 EMMC_SOCA.img
sgdisk -n 0:512M:+512M -c 8:KDR_A EMMC_SOCA.img
sgdisk -n 0:1G:+512M -c 9:KDR_B EMMC_SOCA.img
sgdisk -n 0:1536M:+1536M -c 10:LIBFS_A EMMC_SOCA.img
sgdisk -n 0:3G:+1536M -c 11:LIBFS_B EMMC_SOCA.img
sgdisk -n 0:4608M:+256M -c 12:PLATFS_A EMMC_SOCA.img
sgdisk -n 0:4864M:+256M -c 13:PLATFS_B EMMC_SOCA.img
sgdisk -n 0:5G:+1G -c 14:PARKAPPFS_A EMMC_SOCA.img
sgdisk -n 0:6G:+1G -c 15:PARKAPPFS_B EMMC_SOCA.img
sgdisk -n 0:7G:+20M -c 16:RECOVERY EMMC_SOCA.img
sgdisk -n 0:7188M:+200M -c 17:CALDATA EMMC_SOCA.img
sgdisk -n 0:7388M:+1800M -c 18:LOGFS EMMC_SOCA.img
sgdisk -n 0:9188M:+4608M -c 19:OTA_DT EMMC_SOCA.img
sgdisk -n 0:13824M:+1G -c 20:userdata EMMC_SOCA.img

# 检查是否有错误
if [ ! $? == 0 ]; then
    echo -e "\033[31m[ERROR] create EMMC_SOCA.img \033[0m"
    exit 1
fi

# 复制分区表到新的镜像文件
dd if=EMMC_SOCA.img of=EMMC_PARTITION_SOCA.img bs=32768 count=1

# 设置偏移量
dd if=/dev/zero of=EMMC_SOCA.img bs=1024k count=1 seek=64


exit 0
