#! /bin/bash 

parameter1=$1

TOOLCHAINS_PATH="/opt/toolchains/"
TOOLCHAIN_PATH=${TOOLCHAINS_PATH}

ESR_SDK_VERSION=$1
PLATFORM_TYPE=$2

HOME_DIR=$(echo ~)
echo "USER:" $USER
echo "whoami:" `whoami`
echo "HOME_DIR:" $HOME_DIR
WORKDIR=$(pwd)
PACKAGE_PATH="${WORKDIR}/../pack/fc_linux_pack"
SDK_DIR="${WORKDIR}/sysroot"
VERSION_FILE=".version"
export CREATE_ARTIFACT=YES
export N_PROC=4
readonly TARGET_FILEPATH='./target_info.json'
readonly MODULES_DIR='./source/'

ESR_SDK_PACK_TAR_PATH=${WORKDIR}/../pack_tar/

echo "printing variables:"
echo "		CREATE_ARTIFACT = " $CREATE_ARTIFACT
echo "		N_PROC = " $N_PROC
echo "      SDK_DIR = " $SDK_DIR
echo "      WORKDIR = " $WORKDIR
echo "      LD_LIBRARY_PATH = " $LD_LIBRARY_PATH


function ftp_put()
{
    local file_path=$1
    local platform_name=$2
    local sdk_version=$3

    if [ ! -e ${file_path}/esr_sdk_${sdk_version}_${platform_name}.tar.gz ]; then 
        echo "文件不存在: esr_sdk_${sdk_version}_${platform_name}.tar.gz"
        exit 1
    fi

    curl -T ${file_path}/esr_sdk_${sdk_version}_${platform_name}.tar.gz ftp://jica:jica@10.43.60.90/third_party/ESR_SDK/

    return 0
}

jforg_put()
{
    local file_path=$1
    local platform_name=$2
    local sdk_version=$3

    cd ${file_path}/

    echo "file_path=$file_path esr_sdk_${sdk_version}_${platform_name}.tar.gz"
    if [ ! -e esr_sdk_${sdk_version}_${platform_name}.tar.gz ]; then 
        echo "文件不存在: esr_sdk_${sdk_version}_${platform_name}.tar.gz"
        exit 1
    fi 

    read -p "User Name: " JFROG_USER
    read -s -p "Passwd: " JFROG_PASS
    echo ""  

    jfrog rt u --flat  --url "https://jfrog.ecarxgroup.com/artifactory" \
    --user "$JFROG_USER" --password="$JFROG_PASS" esr_sdk_${sdk_version}_${platform_name}.tar.gz \
    thirdparty-generic-federated/A1000le/C229CN_PAS/library/ECARX/a1000_linux_esr_sdk/${sdk_version}/

    touch latest && jfrog rt u --flat  --url "https://jfrog.ecarxgroup.com/artifactory" \
    --user "$JFROG_USER" --password="$JFROG_PASS"  \
    --target-props="jfrogurl=thirdparty-generic-federated/A1000le/C229CN_PAS/library/ECARX/a1000_linux_esr_sdk/${sdk_version}/" \
    latest thirdparty-generic-federated/A1000le/C229CN_PAS/library/ECARX/a1000_linux_esr_sdk/

    cd -

    return 0
}

#set env variant
function help(){
    echo "----------Usage----------"
    echo "./build_source.sh a1000_linux              #compile a1000 app linux version"
    echo "./build_source.sh e245_linux               #compile a1000 app linux version"
    echo "./build_source.sh c1200_linux              #compile a1000 app linux version"
    echo "./build_source.sh c1200_linux-25           #compile a1000 app linux version"
    echo "./build_source.sh x86                      #compile x86 app linux version"
    echo "./build_source.sh clean                    #delete files and directories built by esr"
}


function version_log()
{
    local fc_path=$1
    local release_txt="${fc_path}/version_info.csv"
    local platform_name=$2
    local sw_version=$3

    local git_repository_name=""
    local git_repository_branch=""
    local git_repository_id=""

    cd ${fc_path}/../..
    
    git_repository_name=$(basename $(pwd))
    git_repository_id=$(git rev-parse HEAD)
    git_repository_branch=$(git rev-parse --abbrev-ref HEAD)

    echo "Build Time, $(date)"                        > ${release_txt}
    echo -e "Pack Time, $(date)"                    >> ${release_txt}
    echo -e "Platform Type :,${platform_name}"      >> ${release_txt}
    echo -e "SDK Version :,${sw_version}"           >> ${release_txt}


    echo -e "${git_repository_name}, ${git_repository_branch}, ${git_repository_id}" >> ${release_txt}

    echo -e "" >> ${release_txt}
    cd -

    return 0
}

