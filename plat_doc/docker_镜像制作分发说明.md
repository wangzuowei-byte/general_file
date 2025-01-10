# docker 镜像制作分发说明

## 镜像制作

### 直接采用commit制作

```shell
# 用容器ID制作镜像 : 镜像名字只能 小写字母 _ .
docker commit <container_id> <image_name>:<tag>
# e.g. 给容器ID为aef7cee575df 制作个镜像 名字为 ubuntu1804_c1200_mcu 版本 v1.0
docker commit aef7cee575df ubuntu1804_c1200_mcu:v1.0
```

### 容器内容导出制作

```shell
# 将配置好的容器内容导出为一个 .tar 文件：
docker export <容器ID> > container_export.tar
# e.g. 将容器ID为aef7cee575df导出
docker export aef7cee575df ubuntu1804_c1200_mcu_v1.1.tar

# 创建一个工作目录并将归档文件释放到工作目录
mkdir docker_build
tar -xvf ubuntu1804_c1200_mcu_v1.1.tar -C docker_build

# 进入工作目录,创建Dockerfile
cd docker_build
vim Dockerfile
# 录入如下内容:
FROM scratch
ADD . /
CMD ["bash"]
# 构建镜像
docker build -t <镜像名>:<版本> .
# e.g.
docker build -t ubuntu1804_c1200_mcu:v1.1
```

## 分发

### 发布到 Docker Hub

```shell
docker login
docker tag <image_name>:<tag> <docker_hub_username>/<repository_name>:<tag>
docker push <docker_hub_username>/<repository_name>:<tag>
```

### 发布到私有镜像仓库

```
docker login <registry_url>
docker tag <image_name>:<tag> <registry_url>/<namespace>/<repository_name>:<tag>
docker push <registry_url>/<namespace>/<repository_name>:<tag>
```

### 导出镜像并分发

```shell
# 将制作的镜像保存为本地文件 ubuntu1804_c1200_mcu.tar
docker save -o ubuntu1804_c1200_mcu.tar ubuntu1804_c1200_mcu:v1.0
# 在目标系统倒入拿到的离线镜像文件
docker load -i ubuntu1804_c1200_mcu.tar
```

## 镜像使用

```shell
# 在目标系统倒入拿到的离线镜像文件
docker load -i ubuntu1804_c1200_mcu.tar
# 创建用户数据卷目录
mkdir /home/docker_data
# 创建latest标签
docker tag ubuntu1804_c1200_mcu:v1.1 ubuntu1804_c1200_mcu:latest
# 运行容器
docker run -it --name mcu_docker -v /home/docker_data:/work -p 10022:22  ubuntu1804_c1200_mcu:v1.1 bash  -c "service ssh start && bash"
```

