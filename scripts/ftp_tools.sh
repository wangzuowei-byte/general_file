#!/bin/bash

CURRENT_PATH=$(readlink -f "$(dirname "$0")")

source ${CURRENT_PATH}/tools/.config

RED=31
GRE=32
YEL=33
BLU=34

VERSION="v1.0"

MIDDLEWARE_DIR="/third_party/middleware_sdk"
ESR_DIR="/third_party/ESR_SDK"
CLEAN_FILE_NAME=""


function echo_str()
{
    local colour=$1
    local str=$2
    echo -e "\033[${colour}m""${str}""\033[0m"
    return 0
}


function chk_env()
{
    SF_NAME=$(which ftp)
    if [ -z "$SF_NAME" ]; then
        apt-get install ftp lftp -y
    fi

    SF_NAME=$(which jf)
    if [ -z "$SF_NAME" ]; then
        curl -fL https://install-cli.jfrog.io | sh
        SF_NAME=$(which jf)
        rm -rf /usr/bin/jfrog
        ln -sf ${SF_NAME} /usr/bin/jfrog
        jfrog -v
    fi



    return 0
}


function jfr_put()
{
    local platform=$1
    local sdk_version=$2
    local sdk_name=$3

    cd ${CURRENT_PATH}/download/


    if [ ! -e ${sdk_name}_sdk_${sdk_version}_${platform}.tar.gz ]; then 
        echo "文件不存在: ${sdk_name}_sdk_${sdk_version}_${platform}.tar.gz"
        exit 1
    fi 

    read -p "User Name: " JFROG_USER
    read -s -p "Passwd: " JFROG_PASS
    echo ""  

    jfrog rt u --flat  --url "https://jfrog.ecarxgroup.com/artifactory" \
    --user "$JFROG_USER" --password="$JFROG_PASS" ${sdk_name}_sdk_${sdk_version}_${platform}.tar.gz \
    thirdparty-generic-federated/A1000le/C229CN_PAS/library/ECARX/a1000_linux_esr_sdk/${sdk_version}/

    touch latest && jfrog rt u --flat  --url "https://jfrog.ecarxgroup.com/artifactory" \
    --user "$JFROG_USER" --password="$JFROG_PASS"  \
    --target-props="jfrogurl=thirdparty-generic-federated/A1000le/C229CN_PAS/library/ECARX/a1000_linux_esr_sdk/${sdk_version}/" \
    latest thirdparty-generic-federated/A1000le/C229CN_PAS/library/ECARX/a1000_linux_esr_sdk/


    cd -

    return 0
}

function ftp_get_bk()
{
    local platform=$1
    local remote_path=$2
    local download_path=$3
    local plat_mask=""


    if [ -e file_list.txt ];then
        rm -rf file_list.txt
    fi 

    if [ -n "$platform" ]; then
        plat_mask="| grep "$platform""
    fi

#    eval "ftp -inv ${FILE_SERVER_ADDR} <<EOF | grep -E '^-|^d' | awk '{print \$NF}' "$plat_mask" > file_list.txt
    eval "ftp -inv ${FILE_SERVER_ADDR} <<EOF | grep -E '^-|^d' | awk '{printf \"%-12s %-3s %-5s %s\\n\", \$5, \$6, \$7, \$9}' "$plat_mask" > file_list.txt    
    user ${FILE_SERVER_NAME} ${FILE_SERVER_PASSWORD}
    cd $remote_path
    ls -l
    bye
EOF"

    echo "📂 Remote File List:"
    cat -n file_list.txt
    echo ""
    read -p "Please Enter The File Number You Want to Download: " FILE_INDEX
    FILE_NAME=$(sed -n "${FILE_INDEX}p" file_list.txt)
    CLEAN_FILE_NAME=$(echo $FILE_NAME | awk '{print $NF}')

    if [ -n "$CLEAN_FILE_NAME" ]; then
        echo "📥 Start Download: ${CLEAN_FILE_NAME} to ${download_path}/"
        ftp -inv ${FILE_SERVER_ADDR} <<EOF
        user $FILE_SERVER_NAME $FILE_SERVER_PASSWORD
        cd $remote_path
        lcd ${download_path}
        get ${CLEAN_FILE_NAME}
        bye
EOF
        echo_str ${GRE} "✅ File $CLEAN_FILE_NAME Download OKAY!!!"
    else
        echo_str ${RED} "❌ 无效的文件编号！"
    fi

    rm -f file_list.txt

    return 0
}

