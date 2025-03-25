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