function clean_fc()
{
    esr_path=$(pwd)
    echo "work dir: ${esr_path}"
    subdirs=$(find $esr_path/source -maxdepth 1 -type d -not -path "." | sed 's|^./||')
    for dir in $subdirs; do
        if [ -d "$dir/build" ]; then
            echo "remove directory: $dir/build"
            rm -rf $dir/build
        fi

        if [ -d "$dir/artifact_dir" ]; then
            echo "remove directory: $dir/artifact_dir"
            rm -rf $dir/artifact_dir
        fi
    done

    if [ -d "$esr_path/sysroot" ]; then
            echo "remove directory: $esr_path/sysroot"
            rm -rf $esr_path/sysroot
    fi

    if [ -d "$esr_path/../pack" ]; then
            echo "remove directory: $esr_path/../pack"
            rm -rf $esr_path/../pack
    fi

    echo -e "\033[32m[SUCCESS] Clean fc.\033[0m"
    return 0
}

function package_ap_module() {
    local workspace=$1
    local pack_path=$2

    cp -a ${workspace}/env*.sh                          ${pack_path}
    cp -r ${workspace}/opt                              ${pack_path}
    cp -r ${workspace}/usr                              ${pack_path}
    cp -r ${workspace}/../../third_part_lib/linux/acl   ${pack_path}

    mkdir -p ${pack_path}/scratch
}

function install_ap_module() {
    local install_path=$1/esr
    local pack_path=$2

    echo "install esr pack to ${TOOLCHAINS_PATH}"

    mkdir -p    ${install_path}
    rm -rf      ${install_path}/.
    cp -a       ${pack_path}        ${install_path}
}

##########################################################
# build module
# Globals:
#   Nothing
# Artuments:
#   Build index (position of build array)
# Retures:
#   0 if succeeded, non-zero on error.
##########################################################
function build_module() {
    local index=${1}
    local name=$(cat ${TARGET_FILEPATH} | jq -r ".build[${index}].name")
    local build_command=$(cat ${TARGET_FILEPATH} | jq -r ".build[${index}].build")
    local copy_artifacts_length=$(cat ${TARGET_FILEPATH} | jq -r ".build[${index}].copy_artifacts | length")

    if [ -z "${build_command}" ] || [ "${build_command}" = "null" ]; then
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> compiling ${name}"
        echo "Warning : Build command was not defined. Skip this module"
        return 0;
    fi

    pushd ${MODULES_DIR}/${name} > /dev/null
    (
        echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>> compiling ${name} (${build_command})"
        eval ${build_command}
    )
    popd > /dev/null

    echo "merging artifact_dir ..."
    for (( copy_index = 0; copy_index < ${copy_artifacts_length}; copy_index++ )); do
        source=$(cat ${TARGET_FILEPATH} | jq -r ".build[${index}].copy_artifacts[${copy_index}].source")
        destination=$(cat ${TARGET_FILEPATH} | jq -r ".build[${index}].copy_artifacts[${copy_index}].destination")

        source=${MODULES_DIR}/${name}/${source}
        destination=${SDK_DIR}/${destination}

        if [ ! -d ${destination} ]; then
            mkdir -p ${destination}
        fi

        echo "copy ${source} -> ${destination}"
        eval "cp -r ${source} ${destination}"
    done
    echo ""
}