function ftp_get() {
    local platform=$1
    local remote_path=$2
    local download_path=$3
    local file_list="/tmp/file_list.txt"

    # 清空临时文件
    if [ -e "$file_list" ]; then
        rm -f "$file_list"
    fi

    # 获取远程文件列表
    echo "📂 正在获取远程文件列表..."
    curl -u jica:jica "ftp://10.43.60.90${remote_path}/" --list-only > "$file_list"

    if [ $? -ne 0 ]; then
        echo "❌ 获取文件列表失败，请检查 FTP 服务器配置！"
        return 1
    fi

    # 过滤平台相关文件（如果需要）
    if [ -n "$platform" ]; then
        grep "$platform" "$file_list" > "${file_list}.filtered"
        mv "${file_list}.filtered" "$file_list"
    fi

    # 显示文件列表
    echo "📂 远程文件列表："
    cat -n "$file_list"
    echo ""

    # 选择要下载的文件
    read -p "请输入要下载的文件编号: " FILE_INDEX
    CLEAN_FILE_NAME=$(sed -n "${FILE_INDEX}p" "$file_list")

    if [ -z "$CLEAN_FILE_NAME" ]; then
        echo "❌ 无效的文件编号！"
        return 1
    fi

    # 下载文件
    echo "📥 正在下载文件: ${CLEAN_FILE_NAME}..."
    curl -u jica:jica "ftp://10.43.60.90${remote_path}/${CLEAN_FILE_NAME}" -o "${download_path}/${CLEAN_FILE_NAME}"

    if [ $? -eq 0 ]; then
        echo "✅ 文件下载成功: ${download_path}/${CLEAN_FILE_NAME}"
    else
        echo "❌ 文件下载失败！"
    fi

    # 清理临时文件
    rm -f "$file_list"

    return 0
}

function ftp_put()
{
    local platform=$1
    local remote_path=$2
    local sdk_name=$3
    local sdk_version=$4

    cd ${CURRENT_PATH}/download/

    if [ ! -e ${sdk_name}_sdk_${sdk_version}_${platform}.tar.gz ]; then 
        echo "文件不存在：${sdk_name}_sdk_${sdk_version}_${platform}.tar.gz"
        exit 1
    fi

    echo "📤 Start Upload: ${sdk_name}_sdk_${sdk_version}_${platform}.tar.gz to ${remote_path}"
    #curl -T ${sdk_name}_sdk_${sdk_version}_${platform}.tar.gz ftp://${FILE_SERVER_NAME}:${FILE_SERVER_PASSWORD}@${FILE_SERVER_ADDR}${remote_path}

    ftp -inv ${FILE_SERVER_ADDR} <<EOF
    user ${FILE_SERVER_NAME} ${FILE_SERVER_PASSWORD}
    cd ${remote_path}
    put ./${sdk_name}_sdk_${sdk_version}_${platform}.tar.gz
    bye
EOF
    cd -

    return 0
}

SDK_Deploy()
{
    local platform=$1
    local remote_path=$2
    local sdk_name=$3

    ftp_get "$platform" ${remote_path} ${CURRENT_PATH}/download

    cd ${CURRENT_PATH}/${platform}/

    if [ ! -d ${sdk_name} ]; then
        mkdir ${sdk_name}
    fi
    
    rm -rf ./${sdk_name}/*

    tar -xf ${CURRENT_PATH}/download/${CLEAN_FILE_NAME} -C ${sdk_name}

    cd -

    return 0
}

function release_tar_pack()
{
    local platform=$1
    local version=$2
    local sdk_name=$3

    cd ${CURRENT_PATH}/download/

    if [ -e ${sdk_name}_sdk_${version}_${platform}.tar.gz ]; then
        rm -rf ${sdk_name}_sdk_${version}_${platform}.tar.gz
    fi

    if [ ! -d ${CURRENT_PATH}/${platform}/${sdk_name} ]; then
        echo_str ${RED} "❌ 无效得打包目录！"
    fi

    echo_str ${YEL} "pack $sdk_name tar"
    tar -zcf ${sdk_name}_sdk_${version}_${platform}.tar.gz \
    -C ${CURRENT_PATH}/${platform}/${sdk_name} ./

    cd -

    return 0
}

FTP_Releae()
{
    local platform=$1
    local remote_path=$2
    local sdk_name=$3

    local version_file="${CURRENT_PATH}/${platform}/${sdk_name}/fc_linux_pack/version_info.csv"

    if [ -e ${version_file} ]; then
        sdk_version=$(awk -F ', *' '/SDK Version/ {print $2}' ${version_file})
        sed -i "s/^Pack Time,.*/Pack Time, $pack_time/" ${version_file}

    else

        echo -e "\033[34m请输入版本号（如：v1.0.0.1）： \033[0m"
        

        read -r sdk_version
        
        # 再次检查是否为空（防止用户直接回车）
        while [ -z "$sdk_version" ]; do
            echo -e "\033[33m版本号不能为空，请重新输入：\033[0m"
            read -r sdk_version
        done

    fi 

    echo "SDK Version: $sdk_version"

    release_tar_pack ${platform} ${sdk_version} ${sdk_name}

    ftp_put ${platform} ${remote_path} ${sdk_name} ${sdk_version}
    

    return 0
}

