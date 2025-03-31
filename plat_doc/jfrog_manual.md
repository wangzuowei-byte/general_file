# jfrog_manual

## 安装部署

```shell
curl -fL https://install-cli.jfrog.io | sh
jf_path=$(which jf)
rm -rf /usr/bin/jfrog
ln -sf ${jf_path} /usr/bin/jfrog
jfrog -v
```

## 配置

```shell
jfrog c add
# 配置信息如下
# 注意使用前需要 web 登录一次 https://jfrog.ecarxgroup.com
Server ID: 你自己定义的名称，比如 ecarx-jfrog
JFrog Platform URL: https://jfrog.ecarxgroup.com
Artifactory URL: https://jfrog.ecarxgroup.com/artifactory
Username: zuowei.wang
Password/API Key: 

```

## 上传

```shell
# 上传SDK文件包到服务器 
# URL中的 注意版本号一致
jfrog rt u --flat  --url "https://jfrog.ecarxgroup.com/artifactory" --user "zuowei.wang" --password="xxx" esr_sdk_v1.0.0.2_a1000_linux.tar.gz thirdparty-generic-federated/A1000le/C229CN_PAS/library/ECARX/a1000_linux_esr_sdk/v1.0.0.2/

# 设置使用最新的文件包
touch latest && jfrog rt u --flat  --url "https://jfrog.ecarxgroup.com/artifactory" --user "zuowei.wang" --password="xxx"  --target-props="jfrogurl=thirdparty-generic-federated/A1000le/C229CN_PAS/library/ECARX/a1000_linux_esr_sdk/v1.0.0.2/" latest thirdparty-generic-federated/A1000le/C229CN_PAS/library/ECARX/a1000_linux_esr_sdk/
```

## 权限申请

https://ecarxgroup.feishu.cn/share/base/form/shrcn0WC2NaDlfY3Ao1HN0dPxag

上传权限 
https://jfrog.ecarxgroup.com/ui/repos/tree/General/thirdparty-generic-federated/A1000le/C229CN_PAS