function build_env_chk()
{
    local platform=$1
    local workspace=$2

    if [ -z "$platform" ]; then
        echo "input error"
        help
        exit -1
    fi

    if [[ $(whoami) == "root" ]]; then
        echo "local build, modifying USER to:" $USER
        HOME_DIR=/home/$USER
    else
        echo "root set to:" 'whoami'
    fi

    if [ ! -e ${TOOLCHAINS_PATH} ]; then 
        echo -e "\033[31m[ERROR] The toolchain symbolic link is missing. \033[0m"
        echo -e "\033[33m[WARNING] Please create a symbolic link /opt/toolchains pointing to the toolchain folder. \033[0m"
        exit 1
    fi

    echo "workspace=$workspace"

    case "$platform" in
        "a1000_linux"| "c1200_linux" | "c1200_linux-25")
            echo "build $platform"
            unset LD_LIBRAY_PATH
            TOOLCHAIN_PATH=${TOOLCHAINS_PATH}/${platform}
            if [ -d ${TOOLCHAIN_PATH}/esr ]; then 
                rm -rf ${TOOLCHAIN_PATH}/esr
            fi
         
            source ${TOOLCHAIN_PATH}/setup.sh

            unset CC
            unset CXX
            unset LD

            export CC="aarch64-bst-linux-gcc  --sysroot=$SYSROOT"
            export CXX="aarch64-bst-linux-g++  --sysroot=$SYSROOT"
            export LD="aarch64-bst-linux-ld  --sysroot=$SYSROOT"

            cp -a ${workspace}/sdk_build_env/env_a1000.sh ${workspace}/sdk_build_env/env.sh
            ;;

        "e245_linux")
            echo "build linux e245"
            unset LD_LIBRAY_PATH
            TOOLCHAIN_PATH=${TOOLCHAINS_PATH}/${platform}
            if [ -d ${TOOLCHAIN_PATH}/esr ]; then 
                rm -rf ${TOOLCHAIN_PATH}/esr
            fi
         
            source ${TOOLCHAIN_PATH}/setup.sh

            unset CC
            unset CXX
            unset LD

            export CC="aarch64-ecarx-linux-gcc  --sysroot=$SYSROOT"
            export CXX="aarch64-ecarx-linux-g++  --sysroot=$SYSROOT"
            export LD="aarch64-ecarx-linux-ld  --sysroot=$SYSROOT"

            cp -a ${workspace}/sdk_build_env/env_e245.sh ${workspace}/sdk_build_env/env.sh
            ;;

        "x86")
            echo "build linux x86"
            TOOLCHAIN_PATH=${TOOLCHAINS_PATH}/x86_64
            cp -a ${workspace}/sdk_build_env/env_x86.sh ${workspace}/sdk_build_env/env.sh
            ;;
        "clean")
            echo "delete files and directories built by esr"
            clean_fc
            exit 0
            ;;
        *)
            echo "input error"
            help
            exit -1
            ;;
    esac


    return 0
}


function sdk_env_ins()
{
    local source_path=$1
    local tag_path=$2

    mkdir -p ${tag_path}
    rm -rf ${tag_path}.tar.gz

    if [ -f ${VERSION_FILE} ]; then
        cp ${VERSION_FILE} ${tag_path}
    fi

    echo "prepare sdk build"

    mkdir -p ${tag_path}/usr/bin
    mkdir -p ${tag_path}/usr/lib
    mkdir -p ${tag_path}/opt/linux_toolchain
    mkdir -p ${tag_path}/opt/VRTE/RC4/Tools/vrte_fs_processor_cli/scripts
    mkdir -p ${tag_path}/opt/erte/lib/cmake/vrteb_fs
    mkdir -p ${tag_path}/opt/erte/lib/cmake/vrteb_fs/modules
    
    LINUX_TOOLCHAIN_FILE=linux_toolchain_file_ntox86_64
    VRTE_FS_CLI_PKG_NAME="esr-configurator-ap-cli-linux.gtk.x86_64.tar.gz"

    tar xzf ${source_path}/sdk_build_env/binaries/$VRTE_FS_CLI_PKG_NAME -C ${tag_path}/opt/VRTE/RC4/Tools/vrte_fs_processor_cli > /dev/null

    cp -r ${source_path}/sdk_build_env/VrteFsProcessorCli/ ${tag_path}/opt/erte/lib/cmake/
    cp  ${source_path}/sdk_build_env/vrteb_command_logger.cmake ${tag_path}/opt/erte/lib/cmake/vrteb_fs/
    cp  ${source_path}/sdk_build_env/vrteb_command_logger.cmake ${tag_path}/opt/erte/lib/cmake/vrteb_fs/modules/
    cp  ${source_path}/sdk_build_env/vrteb_fs_cli.cmake ${tag_path}/opt/erte/lib/cmake/vrteb_fs/
    cp  ${source_path}/sdk_build_env/vrteb_fs_cli.cmake ${tag_path}/opt/erte/lib/cmake/vrteb_fs/modules/
    cp  ${source_path}/sdk_build_env/vrteb_exec_tool.cmake ${tag_path}/opt/VRTE/RC4/Tools/vrte_fs_processor_cli/scripts/
    cp  ${source_path}/sdk_build_env/vrteb_modify_flags.cmake ${tag_path}/opt/erte/lib/cmake/vrteb_fs/
    cp  ${source_path}/sdk_build_env/vrteb_modify_flags.cmake ${tag_path}/opt/erte/lib/cmake/vrteb_fs/modules/

    cp ${source_path}/sdk_build_env/$LINUX_TOOLCHAIN_FILE ${tag_path}/opt/linux_toolchain/
    cp ${source_path}/sdk_build_env/binaries/smc-4.6.1-x86-linux64 ${tag_path}/usr/bin
    cp ${source_path}/sdk_build_env/env.sh ${tag_path}

    chmod a+x ${tag_path}/usr/bin/smc-4.6.1-x86-linux64


    echo "Sourcing env.sh"
    source ${SDK_DIR}/env.sh
    cat ${SDK_DIR}/opt/linux_toolchain/linux_toolchain_file_ntox86_64
    readonly build_length=$(cat ${TARGET_FILEPATH} | jq '.build | length')
    for (( i = 0; i < ${build_length}; i++ )); do
        build_module ${i}
    done

    echo "creating ${PACKAGE_PATH}"
    if [ ! -d "$BUILD_PATH" ]; then
        mkdir -p "$PACKAGE_PATH"
    fi

    return 0
}


