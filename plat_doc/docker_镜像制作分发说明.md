# docker 使用说明



## 容器管理

### docker-compose

基础使用

* 安装

```shell
# apt 安装
apt-get install -y docker-compose
# 手动安装
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

* 启动管理

```shell
# 启动管理
docker-compose up -d   # 后台启动所有服务
# 多个yml文件
docker-compose -f docker-compose.yml -f docker-compose.override.yml up
docker-compose down    # 停止并删除所有服务
docker-compose restart # 重启所有服务
docker-compose stop    # 停止服务
docker-compose start   # 启动已创建但未运行的服务

# 查看日志
docker-compose logs  # 查看所有服务的日志
docker-compose logs -f web  # 实时查看某个服务的日志

# 运行命令
docker-compose exec web bash  # 进入 web 容器的 Shell
docker-compose run web ls -l  # 在 web 容器内执行命令

# 查看状态
docker-compose ps  # 查看当前运行的容器

# 构建更新
docker-compose build   # 构建或重新构建服务
docker-compose pull    # 拉取镜像
docker-compose up --build  # 重新构建并启动服务

# 清理 Docker Compose 资源
docker-compose down -v  # 删除容器和数据卷
docker-compose rm       # 删除已停止的容器
docker system prune -f  # 清理未使用的 Docker 资源
```

重置容器

```shell
docker stop dev014
docker rm dev014
docker-compose -f ./docker-compose.yml up -d dev014
```



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
docker export aef7cee575df ubuntu1804_c1200_mcu.tar

# 创建一个工作目录并将归档文件释放到工作目录
mkdir docker_build
tar -xvf ubuntu1804_c1200_mcu.tar -C docker_build

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
docker build -t ubuntu1804_c1200_mcu:v1.0 .
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
docker save -o ubuntu1804_c1200_mcu_v1.0.tar ubuntu1804_c1200_mcu:v1.0
# 在目标系统倒入拿到的离线镜像文件
docker load -i ubuntu1804_c1200_mcu_v1.0.tar
```

## 镜像使用

```shell
# 在目标系统倒入拿到的离线镜像文件
docker load -i ubuntu1804_c1200_mcu_v1.0.tar
# 创建用户数据卷目录
mkdir /home/docker_data
# 创建latest标签
docker tag ubuntu1804_c1200_mcu:v1.0 ubuntu1804_c1200_mcu:latest
# 运行容器
docker run -it --name mcu_docker -v /home/docker_data:/work -p 10022:22  ubuntu1804_c1200_mcu:v1.1 bash  -c "service ssh start && bash"
```

## yml

### 目录结构

```
/mnt/docker/compose# tree -L 2
.
├── ubuntu_dev
│   ├── dev001
│   ├── dev003
│   ├── dev006
│   ├── soc_dev.yml
│   └── tips
└── ubuntu_dev_v0.4
    ├── dev014
    ├── dev015
    ├── dev016
    ├── dev019
    ├── docker-compose.yml
    ├── startup.sh
    └── tips
```



### docker-compose.yml

```shell
version: "2"
services:

  dev014:
    image: "ubuntu-dev:v0.4"
    ports:
      - "33422:22"
      - "33430-33459:33430-33459/tcp"
      - "33460-33499:33460-33499/udp"
    volumes:
      - ./dev014/:/work
      - ./tips:/etc/motd

    privileged: true
    restart: "always"

    networks:
      app_net:
        ipv4_address: 172.16.239.14
        ipv6_address: 2001:3984:3999::14
    stdin_open: true

  dev015:
    image: "ubuntu-dev:v0.4"
    ports:
      - "33522:22"
      - "33530-33559:33530-33559/tcp"
      - "33560-33599:33560-33599/udp"
    volumes:
      - ./dev015/:/work
      - ./tips:/etc/motd

    privileged: true
    restart: "always"

    stdin_open: true


  dev016:
    image: "ubuntu-dev:v0.4"
    ports:
      - "33622:22"
      - "33630-33659:33630-33659/tcp"
      - "33660-33699:33660-33699/udp"
    volumes:
      - ./dev016/:/work
      - ./tips:/etc/motd

    privileged: true
    restart: "always"

    stdin_open: true


  dev019:
    image: "ubuntu-dev:v0.4"
    ports:
      - "33922:22"
      - "33930-33959:33930-33959/tcp"
      - "33960-33999:33960-33999/udp"

    volumes:
      - ./dev019/:/work
      - ./tips:/etc/motd

    networks:
      app_net:
        ipv4_address: 172.16.239.11
        ipv6_address: 2001:3984:3999::11

    privileged: true
    restart: "always"

    # network_mode: "host"

    stdin_open: true

networks:
  app_net:
    driver: bridge
    enable_ipv6: true
    ipam:
      driver: default
      config:
        - subnet: 172.16.239.0/24
          gateway: 172.16.239.1
        - subnet: 2001:3984:3999::/64
          gateway: 2001:3984:3999::1

```

### startup.sh

```shell
#!/bin/bash
set -e
# PID_SUB=$!
OPT=$@

service ssh start

apt update > /dev/null 2>&1

if [ -z "${OPT}" ]; then
    # wait $PID_SUB
    echo "no command ,Executing bash"
    bash
else
    # unknown option ==> call command
    echo -e "\n\n------------------ EXECUTE COMMAND ------------------"
    echo "Executing command: '${OPT}'"
    ${OPT}

    # 多个命令可以通过command： source 脚本
    # exec "$@"

    echo "start success , Executing bash"
    bash
    echo "end"
fi

```

 tips

```
version:0.4
```

### soc_dev.yml

```shell
version: "2"
services:
  dev001:
    image: "ubuntu-dev:v0.3"
    ports:
      - "3122:22"
      - "3130-3159:3130-3159/tcp"
      - "3160-3199:3160-3199/udp"
    volumes:
      - ./dev001/:/work
      - ./tips:/etc/motd

    privileged: true
    restart: "always"

    networks:
      app_net:
        ipv4_address: 172.16.238.11
        ipv6_address: 2001:3984:3989::11
    stdin_open: true


  dev003:
    image: "ubuntu-dev:v0.3"
    ports:
      - "3322:22"
      - "3330-3359:3330-3359/tcp"
      - "3360-3399:3360-3399/udp"
    volumes:
      - ./dev003/:/work
      - ./tips:/etc/motd

    privileged: true
    restart: "always"

    stdin_open: true

  dev006:
    image: "ubuntu-dev:v0.3"
    ports:
      - "3622:22"
      - "3630-3659:3630-3659/tcp"
      - "3660-3699:3660-3699/udp"
    volumes:
      - ./dev006/:/work
      - ./tips:/etc/motd

    privileged: true
    restart: "always"

    stdin_open: true



networks:
  app_net:
    driver: bridge
    enable_ipv6: true
    ipam:
      driver: default
      config:
        - subnet: 172.16.238.0/24
          gateway: 172.16.238.1
        - subnet: 2001:3984:3989::/64
          gateway: 2001:3984:3989::1
```

