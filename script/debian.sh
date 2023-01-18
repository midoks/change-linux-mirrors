#!/bin/bash

## Author: midoks
## Modified: 2023-01-18
## License: Apache License
## Github: https://github.com/midoks/change-linux-mirrors

ARCH=$(uname -m)

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

SYSTEM_NAME=debian
SYSTEM_VERSION_NUMBER=$(cat /etc/os-release | grep -E "VERSION_ID=" | awk -F '=' '{print$2}' | sed "s/[\'\"]//g")


SOURCE_LIST[0]=deb.debian.org
SOURCE_LIST[1]=mirrors.linode.com
SOURCE_LIST_LEN=${#SOURCE_LIST[*]}

SOURCE_LIST_LANG[0]=Debian官方
SOURCE_LIST_LANG[1]=LINODE

## 系统判定变量
function EnvJudgment() {
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

    SYNC_TXT="更新"
}

## 关闭防火墙和SELinux
function CloseFirewall() {
    if [[ $(systemctl is-active firewalld) == "active" ]]; then
        CHOICE_C=$(echo -e "\n${BOLD}└─ 是否关闭防火墙和 SELinux ? [Y/n] ${PLAIN}")
        read -p "${CHOICE_C}" INPUT
        [ -z ${INPUT} ] && INPUT=Y
        case $INPUT in
        [Yy] | [Yy][Ee][Ss])
            systemctl disable --now firewalld >/dev/null 2>&1
            [ -s $SelinuxConfig ] && sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" $SelinuxConfig && setenforce 0 >/dev/null 2>&1
            ;;
        [Nn] | [Nn][Oo]) ;;
        *)
            echo -e "\n$WARN 输入错误，默认不关闭！"
            ;;
        esac
    fi
}

## 选择官方源
function ChooseMirrors() {
    clear
    echo -e '+---------------------------------------------------+'
    echo -e '|                                                   |'
    echo -e '|   =============================================   |'
    echo -e '|                                                   |'
    echo -e '|       欢迎使用 Linux 一键更换系统软件源脚本       |'
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
    i=0
    for V in ${SOURCE_LIST[@]}; do
    i=`expr $i + 1`
	echo -e " ❖   ${SOURCE_LIST_LANG[$i]}              $i)"
	i=`expr $i + 1`
	done
    # echo -e ' ❖   Debian官方              1)'
    echo -e ''
    echo -e '#####################################################'
    echo -e ''
    echo -e "        运行环境  ${BLUE}${SYSTEM_NAME} ${SYSTEM_VERSION_NUMBER} ${SYSTEM_ARCH}${PLAIN}"
    echo -e "        系统时间  ${BLUE}$(date "+%Y-%m-%d %H:%M:%S")${PLAIN}"
    echo -e ''
    echo -e '#####################################################'
    CHOICE_A=$(echo -e "\n${BOLD}└─ 请选择并输入你想使用的软件源 [ 1-${SOURCE_LIST_LEN} ]：${PLAIN}")

    read -p "${CHOICE_A}" INPUT
    case $INPUT in
    1)
        SOURCE="deb.debian.org"
        ;;
    *)
        SOURCE="deb.debian.org"
        echo -e "\n$WARN 输入错误，将默认使用 ${BLUE}Debian官方${PLAIN} 作为源！"
        sleep 2s
        ;;
    esac

    CHOICE_A_TMP=$(echo -e "\n  ${BOLD}└─ 默认使用镜像站的公网地址，是否继续? [Y/n] ${PLAIN}")
    read -p "${CHOICE_A_TMP}" INPUT
    [ -z ${INPUT} ] && INPUT=Y
    case $INPUT in
    [Yy] | [Yy][Ee][Ss])
        SOURCE=${Extranet}
        ;;
    [Nn] | [Nn][Oo])
        SOURCE=${Intranet}
        echo -e "\n  $WARN 已切换至云计算厂商镜像站的内网访问地址，仅限对应厂商云服务器用户使用！"
        NOT_SUPPORT_HTTPS="True"
        ;;
    *)
        SOURCE=${Extranet}
        echo -e "\n$WARN 输入错误，默认使用公网地址！"
        ;;
    esac

       ## 选择同步软件源所使用的 WEB 协议（ HTTP：80 端口，HTTPS：443 端口）
    if [[ ${NOT_SUPPORT_HTTPS} == "True" ]]; then
        WEB_PROTOCOL="http"
    else
        CHOICE_E=$(echo -e "\n${BOLD}└─ 软件源是否使用 HTTP 协议? [Y/n] ${PLAIN}")
        read -p "${CHOICE_E}" INPUT
        [ -z ${INPUT} ] && INPUT=Y
        case $INPUT in
        [Yy] | [Yy][Ee][Ss])
            WEB_PROTOCOL="http"
            ;;
        [Nn] | [Nn][Oo])
            WEB_PROTOCOL="https"
            ;;
        *)
            echo -e "\n$WARN 输入错误，默认使用 HTTPS 协议！"
            WEB_PROTOCOL="https"
            ;;
        esac
    fi

    echo "${SYSTEM_JUDGMENT} = ${SYSTEM_CENTOS} -o ${SYSTEM_JUDGMENT} = ${SYSTEM_RHEL}"
}

function RunMain(){
	EnvJudgment
	ChooseMirrors
}

# 执行
RunMain