#build_env_chk       ${parameter1}           ${WORKDIR}/..
#sdk_env_ins         ${WORKDIR}/..           ${SDK_DIR}

#package_ap_module   ${SDK_DIR}              ${PACKAGE_PATH}    
#install_ap_module   ${TOOLCHAIN_PATH}       ${PACKAGE_PATH}

function sdk_build_install()
{
    local tar_path=$1
    local platform_name=$2

    if [ -z "$ESR_SDK_VERSION" ]; then
        echo -e "\033[34mESR_SDK_VERSION 为空，请输入版本号（如：v1.0.0.1）： \033[0m"
        

        read -r ESR_SDK_VERSION
        
        # 再次检查是否为空（防止用户直接回车）
        while [ -z "$ESR_SDK_VERSION" ]; do
            echo -e "\033[33m版本号不能为空，请重新输入：\033[0m"
            read -r ESR_SDK_VERSION
        done
    fi

    sdk_env_ins         ${WORKDIR}/..           ${SDK_DIR}
    package_ap_module   ${SDK_DIR}              ${PACKAGE_PATH}    
    install_ap_module   ${TOOLCHAIN_PATH}       ${PACKAGE_PATH}
    
    version_log ${PACKAGE_PATH} ${platform_name} ${ESR_SDK_VERSION}
    
    echo "mkdir ${tar_path}"
    mkdir -p ${tar_path}

    cd ${tar_path}/
    if [ -e esr_sdk_${ESR_SDK_VERSION}_${platform_name}.tar.gz ]; then
        rm -rf esr_sdk_${ESR_SDK_VERSION}_${platform_name}.tar.gz
    fi
    echo "-zcf esr_sdk_${ESR_SDK_VERSION}_${platform_name}.tar.gz -C ${PACKAGE_PATH}/../ ./"
    tar -zcf esr_sdk_${ESR_SDK_VERSION}_${platform_name}.tar.gz -C ${PACKAGE_PATH}/../ ./

    cd -

    return 0
}


function x86_build()
{
    local platform_name=$1
    local tar_path=$2
    local workspace=$3

    echo "build linux x86"
    TOOLCHAIN_PATH=${TOOLCHAINS_PATH}/${platform_name}
    cp -a ${workspace}/sdk_build_env/env_x86.sh ${workspace}/sdk_build_env/env.sh

    sdk_build_install ${tar_path} ${platform_name} 

    return 0
}
function aarch64_e245_build()
{
    local platform_name=$1
    local tar_path=$2
    local workspace=$3

    echo "build linux e245"
    unset LD_LIBRAY_PATH
    TOOLCHAIN_PATH=${TOOLCHAINS_PATH}/${platform_name}
    if [ -d ${TOOLCHAIN_PATH}/esr ]; then 
        rm -rf ${TOOLCHAIN_PATH}/esr
    fi
    
    source ${TOOLCHAIN_PATH}/setup.sh

    unset CC
    unset CXX
    unset LD

    export CC="aarch64-ecarx-linux-gcc  --sysroot=$SYSROOT"
    export CXX="aarch64-ecarx-linux-g++  --sysroot=$SYSROOT"
    export LD="aarch64-ecarx-linux-ld  --sysroot=$SYSROOT"

    cp -a ${workspace}/sdk_build_env/env_e245.sh ${workspace}/sdk_build_env/env.sh

    sdk_build_install ${tar_path} ${platform_name} 

    return 0
}

