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


DebianVersion=/etc/debian_version
DebianSourceList=/etc/apt/sources.list
DebianSourceListBackup=/etc/apt/sources.list.bak
DebianExtendListDir=/etc/apt/sources.list.d
DebianExtendListDirBackup=/etc/apt/sources.list.d.bak
SYSTEM_UBUNTU="Ubuntu"
SYSTEM_DEBIAN="Debian"


SYSTEM_NAME=debian
SYSTEM_VERSION_NUMBER=$(cat /etc/os-release | grep -E "VERSION_ID=" | awk -F '=' '{print$2}' | sed "s/[\'\"]//g")
DebianRelease="lsb_release"
SYSTEM_JUDGMENT=$(${DebianRelease} -is)
SYSTEM_VERSION=$(${DebianRelease} -cs)
SOURCE_BRANCH=${SYSTEM_JUDGMENT,,}


SOURCE_LIST[0]=deb.debian.org
SOURCE_LIST[1]=mirrors.linode.com
SOURCE_LIST[2]=mirrors.aliyun.com
SOURCE_LIST[3]=mirrors.cloud.aliyuncs.com
SOURCE_LIST[4]=mirrors.tencent.com
SOURCE_LIST[5]=mirrors.tencentyun.com
SOURCE_LIST[6]=repo.huaweicloud.com
SOURCE_LIST[7]=mirrors.myhuaweicloud.com

SOURCE_LIST_LANG[0]="Debian官方"
SOURCE_LIST_LANG[1]="LINODE"
SOURCE_LIST_LANG[2]="阿里云"
SOURCE_LIST_LANG[3]="阿里云[内网]"
SOURCE_LIST_LANG[4]="腾讯云"
SOURCE_LIST_LANG[5]="腾讯云[内网]"
SOURCE_LIST_LANG[6]="华为云"
SOURCE_LIST_LANG[7]="华为云[内网]"