function Jfr_UpLoad()
{
    local platform=$1

    local sdk_version=""
    local pack_time=$(date +"%a %b %d %T %Z %Y")
    local version_file="${CURRENT_PATH}/${platform}/esr/fc_linux_pack/version_info.csv"

    sdk_version=$(awk -F ', *' '/SDK Version/ {print $2}' ${version_file})
    sed -i "s/^Pack Time,.*/Pack Time, $pack_time/" ${version_file}

    echo "SDK Version: $sdk_version"

    release_tar_pack ${platform} ${sdk_version} "esr"
    jfr_put ${platform} ${sdk_version} "esr"

    return 0
}

function FTP_DoLoad()
{
    local platform=$1

    echo_str ${YEL} "请选择对应的功能进行安装（不区分大小写）"
    echo_str ${YEL} "----------------------------------------"
    echo_str ${BLU} "1.  📥ESR        SDK"
    echo_str ${BLU} "2.  📥Middleware SDK"

    echo_str ${RED} "Q.   Exit"
    echo_str ${YEL} "----------------------------------------"

    read KEY_VAL

    case ${KEY_VAL} in

    1)      SDK_Deploy  ${platform} ${ESR_DIR} "esr" ;;
    2)      SDK_Deploy  ${platform} ${MIDDLEWARE_DIR} "L_Middleware";;

    [Qq])       exit 0 ;;
    *)          echo -e "\033[31m[ERROR] Input key is error: $KEY_VAL. \033[0m" 
                exit 1;;

    esac

    return 0
}

function FTP_UpLoad()
{
    local platform=$1

    echo_str ${YEL} "请选择对应的功能进行安装（不区分大小写）"
    echo_str ${YEL} "----------------------------------------"
    echo_str ${BLU} "1.  📤ESR        SDK "
    echo_str ${BLU} "2.  📤Middleware SDK "

    echo_str ${RED} "Q.   Exit"
    echo_str ${YEL} "----------------------------------------"

    read KEY_VAL

    case ${KEY_VAL} in

    1)      FTP_Releae  ${platform} ${ESR_DIR} "esr";;
    2)      FTP_Releae  ${platform} ${MIDDLEWARE_DIR} "L_Middleware";;

    [Qq])       exit 0 ;;
    *)          echo -e "\033[31m[ERROR] Input key is error: $KEY_VAL. \033[0m" 
                exit 1;;

    esac

    return 0
}


function menu_install()
{
    local platform=$1
    local version=$2

    echo_str ${YEL} "请选择对应的功能进行安装（不区分大小写）"
    echo_str ${YEL} "----------------------------------------"
    echo_str ${BLU} "A1.  📥x86_linux          FTP SDK 下载"
    echo_str ${BLU} "A2.  📤x86_linux          FTP SDK 上载"
    echo_str ${GRE} "A3.  📤x86_linux          JFR SDK 上载"
    echo_str ${BLU} ""
    echo_str ${BLU} "B1.  📥a1000_linux        FTP SDK 下载"
    echo_str ${BLU} "B2.  📤a1000_linux        FTP SDK 上载"
    echo_str ${GRE} "B3.  📤a1000_linux        JFR SDK 上载"
    echo_str ${BLU} ""
    echo_str ${BLU} "C1.  📥c1200_linux        FTP SDK 下载"
    echo_str ${BLU} "C2.  📤c1200_linux        FTP SDK 上载"
    echo_str ${GRE} "C3.  📤c1200_linux        JFR SDK 上载"
    echo_str ${BLU} ""
    echo_str ${BLU} "D1.  📥e245_linux         FTP SDK 下载"
    echo_str ${BLU} "D2.  📤e245_linux         FTP SDK 上载"
    echo_str ${GRE} "D3.  📤e245_linux         JFR SDK 上载"
    echo_str ${BLU} ""
    echo_str ${RED} "Q.   Exit"
    echo_str ${YEL} "----------------------------------------"

    read KEY_VAL

    case ${KEY_VAL} in

    [Aa]1)      FTP_DoLoad        x86_64;;
    [Aa]2)      FTP_UpLoad        x86_64;;
    [Aa]3)      Jfr_UpLoad        x86_64;;

    [Bb]1)      FTP_DoLoad        a1000_linux;;
    [Bb]2)      FTP_UpLoad        a1000_linux;;
    [Bb]3)      Jfr_UpLoad        a1000_linux;;

    [Cc]1)      FTP_DoLoad        c1200_linux;;
    [Cc]2)      FTP_UpLoad        c1200_linux;;
    [Cc]3)      Jfr_UpLoad        c1200_linux;;

    [Dd]1)      FTP_DoLoad        e245_linux;;
    [Dd]2)      FTP_UpLoad        e245_linux;;
    [Dd]3)      Jfr_UpLoad        e245_linux;;

    [Qq])       exit 0 ;;
    *)          echo -e "\033[31m[ERROR] Input key is error: $KEY_VAL. \033[0m" 
                exit 1;;

    esac

    
}

chk_env

if [ -n "$1" ]; then 
    VERSION=$1
fi
echo "VERSION=$VERSION"
menu_install 