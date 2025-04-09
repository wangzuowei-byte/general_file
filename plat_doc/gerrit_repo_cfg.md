# 切换 gerrit repo 配置

## install repo

```shell
apt-get update
apt-get install git python3 curl

# 方法 1
curl https://mirrors.tuna.tsinghua.edu.cn/git/git-repo -o repo 
chmod a+x ./repo
mv ./repo /usr/local/bin

# 方法 2
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
echo 'export PATH=~/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
# 查看
repo --version
```



## Manifest

```shell
<?xml version="1.0" encoding="UTF-8"?>
<manifest>

  <remote name="gerrit_ecarx"
          fetch="ssh://gerrit.ecarxgroup.com:29418/"
          review="gerrit.ecarxgroup.com"/>

  <default remote="gerrit_ecarx" revision="pas_dev"/>

  <project name="spb/bsw_soc/system_design"
           path="pas_test/system_design"
           remote="gerrit_ecarx"
           revision="pas_dev"/>

  <project name="spb/bsw_soc/plat_l/designer_base_tools"
           path="pas_test/tools"
           remote="gerrit_ecarx"
           revision="pas_dev"/>

  <project name="spb/bsw_soc/plat_l/designer_base_app"
           path="pas_test/Bsw/app"
           remote="gerrit_ecarx"
           revision="pas_dev"/>

  <!-- Add other repositories if necessary -->
```

## cfg ssh

vim ~/.ssh/config 输入如下内容：

```shell
host gerrit.ecarxgroup.com
        port 29418
        user xxx
        PubkeyAcceptedKeyTypes +ssh-rsa
host gerrit-dl.ecarxgroup.com
        port 29418
        user xxx
        PubkeyAcceptedKeyTypes +ssh-rsa
Host ecarxgroup
        HostName gerrit.ecarxgroup.com
        user xxx
        port 29418
        PubkeyAcceptedKeyTypes +ssh-rsa
```

## 同步

```shell
# 查看仓库 git ls-remote URL
# e.g.
git ls-remote ssh://gerrit.ecarxgroup.com:29418/spb/bsw_soc/system_design
# 远程同步
repo init -u git@git.ecarxgroup.com:jica/adcu/bsw/bsw_soc/plat_l/bsw_reporoot.git -b dev -m pas_test.xml
# 本地同步
repo init -u . -b dev_gerrit -m pas_test.xml
repo sync -j8

# 全项目一键安装 hook：
repo forall -c 'scp -p -P 29418 zuowei.wang@gerrit.ecarxgroup.com:hooks/commit-msg .git/hooks/'
```