SOURCE_LIST_LEN=${#SOURCE_LIST[*]}


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

    if [ ${SYSTEM_JUDGMENT} = ${SYSTEM_UBUNTU} ]; then
        if [ ${ARCH} = "x86_64" ] || [ ${ARCH} = "*i?86*" ]; then
            SOURCE_BRANCH=${SYSTEM_JUDGMENT,,}
        else
            SOURCE_BRANCH=ubuntu-ports
        fi
    else
        SOURCE_BRANCH=${SYSTEM_JUDGMENT,,}
    fi
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

function AutoSizeStr(){
	NAME_STR=$1
	NAME_NUM=$2

	# NAME_STR_LEN=${#NAME_STR}
	# NAME_NUM_LEN=${#NAME_NUM}

	# NAME_STR_LEN=`echo "$NAME_STR"|awk '{print length($0)}'`
	# NAME_NUM_LEN=`echo "$NAME_NUM"|awk '{print length($0)}'`

	NAME_STR_LEN=`echo "$NAME_STR" | wc -L`
	NAME_NUM_LEN=`echo "$NAME_NUM" | wc -L`

	fix_len=35
	remaining_len=`expr $fix_len - $NAME_STR_LEN - $NAME_NUM_LEN`
	FIX_SPACE=' '
	for ((ass_i=1;ass_i<=$remaining_len;ass_i++))
	do 
		FIX_SPACE="$FIX_SPACE "
	done
	echo -e " ❖   ${1}${FIX_SPACE}${2})"
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
    cm_i=0
    for V in ${SOURCE_LIST[@]}; do
    num=`expr $cm_i + 1`
	# echo -e " ❖   ${SOURCE_LIST_LANG[$cm_i]}              $num)"
	AutoSizeStr "${SOURCE_LIST_LANG[$cm_i]}" "$num"
	cm_i=`expr $cm_i + 1`
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
    if [ "$INPUT" == "" ];then
    	INPUT=1
    fi

    expr $INPUT "+" 10 &> /dev/null
	if [ "$?" -ne "0" ];then
		INPUT=1
		echo -e "\n$WARN 输入错误，将默认使用 ${BLUE}Debian官方${PLAIN} 作为源！"
        sleep 2s
	fi

	if [ "$INPUT" -lt "0" ];then
		INPUT=1
		TMP_INPUT=`expr $INPUT - 1`
		echo -e "\n$WARN 输入错误，将默认使用 ${BLUE}${SOURCE_LIST_LANG[$TMP_INPUT]}${PLAIN} 作为源！"
		sleep 2s
	fi

	if [ "$INPUT" -gt "${SOURCE_LIST_LEN}" ];then
		INPUT=${SOURCE_LIST_LEN}
		TMP_INPUT=`expr $INPUT - 1`
		echo -e "\n$WARN 输入错误，将默认使用 ${BLUE}${SOURCE_LIST_LANG[$TMP_INPUT]}${PLAIN} 作为源！"
		sleep 2s
	fi

    INPUT=`expr $INPUT - 1`
    SOURCE=${SOURCE_LIST[$INPUT]}

	echo -e "\n将使用 ${BLUE}${SOURCE_LIST_LANG[$INPUT]}${PLAIN} 作为源！"    

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
}

function BackupMirrors(){
	
    ## 判断 /etc/apt/sources.list.d 目录下是否存在文件
    [ -d $DebianExtendListDir ] && ls $DebianExtendListDir | grep *.list -q
    VERIFICATION_FILES=$?
    ## 判断 /etc/apt/sources.list.d.bak 目录下是否存在文件
    [ -d $DebianExtendListDirBackup ] && ls $DebianExtendListDirBackup | grep *.list -q
    VERIFICATION_BACKUPFILES=$?
   

    ## /etc/apt/sources.list
    if [ -s $DebianSourceList ]; then
        if [ -s $DebianSourceListBackup ]; then
            CHOICE_BACKUP1=$(echo -e "\n${BOLD}└─ 检测到系统存在已备份的 list 源文件，是否覆盖备份? [Y/n] ${PLAIN}")
            read -p "${CHOICE_BACKUP1}" INPUT
            [ -z ${INPUT} ] && INPUT=Y
            case $INPUT in
            [Yy] | [Yy][Ee][Ss])
                cp -rf $DebianSourceList $DebianSourceListBackup >/dev/null 2>&1
                ;;
            [Nn] | [Nn][Oo]) ;;
            *)
                echo -e "\n$WARN 输入错误，默认不覆盖！"
                ;;
            esac
        else
            cp -rf $DebianSourceList $DebianSourceListBackup >/dev/null 2>&1
            echo -e "\n$COMPLETE 已备份原有 list 源文件至 $DebianSourceListBackup"
            sleep 1s
        fi
    else
        [ -f $DebianSourceList ] || touch $DebianSourceList
        echo -e ''
    fi

    ## /etc/apt/sources.list.d
    if [ -d $DebianExtendListDir ] && [ ${VERIFICATION_FILES} -eq 0 ]; then
        if [ -d $DebianExtendListDirBackup ] && [ ${VERIFICATION_BACKUPFILES} -eq 0 ]; then
            CHOICE_BACKUP2=$(echo -e "\n${BOLD}└─ 检测到系统存在已备份的 list 第三方源文件，是否覆盖备份? [Y/n] ${PLAIN}")
            read -p "${CHOICE_BACKUP2}" INPUT
            [ -z ${INPUT} ] && INPUT=Y
            case $INPUT in
            [Yy] | [Yy][Ee][Ss])
                cp -rf $DebianExtendListDir/* $DebianExtendListDirBackup >/dev/null 2>&1
                ;;
            [Nn] | [Nn][Oo]) ;;
            *)
                echo -e "\n$WARN 输入错误，默认不覆盖！"
                ;;
            esac
        else
            [ -d $DebianExtendListDirBackup ] || mkdir -p $DebianExtendListDirBackup
            cp -rf $DebianExtendListDir/* $DebianExtendListDirBackup >/dev/null 2>&1
            echo -e "$COMPLETE 已备份原有 list 第三方源文件至 $DebianExtendListDirBackup 目录"
            sleep 1s
        fi
    fi
  
}

## 删除原有源
function RemoveOldMirrorsFiles() {
    [ -f $DebianSourceList ] && sed -i '1,$d' $DebianSourceList
}

## 更换国内源
function ChangeMirrors() {
    DebianMirrors
    echo -e "\n${WORKING} 开始更新软件源...\n"
    apt-get update -y
    VERIFICATION_SOURCESYNC=$?
    if [ ${VERIFICATION_SOURCESYNC} -eq 0 ]; then
        echo -e "\n$COMPLETE 软件源更换完毕"
    else
        echo -e "\n$ERROR 软件源${SYNC_TXT}失败\n"
        echo -e "请再次执行脚本并更换软件源后进行尝试，如果仍然${SYNC_TXT}失败那么可能由以下原因导致"
        echo -e "1. 网络问题：例如网络异常、网络间歇式中断、由地区影响的网络因素等"
        echo -e "2. 软件源问题：所选镜像站正在维护，或者出现罕见的少数文件同步出错导致软件源${SYNC_TXT}命令执行后返回错误状态"
        echo ''
        exit
    fi
}

## 更换基于 Debian 系 Linux 发行版的国内源
function DebianMirrors() {
    ## 修改国内源
    case ${SYSTEM_JUDGMENT} in
    Ubuntu)
        echo "## 默认禁用源码镜像以提高速度，如需启用请自行取消注释
deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION} main restricted universe multiverse
# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION} main restricted universe multiverse
deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-security main restricted universe multiverse
# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-security main restricted universe multiverse
deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-updates main restricted universe multiverse
# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-updates main restricted universe multiverse
deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-backports main restricted universe multiverse
# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-backports main restricted universe multiverse

## 预发布软件源（不建议启用）
# deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-proposed main restricted universe multiverse
# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-proposed main restricted universe multiverse" >>$DebianSourceList
        ;;
    Debian)
        echo "## 默认禁用源码镜像以提高速度，如需启用请自行取消注释
deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION} main contrib non-free
# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION} main contrib non-free
deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-updates main contrib non-free
# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-updates main contrib non-free
deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-backports main contrib non-free
# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH} ${SYSTEM_VERSION}-backports main contrib non-free
        
## 预发布软件源（不建议启用）
# deb ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH}-security ${SYSTEM_VERSION}/updates main contrib non-free
# deb-src ${WEB_PROTOCOL}://${SOURCE}/${SOURCE_BRANCH}-security ${SYSTEM_VERSION}/updates main contrib non-free" >>$DebianSourceList
        ;;
    esac
}

## 更新软件包
function UpgradeSoftware() {
    CHOICE_B=$(echo -e "\n${BOLD}└─ 是否更新软件包? [Y/n] ${PLAIN}")
    read -p "${CHOICE_B}" INPUT
    [ -z ${INPUT} ] && INPUT=Y
    case $INPUT in
    [Yy] | [Yy][Ee][Ss])
        echo -e ''
        apt-get upgrade -y
        CHOICE_C=$(echo -e "\n${BOLD}└─ 是否清理已下载的软件包缓存? [Y/n] ${PLAIN}")
        read -p "${CHOICE_C}" INPUT
        [ -z ${INPUT} ] && INPUT=Y
        case $INPUT in
        [Yy] | [Yy][Ee][Ss])
           
            apt-get autoremove -y >/dev/null 2>&1
            apt-get clean >/dev/null 2>&1
           
            echo -e "\n$COMPLETE 清理完毕"
            ;;
        [Nn] | [Nn][Oo]) ;;
        *)
            echo -e "\n$WARN 输入错误，默认不清理！"
            ;;
        esac
        ;;
    [Nn] | [Nn][Oo]) ;;
    *)
        echo -e "\n$WARN 输入错误，默认不更新！"
        ;;
    esac
}


function RunMain(){
	EnvJudgment
	ChooseMirrors
	BackupMirrors
	RemoveOldMirrorsFiles
    ChangeMirrors
    UpgradeSoftware

	# echo "SYSTEM_JUDGMENT:${SYSTEM_JUDGMENT}"
	# echo "SOURCE_BRANCH:${SOURCE_BRANCH}"
}

# 执行
RunMain