function aarch64_linux_build()
{
    local platform_name=$1
    local tar_path=$2
    local workspace=$3

    echo "build linux aarch64"
    unset LD_LIBRAY_PATH
    TOOLCHAIN_PATH=${TOOLCHAINS_PATH}/${platform_name}
    if [ -d ${TOOLCHAIN_PATH}/esr ]; then 
        rm -rf ${TOOLCHAIN_PATH}/esr
    fi
    
    source ${TOOLCHAIN_PATH}/setup.sh

    unset CC
    unset CXX
    unset LD

    export CC="aarch64-bst-linux-gcc  --sysroot=$SYSROOT"
    export CXX="aarch64-bst-linux-g++  --sysroot=$SYSROOT"
    export LD="aarch64-bst-linux-ld  --sysroot=$SYSROOT"

    cp -a ${workspace}/sdk_build_env/env_a1000.sh ${workspace}/sdk_build_env/env.sh

    sdk_build_install ${tar_path} ${platform_name} 

    return 0
}

function distclean_buid()
{
    clean_fc
    return 0
}

function install_env()
{
    apt-get install -y jq

    curl -fL https://install-cli.jfrog.io | sh
    jf_path=$(which jf)
    rm -rf /usr/bin/jfrog
    ln -sf ${jf_path} /usr/bin/jfrog
    jfrog -v
    
    return 0
}

