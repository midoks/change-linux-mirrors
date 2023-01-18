#!/bin/bash

## Author: midoks
## Modified: 2023-01-05
## License: Apache License
## Github: https://github.com/midoks/change-linux-mirrors

RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
PLAIN='\033[0m'
BOLD='\033[1m'
SUCCESS='[\033[32mOK\033[0m]'
COMPLETE='[\033[32mDONE\033[0m]'
WARN='[\033[33mWARN\033[0m]'
ERROR='[\033[31mERROR\033[0m]'
WORKING='[\033[34m*\033[0m]'

## 定义系统判定变量
DebianRelease="lsb_release"
ARCH=$(uname -m)
SYSTEM_DEBIAN="Debian"
SYSTEM_UBUNTU="Ubuntu"
SYSTEM_KALI="Kali"
SYSTEM_REDHAT="RedHat"
SYSTEM_RHEL="RedHat"
SYSTEM_CENTOS="CentOS"
SYSTEM_FEDORA="Fedora"

## 定义目录和文件
LinuxRelease=/etc/os-release
RedHatRelease=/etc/redhat-release
DebianVersion=/etc/debian_version
DebianSourceList=/etc/apt/sources.list
DebianSourceListBackup=/etc/apt/sources.list.bak
DebianExtendListDir=/etc/apt/sources.list.d
DebianExtendListDirBackup=/etc/apt/sources.list.d.bak
RedHatReposDir=/etc/yum.repos.d
RedHatReposDirBackup=/etc/yum.repos.d.bak
SelinuxConfig=/etc/selinux/config

function AuthorMessage() {
    echo -e "\n${GREEN} ------------ 脚本执行结束 ------------ ${PLAIN}\n"
    echo -e " \033[1;34m官方网站\033[0m https://github.com/midoks/change-linux-mirrors\n"
}

## 环境判定
function PermissionJudgment() {
    ## 权限判定
    if [ $UID -ne 0 ]; then
        echo -e "\n$ERROR 权限不足，请使用 Root 用户\n"
        exit
    fi
}

## 系统判定变量
function EnvJudgment() {
    ## 判定当前系统基于 Debian or RedHat
    if [ -s $RedHatRelease ]; then
        SYSTEM_FACTIONS=${SYSTEM_REDHAT}
    elif [ -s $DebianVersion ]; then
        SYSTEM_FACTIONS=${SYSTEM_DEBIAN}
    else
        echo -e "\n$ERROR 无法判断当前运行环境，请先确认本脚本针对当前操作系统是否适配\n"
        exit
    fi

    echo $SYSTEM_FACTIONS
    ## 判定系统名称、版本、版本号
    case ${SYSTEM_FACTIONS} in
    Debian)
        if [ ! -x /usr/bin/lsb_release ]; then
            apt-get install -y lsb-release
            if [ $? -eq 0 ]; then
                clear
            else
                echo -e "\n$ERROR lsb-release 软件包安装失败"
                echo -e "\n本脚本需要通过 lsb_release 指令判断系统类型，当前可能为精简安装的系统一般系统自带，请自行安装后重新执行脚本！\n"
                exit
            fi
        fi
        SYSTEM_JUDGMENT=$(${DebianRelease} -is)
        SYSTEM_VERSION=$(${DebianRelease} -cs)
        ;;
    RedHat)
        SYSTEM_JUDGMENT=$(cat $RedHatRelease | sed 's/ //g' | cut -c1-6)
        if [[ ${SYSTEM_JUDGMENT} = ${SYSTEM_CENTOS} || ${SYSTEM_JUDGMENT} = ${SYSTEM_RHEL} ]]; then
            CENTOS_VERSION=$(echo ${SYSTEM_VERSION_NUMBER} | cut -c1)
        else
            CENTOS_VERSION=""
        fi
        ;;
    esac

    ## 判定系统处理器架构
    case ${ARCH} in
    x86_64)
        SYSTEM_ARCH="x86_64"
        ;;
    aarch64)
        SYSTEM_ARCH="ARM64"
        ;;
    armv7l)
        SYSTEM_ARCH="ARMv7"
        ;;
    armv6l)
        SYSTEM_ARCH="ARMv6"
        ;;
    i686)
        SYSTEM_ARCH="x86_32"
        ;;
    *)
        SYSTEM_ARCH=${ARCH}
        ;;
    esac

    ## 定义软件源分支名称
    if [ ${SYSTEM_JUDGMENT} = ${SYSTEM_UBUNTU} ]; then
        if [ ${ARCH} = "x86_64" ] || [ ${ARCH} = "*i?86*" ]; then
            SOURCE_BRANCH=${SYSTEM_JUDGMENT,,}
        else
            SOURCE_BRANCH=ubuntu-ports
        fi
    elif [ ${SYSTEM_JUDGMENT} = ${SYSTEM_RHEL} ]; then
        SOURCE_BRANCH="centos"
    else
        SOURCE_BRANCH=${SYSTEM_JUDGMENT,,}
    fi
    ## 定义软件源同步/更新文字
    case ${SYSTEM_FACTIONS} in
    Debian)
        SYNC_TXT="更新"
        ;;
    RedHat)
        SYNC_TXT="同步"
        ;;
    esac

    echo $SOURCE_BRANCH
    echo $SYSTEM_JUDGMENT
    echo $SYNC_TXT
}

## 选择官方源
function ChooseMirrors() {
    clear
    echo -e '+---------------------------------------------------+'
    echo -e '|                                                   |'
    echo -e '|   =============================================   |'
    echo -e '|                                                   |'
    echo -e '|       欢迎使用 Linux 一键更换系统软件源脚本.          |'
    echo -e '|                                                   |'
    echo -e '|   =============================================   |'
    echo -e '|                                                   |'
    echo -e '+---------------------------------------------------+'
    echo -e ''
    echo -e '#####################################################'
    echo -e ''
    echo -e '            提供以下软件源可供选择：'
    echo -e ''
    echo -e '#####################################################'
    echo -e ''
    echo -e ' ❖   Debian官方              1)'
    echo -e ''
    echo -e '#####################################################'
    echo -e ''
    echo -e "        运行环境  ${BLUE}${SYSTEM_NAME} ${SYSTEM_VERSION_NUMBER} ${SYSTEM_ARCH}${PLAIN}"
    echo -e "        系统时间  ${BLUE}$(date "+%Y-%m-%d %H:%M:%S")${PLAIN}"
    echo -e ''
    echo -e '#####################################################'
    CHOICE_A=$(echo -e "\n${BOLD}└─ 请选择并输入你想使用的软件源 [ 1-13 ]：${PLAIN}")
}
function RunMain(){
	PermissionJudgment
    EnvJudgment
    ChooseMirrors

}

# 执行
RunMain