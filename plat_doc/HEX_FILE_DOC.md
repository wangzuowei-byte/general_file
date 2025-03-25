# HEX_FILE_DOC

## Tools

```shell
apt-get install bvi
apt-get install hexedit
```

### 使用说明

hexedit

```shell
# 打开文件
hexedit your_file.bin
# 按 Ctrl + S 输入 地址如1000 跳转到地址 0x1000 移动光标修改内容
# 切换十六进制 / ASCII 编辑	Tab
# 保存更改	Ctrl + X，然后 Y（确认）并回车
# 退出不保存	Ctrl + X，然后 N
```

bvi

```shell
bvi your_file.bin
# 按 / 搜索内容
# 按 i 进入编辑模式
# 修改完后按 Esc，输入 :wq 退出并保存
```

## 命令行修改查看

```shell
# 使用 strings 命令 查找内容
# strings your_file.bin | grep "关键字"
strings firmware.bin | grep "version"

# hexdump 或 xxd 查看十六进制
hexdump -C your_file.bin | grep "关键字"
xxd your_file.bin | grep "关键字"

chmod +w NOR.bin

# DD修改
printf '\x41\x42\x43\x7f' | dd of=NOR.bin bs=1 seek=偏移地址 count=3 conv=notrunc
# 修改
printf '\x21\x43\x65\x7f' | dd of=NOR.bin bs=1 seek=$((0x10112C)) conv=notrunc

# bvi 修改
bvi NOR.bin
# 按 / 搜索 FFFFFFFF
# 移动光标到 FFFFFFFF
# 按 r 然后输入 2143657f
# 按 :wq 保存并退出

hexedit NOR.bin
# 按 Ctrl + S 搜索 FFFFFFFF
# 移动光标到 FFFFFFFF
# 输入 2143657f
# 按 Ctrl + X，选择 y 保存并退出

# 查看
hexdump -C NOR.bin | grep 101120
```