function ftp_upload_pack()
{
    local file_path=$1

    echo -e "\033[34m"
    echo -e "----------------------------------------"
    echo -e "1. upload x86"
    echo -e "2. upload a1000"
    echo -e "3. upload c1200"
    echo -e "4. upload e245"
    echo -e "0. Exit"
    echo -e "----------------------------------------"
    echo -e "\033[0m"

    read KEY_VAL

    case ${KEY_VAL} in
    1)  platform="x86_64" ;;
    2)  platform="a1000_linux" ;;
    3)  platform="c1200_linux" ;;
    4)  platform="e245_linux" ;;
                   
    0)  exit 0 ;;
    *)  echo -e "\033[31m[ERROR] Input key is error. \033[0m";;
    esac

    files=($(ls "$file_path" | grep "^esr_sdk_.*_${platform}\." 2>/dev/null))

    # 判断是否找到符合条件的文件
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "\033[31m[ERROR] 没有找到匹配平台 '${platform}' 的文件。\033[0m"
        exit 1
    fi

    # 让用户选择文件
    echo -e "\033[34m请选择要上传的文件：\033[0m"
    for i in "${!files[@]}"; do
        echo "$((i+1)). ${files[$i]}"
    done

    read -p "请输入文件编号: " choice


    if [[ ! $choice =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#files[@]})); then
        echo -e "\033[31m[ERROR] 无效的选择。\033[0m"
        exit 1
    fi


    selected_file="${files[$((choice-1))]}"
    echo -e "\033[32m[INFO] puload to jforg file name: $selected_file\033[0m"

    IFS='_' read -ra parts <<< "$selected_file"
    version="${parts[2]}"

    echo "version=$version"
    echo "platform=$platform"

    ftp_put "${file_path}" "${platform}" "${version}"

    return 0
}

function jforg_upload_pack()
{
    local file_path=$1

    echo -e "\033[34m"
    echo -e "----------------------------------------"
    echo -e "1. upload x86"
    echo -e "2. upload a1000"
    echo -e "3. upload c1200"
    echo -e "4. upload e245"
    echo -e "0. Exit"
    echo -e "----------------------------------------"
    echo -e "\033[0m"

    read KEY_VAL

    case ${KEY_VAL} in
    1)  platform="x86_64" ;;
    2)  platform="a1000_linux" ;;
    3)  platform="c1200_linux" ;;
    4)  platform="e245_linux" ;;
                   
    0)  exit 0 ;;
    *)  echo -e "\033[31m[ERROR] Input key is error. \033[0m";;
    esac

    files=($(ls "$file_path" | grep "^esr_sdk_.*_${platform}\." 2>/dev/null))

    # 判断是否找到符合条件的文件
    if [ ${#files[@]} -eq 0 ]; then
        echo -e "\033[31m[ERROR] 没有找到匹配平台 '${platform}' 的文件。\033[0m"
        exit 1
    fi

    # 让用户选择文件
    echo -e "\033[34m请选择要上传的文件：\033[0m"
    for i in "${!files[@]}"; do
        echo "$((i+1)). ${files[$i]}"
    done

    read -p "请输入文件编号: " choice


    if [[ ! $choice =~ ^[0-9]+$ ]] || ((choice < 1 || choice > ${#files[@]})); then
        echo -e "\033[31m[ERROR] 无效的选择。\033[0m"
        exit 1
    fi


    selected_file="${files[$((choice-1))]}"
    echo -e "\033[32m[INFO] puload to jforg file name: $selected_file\033[0m"

    IFS='_' read -ra parts <<< "$selected_file"
    version="${parts[2]}"

    echo "version=$version"
    echo "platform=$platform"

    jforg_put "${file_path}" "${platform}" "${version}"

    return 0
}

function do_once_menu()
{
echo "work=${WORKDIR}/.."
    if [[ $(whoami) == "root" ]]; then
        echo "local build, modifying USER to:" $USER
        HOME_DIR=/home/$USER
    else
        echo "root set to:" 'whoami'
    fi

    if [ ! -d ${TOOLCHAINS_PATH} ]; then 
        echo -e "\033[31m[ERROR] toolchain path LoSe!!! \033[0m"
        echo -e "\033[33m[Warrning] Configure the tool link path correctly... \033[0m"

        exit 1
    fi

    echo -e "\033[34m"
    echo -e "----------------------------------------"
    echo -e "1. x86_64     linux        build"
    echo -e "2. aarch64    a1000 linux  build"
    echo -e "3. aarch64    c1200 linux  build"
    echo -e "4. aarch64	   e245  linux  build"
    echo -e "7. Upload sdk to ftp server"
    echo -e "A. Upload sdk to jfrog server"
    echo -e "8. Install    env"
    echo -e "9. DISTCLEAN  Build"
    echo -e "0. Exit"
    echo -e "----------------------------------------"
    echo -e "\033[0m"

    read KEY_VAL

    case ${KEY_VAL} in
    1)  x86_build               x86_64      ${ESR_SDK_PACK_TAR_PATH} ${WORKDIR}/.. ;;
    2)  aarch64_linux_build     a1000_linux ${ESR_SDK_PACK_TAR_PATH} ${WORKDIR}/.. ;;
    3)  aarch64_linux_build     c1200_linux ${ESR_SDK_PACK_TAR_PATH} ${WORKDIR}/.. ;;
    4)  aarch64_e245_build      e245_linux  ${ESR_SDK_PACK_TAR_PATH} ${WORKDIR}/.. ;;
    7)  ftp_upload_pack                     ${ESR_SDK_PACK_TAR_PATH};;
    [Aa]) jforg_upload_pack                 ${ESR_SDK_PACK_TAR_PATH};;
    8)  install_env;;
    9)  distclean_buid          ;;
                   
    0)  exit 0 ;;
    *)  echo -e "\033[31m[ERROR] Input key is error. \033[0m";;
    esac

    return 0
}

function do_once_platform()
{
    local platform_name=$1
    
    case "$platform_name" in
        "a1000_linux")
            echo "build for platfor name: ${platform_name}"

            aarch64_linux_build     a1000_linux ${ESR_SDK_PACK_TAR_PATH} ${WORKDIR}/.. 
        ;;

        "e245_linux")
            echo "build for platfor name: ${platform_name}"

            aarch64_e245_build      e245_linux  ${ESR_SDK_PACK_TAR_PATH} ${WORKDIR}/.. 
        ;;
        "c1200_linux")
            echo "build for platfor name: ${platform_name}"

            aarch64_linux_build     c1200_linux ${ESR_SDK_PACK_TAR_PATH} ${WORKDIR}/.. 
        ;;

        "x86_64")
            echo "build for platfor name: ${platform_name}"

            x86_build               x86_64      ${ESR_SDK_PACK_TAR_PATH} ${WORKDIR}/.. 
            ;;
        "clean")
            distclean_buid
            ;;
        *)
        echo "paltform type error : ${platform_name}"
        help
        exit -1
        ;;
    esac

    return 0
}

echo "work=${WORKDIR}/.."

echo -e "\033[32mBuild Version: ${ESR_SDK_VERSION} \033[0m"

if [ -n "$PLATFORM_TYPE" ]; then

    do_once_platform "$PLATFORM_TYPE" "$ESR_SDK_VERSION"

    exit 0
fi
do_once_menu 
