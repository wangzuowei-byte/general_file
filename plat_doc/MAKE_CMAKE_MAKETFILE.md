# MAKE_CMAKE_MAKETFILE

## Makefile



## Make



## CMake

### LD Lib 路径设置

指定编译阶段的依赖库查找位置，但不会传播 影响LDD  ，去掉相对路径

```shell
target_link_libraries(ApMonitor PRIVATE -L${CMAKE_BINARY_DIR}/frrt_package/frrt -lfrrt)
```

告诉编译器在编译阶段去这个路径下找动态库但是不传递给ld  也就是不参与运行时链接

```shell
set(CMAKE_EXE_LINKER_FLAGS "-Wl,-rpath-link,${CMAKE_BINARY_DIR}/frrt_package/frrt/")
```

## 动态库连接追溯

### 查看动态库

```shell
readelf -d MonitorTool
# 查看所有 CMakeLists 文件中出现 spdlog 信息的地方
grep -nr --include=CMakeLists.txt spdlog .
```

### 通过日志查看连接过程

```shell
# 安装工具
apt-get install strace

# CMAKE 生成日志
strace -f -e trace=file -o cmake.strace.log cmake ..
# MAKE 生成日志
# strace -f -e trace=file -o make.strace.log make VERBOSE=1 -j8
strace -f -e trace=file -o make.strace.log make -j8

# 查看可执行文件 需要平台匹配
strace -f -e trace=file ./MonitorTool

# 查看cmake阶段某个库的连接信息
grep libspdlog.so cmake.strace.log
# 查看make阶段某个库的连接信息
grep libspdlog.so make.strace.log

# 查看所有库信息
grep '\.so' cmake.strace.log | sort | uniq
grep '\.so' make.strace.log | sort | uniq

```

