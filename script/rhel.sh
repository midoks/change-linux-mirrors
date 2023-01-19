#!/bin/bash

## Author: midoks
## Modified: 2023-01-19
## License: Apache License
## Github: https://github.com/midoks/change-linux-mirrors
## mirror:https://www.debian.org/mirror/list

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

SYSTEM_KALI="Kali"
SYSTEM_REDHAT="RedHat"
SYSTEM_RHEL="RedHat"
SYSTEM_CENTOS="CentOS"
SYSTEM_FEDORA="Fedora"

LinuxRelease=/etc/os-release
RedHatRelease=/etc/redhat-release

RedHatReposDir=/etc/yum.repos.d
RedHatReposDirBackup=/etc/yum.repos.d.bak
SelinuxConfig=/etc/selinux/config

SYSTEM_NAME=$(cat $LinuxRelease | grep -E "^NAME=" | awk -F '=' '{print$2}' | sed "s/[\'\"]//g")
SYSTEM_VERSION_NUMBER=$(cat /etc/os-release | grep -E "VERSION_ID=" | awk -F '=' '{print$2}' | sed "s/[\'\"]//g")
SOURCE_BRANCH=${SYSTEM_JUDGMENT,,}


declare -A SOURCE_LIST

SOURCE_LIST["a_LINODE"]="mirrors.linode.com"
SOURCE_LIST["b_阿里云"]="mirrors.aliyun.com"
SOURCE_LIST["b_阿里云[内网]"]="mirrors.cloud.aliyuncs.com"
SOURCE_LIST["c_腾讯云"]="mirrors.tencent.com"
SOURCE_LIST["c_腾讯云[内网]"]="mirrors.tencentyun.com"
SOURCE_LIST["d_华为云"]="repo.huaweicloud.com"
SOURCE_LIST["d_华为云[内网]"]="mirrors.myhuaweicloud.com"
SOURCE_LIST["e_网易"]="mirrors.163.com"
SOURCE_LIST["e_搜狐"]="mirrors.sohu.com"
SOURCE_LIST["f_清华大学"]="mirrors.tuna.tsinghua.edu.cn"
SOURCE_LIST["f_中国科学技术大学"]="mirrors.ustc.edu.cn"

declare -A SOURCE_NO_EPEL
SOURCE_NO_EPEL['a_LINODE']=1


SOURCE_LIST_KEY_SORT_TMP=$(echo ${!SOURCE_LIST[@]} | tr ' ' '\n' | sort -n)
SOURCE_LIST_KEY=(${SOURCE_LIST_KEY_SORT_TMP//'\n'/})
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

    SYSTEM_JUDGMENT=$(cat $RedHatRelease | sed 's/ //g' | cut -c1-6)
    if [[ ${SYSTEM_JUDGMENT} = ${SYSTEM_CENTOS} || ${SYSTEM_JUDGMENT} = ${SYSTEM_RHEL} ]]; then
        CENTOS_VERSION=$(echo ${SYSTEM_VERSION_NUMBER} | cut -c1)
    else
        CENTOS_VERSION=""
    fi
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
    for V in ${SOURCE_LIST_KEY[@]}; do
    num=`expr $cm_i + 1`
	AutoSizeStr "${V:2}" "$num"
	cm_i=`expr $cm_i + 1`
	done
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
		TMP_INPUT=`expr $INPUT - 1`
		INPUT_KEY=${SOURCE_LIST_KEY[$TMP_INPUT]}
		echo -e "\n$WARN 输入非数字错误，将默认使用 ${BLUE}${INPUT_KEY:2}${PLAIN} 作为源！"
        sleep 2s
	fi

	if [ "$INPUT" -lt "0" ];then
		INPUT=1
		TMP_INPUT=`expr $INPUT - 1`
		INPUT_KEY=${SOURCE_LIST_KEY[$TMP_INPUT]}
		echo -e "\n$WARN 输入低于边界错误，将默认使用 ${BLUE}${INPUT_KEY:2}${PLAIN} 作为源！"
		sleep 2s
	fi

	if [ "$INPUT" -gt "${SOURCE_LIST_LEN}" ];then
		INPUT=${SOURCE_LIST_LEN}
		TMP_INPUT=`expr $INPUT - 1`
		INPUT_KEY=${SOURCE_LIST_KEY[$TMP_INPUT]}
		echo -e "\n$WARN 输入超出边界错误，将默认使用 ${BLUE}${INPUT_KEY:2}${PLAIN} 作为源！"
		sleep 2s
	fi

    INPUT=`expr $INPUT - 1`
    INPUT_KEY=${SOURCE_LIST_KEY[$INPUT]}
    SOURCE=${SOURCE_LIST[$INPUT_KEY]}

	echo -e "\n将使用 ${BLUE}${INPUT_KEY:2}${PLAIN} 作为源！"  

	## 更换基于 RHEL/CentOS 的 EPEL (Extra Packages for Enterprise Linux) 扩展国内源
    if [ ${SYSTEM_JUDGMENT} = ${SYSTEM_CENTOS} -o ${SYSTEM_JUDGMENT} = ${SYSTEM_RHEL} ]; then
        ## 判断是否已安装 EPEL 软件包
        rpm -qa | grep epel-release -q
        VERIFICATION_EPEL=$?
        ## 判断 /etc/yum.repos.d 目录下是否存在 epel 扩展 repo 源文件
        [ -d $RedHatReposDir ] && ls $RedHatReposDir | grep epel -q
        VERIFICATION_EPELFILES=$?
        ## 判断 /etc/yum.repos.d.bak 目录下是否存在 epel 扩展 repo 源文件
        [ -d $RedHatReposDirBackup ] && ls $RedHatReposDirBackup | grep epel -q
        VERIFICATION_EPELBACKUPFILES=$?


        IS_NO_EPEL=${SOURCE_NO_EPEL[$INPUT_KEY]}
        if [ "$IS_NO_EPEL" == "1" ];then
        	echo -e "\n${IS_NO_EPEL}----2" 
        	echo -e "\n${INPUT_KEY:2}源不支持EPEL！"
        	rm -rf $RedHatReposDir/epel.repo
        	EPEL_INSTALL="False"
        else
        	echo -e "\n${IS_NO_EPEL}----1" 
        	if [ ${VERIFICATION_EPEL} -eq 0 ]; then
	            CHOICE_D=$(echo -e "\n  ${BOLD}└─ 检测到系统已安装 EPEL 扩展源，是否替换/覆盖为国内源? [Y/n] ${PLAIN}")
	        else
	            CHOICE_D=$(echo -e "\n  ${BOLD}└─ 是否安装 EPEL 扩展源? [Y/n] ${PLAIN}")
	        fi
	        read -p "${CHOICE_D}" INPUT
	        [ -z ${INPUT} ] && INPUT=Y
	        case $INPUT in
	        [Yy] | [Yy][Ee][Ss])
	            EPEL_INSTALL="True"
	            ;;
	        [Nn] | [Nn][Oo])
	            EPEL_INSTALL="False"
	            ;;
	        *)
	            echo -e "\n  $WARN 输入错误，默认不更换！"
	            EPEL_INSTALL="False"
	            ;;
	        esac
        fi        
    fi  

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
	
    ## 判断 /etc/yum.repos.d 目录下是否存在文件
    [ -d $RedHatReposDir ] && ls $RedHatReposDir | grep repo -q
    VERIFICATION_FILES=$?
    ## 判断 /etc/yum.repos.d.bak 目录下是否存在文件
    [ -d $RedHatReposDirBackup ] && ls $RedHatReposDirBackup | grep repo -q
    VERIFICATION_BACKUPFILES=$?
   

    ## /etc/yum.repos.d
    if [ ${VERIFICATION_FILES} -eq 0 ]; then
        if [ -d $RedHatReposDirBackup ] && [ ${VERIFICATION_BACKUPFILES} -eq 0 ]; then
            CHOICE_BACKUP3=$(echo -e "\n${BOLD}└─ 检测到系统存在已备份的 repo 源文件，是否覆盖备份? [Y/n] ${PLAIN}")
            read -p "${CHOICE_BACKUP3}" INPUT
            [ -z ${INPUT} ] && INPUT=Y
            case $INPUT in
            [Yy] | [Yy][Ee][Ss])
                cp -rf $RedHatReposDir/* $RedHatReposDirBackup >/dev/null 2>&1
                ;;
            [Nn] | [Nn][Oo]) ;;
            *)
                echo -e "\n$WARN 输入错误，默认不覆盖！"
                ;;
            esac
        else
            [ -d $RedHatReposDirBackup ] || mkdir -p $RedHatReposDirBackup
            cp -rf $RedHatReposDir/* $RedHatReposDirBackup >/dev/null 2>&1
            echo -e "\n$COMPLETE 已备份原有 repo 源文件至 $RedHatReposDirBackup 目录"
            sleep 1s
        fi
    else
        [ -d $RedHatReposDir ] || mkdir -p $RedHatReposDir
    fi
}

## 删除原有源
function RemoveOldMirrorsFiles() {
    [ -f $DebianSourceList ] && sed -i '1,$d' $DebianSourceList
}

## 更换国内源
function ChangeMirrors() {
    RedHatMirrors
    SYNC_TXT="同步"
    echo -e "\n${WORKING} 开始${SYNC_TXT}软件源...\n"
    yum makecache -y
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

## 生成 CentOS 官方 repo 源文件
function CreateCentOSRepoFiles() {
    if [ ${CENTOS_VERSION} -eq "8" ]; then
        CentOS8_RepoFiles='CentOS-Linux-AppStream.repo CentOS-Linux-BaseOS.repo CentOS-Linux-ContinuousRelease.repo CentOS-Linux-Debuginfo.repo CentOS-Linux-Devel.repo CentOS-Linux-Extras.repo CentOS-Linux-FastTrack.repo CentOS-Linux-HighAvailability.repo CentOS-Linux-Media.repo CentOS-Linux-Plus.repo CentOS-Linux-PowerTools.repo CentOS-Linux-Sources.repo'
        for REPOS in $CentOS8_RepoFiles; do
            touch $REPOS
        done
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-AppStream.repo <<\EOF
# CentOS-Linux-AppStream.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[appstream]
name=CentOS Linux $releasever - AppStream
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=AppStream&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/AppStream/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-BaseOS.repo <<\EOF
# CentOS-Linux-BaseOS.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[baseos]
name=CentOS Linux $releasever - BaseOS
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=BaseOS&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/BaseOS/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-ContinuousRelease.repo <<\EOF
# CentOS-Linux-ContinuousRelease.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.
#
# The Continuous Release (CR) repository contains packages for the next minor
# release of CentOS Linux.  This repository only has content in the time period
# between an upstream release and the official CentOS Linux release.  These
# packages have not been fully tested yet and should be considered beta
# quality.  They are made available for people willing to test and provide
# feedback for the next release.

[cr]
name=CentOS Linux $releasever - ContinuousRelease
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=cr&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/cr/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-Debuginfo.repo <<\EOF
# CentOS-Linux-Debuginfo.repo
#
# All debug packages are merged into a single repo, split by basearch, and are
# not signed.

[debuginfo]
name=CentOS Linux $releasever - Debuginfo
baseurl=http://debuginfo.centos.org/$releasever/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-Devel.repo <<\EOF
# CentOS-Linux-Devel.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[devel]
name=CentOS Linux $releasever - Devel WARNING! FOR BUILDROOT USE ONLY!
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=Devel&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/Devel/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-Extras.repo <<\EOF
# CentOS-Linux-Extras.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[extras]
name=CentOS Linux $releasever - Extras
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/extras/$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-FastTrack.repo <<\EOF
# CentOS-Linux-FastTrack.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[fasttrack]
name=CentOS Linux $releasever - FastTrack
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=fasttrack&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/fasttrack/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-HighAvailability.repo <<\EOF
# CentOS-Linux-HighAvailability.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[ha]
name=CentOS Linux $releasever - HighAvailability
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=HighAvailability&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/HighAvailability/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-Media.repo <<\EOF
# CentOS-Linux-Media.repo
#
# You can use this repo to install items directly off the installation media.
# Verify your mount point matches one of the below file:// paths.

[media-baseos]
name=CentOS Linux $releasever - Media - BaseOS
baseurl=file:///media/CentOS/BaseOS
        file:///media/cdrom/BaseOS
        file:///media/cdrecorder/BaseOS
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[media-appstream]
name=CentOS Linux $releasever - Media - AppStream
baseurl=file:///media/CentOS/AppStream
        file:///media/cdrom/AppStream
        file:///media/cdrecorder/AppStream
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-Plus.repo <<\EOF
# CentOS-Linux-Plus.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[plus]
name=CentOS Linux $releasever - Plus
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/centosplus/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-PowerTools.repo <<\EOF
# CentOS-Linux-PowerTools.repo
#
# The mirrorlist system uses the connecting IP address of the client and the
# update status of each mirror to pick current mirrors that are geographically
# close to the client.  You should use this for CentOS updates unless you are
# manually picking other mirrors.
#
# If the mirrorlist does not work for you, you can try the commented out
# baseurl line instead.

[powertools]
name=CentOS Linux $releasever - PowerTools
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=PowerTools&infra=$infra
#baseurl=http://mirror.centos.org/$contentdir/$releasever/PowerTools/$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Linux-Sources.repo <<\EOF
# CentOS-Linux-Sources.repo


[baseos-source]
name=CentOS Linux $releasever - BaseOS - Source
baseurl=http://vault.centos.org/$contentdir/$releasever/BaseOS/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[appstream-source]
name=CentOS Linux $releasever - AppStream - Source
baseurl=http://vault.centos.org/$contentdir/$releasever/AppStream/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[extras-source]
name=CentOS Linux $releasever - Extras - Source
baseurl=http://vault.centos.org/$contentdir/$releasever/extras/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[plus-source]
name=CentOS Linux $releasever - Plus - Source
baseurl=http://vault.centos.org/$contentdir/$releasever/centosplus/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF
    elif [ ${CENTOS_VERSION} -eq "7" ]; then
        CentOS7_RepoFiles='CentOS-Base.repo CentOS-CR.repo CentOS-Debuginfo.repo CentOS-fasttrack.repo CentOS-Media.repo CentOS-Sources.repo CentOS-Vault.repo'
        for REPOS in $CentOS7_RepoFiles; do
            touch $REPOS
        done
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Base.repo <<\EOF
# CentOS-Base.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the 
# remarked out baseurl= line instead.
#
#

[base]
name=CentOS-$releasever - Base
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates 
[updates]
name=CentOS-$releasever - Updates
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=extras&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=centosplus&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-CR.repo <<\EOF
# CentOS-CR.repo
#
# The Continuous Release ( CR )  repository contains rpms that are due in the next
# release for a specific CentOS Version ( eg. next release in CentOS-7 ); these rpms
# are far less tested, with no integration checking or update path testing having
# taken place. They are still built from the upstream sources, but might not map 
# to an exact upstream distro release.
#
# These packages are made available soon after they are built, for people willing 
# to test their environments, provide feedback on content for the next release, and
# for people looking for early-access to next release content.
#
# The CR repo is shipped in a disabled state by default; its important that users 
# understand the implications of turning this on. 
#
# NOTE: We do not use a mirrorlist for the CR repos, to ensure content is available
#       to everyone as soon as possible, and not need to wait for the external
#       mirror network to seed first. However, many local mirrors will carry CR repos
#       and if desired you can use one of these local mirrors by editing the baseurl
#       line in the repo config below.
#

[cr]
name=CentOS-$releasever - cr
baseurl=http://mirror.centos.org/centos/$releasever/cr/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
enabled=0
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Debuginfo.repo <<\EOF
# CentOS-Debug.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#

# All debug packages from all the various CentOS-7 releases
# are merged into a single repo, split by BaseArch
#
# Note: packages in the debuginfo repo are currently not signed
#

[base-debuginfo]
name=CentOS-7 - Debuginfo
baseurl=http://debuginfo.centos.org/7/$basearch/
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-Debug-7
enabled=0
#
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-fasttrack.repo <<\EOF
[fasttrack]
name=CentOS-7 - fasttrack
mirrorlist=http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=fasttrack&infra=$infra
#baseurl=http://mirror.centos.org/centos/$releasever/fasttrack/$basearch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Media.repo <<\EOF
# CentOS-Media.repo
#
#  This repo can be used with mounted DVD media, verify the mount point for
#  CentOS-7.  You can use this repo and yum to install items directly off the
#  DVD ISO that we release.
#
# To use this repo, put in your DVD and use it with the other repos too:
#  yum --enablerepo=c7-media [command]
#  
# or for ONLY the media repo, do this:
#
#  yum --disablerepo=\* --enablerepo=c7-media [command]

[c7-media]
name=CentOS-$releasever - Media
baseurl=file:///media/CentOS/
        file:///media/cdrom/
        file:///media/cdrecorder/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
        cat >$RedHatReposDir/${SYSTEM_CENTOS}-Sources.repo <<\EOF
# CentOS-Sources.repo
#
# The mirror system uses the connecting IP address of the client and the
# update status of each mirror to pick mirrors that are updated to and
# geographically close to the client.  You should use this for CentOS updates
# unless you are manually picking other mirrors.
#
# If the mirrorlist= does not work for you, as a fall back you can try the 
# remarked out baseurl= line instead.
#
#

[base-source]
name=CentOS-$releasever - Base Sources
baseurl=http://vault.centos.org/centos/$releasever/os/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#released updates 
[updates-source]
name=CentOS-$releasever - Updates Sources
baseurl=http://vault.centos.org/centos/$releasever/updates/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras-source]
name=CentOS-$releasever - Extras Sources
baseurl=http://vault.centos.org/centos/$releasever/extras/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus-source]
name=CentOS-$releasever - Plus Sources
baseurl=http://vault.centos.org/centos/$releasever/centosplus/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
EOF
    fi
}

## 生成 Fedora 官方 repo 源文件
function CreateReposRepoFiles() {
    Fedora_RepoFiles='fedora-cisco-openh264.repo fedora.repo fedora-updates.repo fedora-modular.repo fedora-updates-modular.repo fedora-updates-testing.repo fedora-updates-testing-modular.repo'
    for REPOS in $Fedora_RepoFiles; do
        touch $REPOS
    done
    cat >$RedHatReposDir/${SOURCE_BRANCH}-cisco-openh264.repo <<\EOF
[fedora-cisco-openh264]
name=Fedora $releasever openh264 (From Cisco) - $basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-cisco-openh264-$releasever&arch=$basearch
type=rpm
enabled=1
metadata_expire=14d
repo_gpgcheck=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=True

[fedora-cisco-openh264-debuginfo]
name=Fedora $releasever openh264 (From Cisco) - $basearch - Debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-cisco-openh264-debug-$releasever&arch=$basearch
type=rpm
enabled=0
metadata_expire=14d
repo_gpgcheck=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=True
EOF
    cat >$RedHatReposDir/${SOURCE_BRANCH}.repo <<\EOF
[fedora]
name=Fedora $releasever - $basearch
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Everything/$basearch/os/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-$releasever&arch=$basearch
enabled=1
countme=1
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-debuginfo]
name=Fedora $releasever - $basearch - Debug
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Everything/$basearch/debug/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-debug-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-source]
name=Fedora $releasever - Source
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Everything/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-source-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat >$RedHatReposDir/${SOURCE_BRANCH}-updates.repo <<\EOF
[updates]
name=Fedora $releasever - $basearch - Updates
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Everything/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-f$releasever&arch=$basearch
enabled=1
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-debuginfo]
name=Fedora $releasever - $basearch - Updates - Debug
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Everything/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-source]
name=Fedora $releasever - Updates Source
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Everything/SRPMS/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat >$RedHatReposDir/${SOURCE_BRANCH}-modular.repo <<\EOF
[fedora-modular]
name=Fedora Modular $releasever - $basearch
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Modular/$basearch/os/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-modular-$releasever&arch=$basearch
enabled=1
countme=1
#metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-modular-debuginfo]
name=Fedora Modular $releasever - $basearch - Debug
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Modular/$basearch/debug/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-modular-debug-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[fedora-modular-source]
name=Fedora Modular $releasever - Source
#baseurl=http://download.example/pub/fedora/linux/releases/$releasever/Modular/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=fedora-modular-source-$releasever&arch=$basearch
enabled=0
metadata_expire=7d
repo_gpgcheck=0
type=rpm
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat >$RedHatReposDir/${SOURCE_BRANCH}-updates-modular.repo <<\EOF
[updates-modular]
name=Fedora Modular $releasever - $basearch - Updates
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-modular-f$releasever&arch=$basearch
enabled=1
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-modular-debuginfo]
name=Fedora Modular $releasever - $basearch - Updates - Debug
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-modular-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-modular-source]
name=Fedora Modular $releasever - Updates Source
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/SRPMS/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-released-modular-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat >$RedHatReposDir/${SOURCE_BRANCH}-updates-testing.repo <<\EOF
[updates-testing]
name=Fedora $releasever - $basearch - Test Updates
#baseurl=http://download.example/pub/fedora/linux/updates/testing/$releasever/Everything/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-f$releasever&arch=$basearch
enabled=0
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-testing-debuginfo]
name=Fedora $releasever - $basearch - Test Updates Debug
#baseurl=http://download.example/pub/fedora/linux/updates/testing/$releasever/Everything/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-testing-source]
name=Fedora $releasever - Test Updates Source
#baseurl=http://download.example/pub/fedora/linux/updates/testing/$releasever/Everything/SRPMS/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
    cat >$RedHatReposDir/${SOURCE_BRANCH}-updates-testing-modular.repo <<\EOF
[updates-testing-modular]
name=Fedora Modular $releasever - $basearch - Test Updates
#baseurl=http://download.example/pub/fedora/linux/updates/testing/$releasever/Modular/$basearch/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-modular-f$releasever&arch=$basearch
enabled=0
countme=1
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-testing-modular-debuginfo]
name=Fedora Modular $releasever - $basearch - Test Updates Debug
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/$basearch/debug/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-modular-debug-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False

[updates-testing-modular-source]
name=Fedora Modular $releasever - Test Updates Source
#baseurl=http://download.example/pub/fedora/linux/updates/$releasever/Modular/SRPMS/
metalink=https://mirrors.fedoraproject.org/metalink?repo=updates-testing-modular-source-f$releasever&arch=$basearch
enabled=0
repo_gpgcheck=0
type=rpm
gpgcheck=1
metadata_expire=6h
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-fedora-$releasever-$basearch
skip_if_unavailable=False
EOF
}

## 生成 EPEL 扩展 repo 官方源文件
function EPELReposCreate() {
    cd $RedHatReposDir
    if [ ${CENTOS_VERSION} -eq "8" ]; then
        EPEL8_RepoFiles='epel.repo epel-modular.repo epel-playground.repo epel-testing.repo epel-testing-modular.repo'
        for REPOS in $EPEL8_RepoFiles; do
            touch $REPOS
        done
        cat >$RedHatReposDir/epel.repo <<\EOF
[epel]
name=Extra Packages for Enterprise Linux $releasever - $basearch
#baseurl=https://download.fedoraproject.org/pub/epel/8/Everything/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8

[epel-debuginfo]
name=Extra Packages for Enterprise Linux $releasever - $basearch - Debug
#baseurl=https://download.fedoraproject.org/pub/epel/8/Everything/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux $releasever - $basearch - Source
#baseurl=https://download.fedoraproject.org/pub/epel/8/Everything/SRPMS
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1
EOF
        cat >$RedHatReposDir/epel-modular.repo <<\EOF
[epel-modular]
name=Extra Packages for Enterprise Linux Modular $releasever - $basearch
#baseurl=https://download.fedoraproject.org/pub/epel/8/Modular/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-modular-$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8

[epel-modular-debuginfo]
name=Extra Packages for Enterprise Linux Modular $releasever - $basearch - Debug
#baseurl=https://download.fedoraproject.org/pub/epel/8/Modular/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-modular-debug-$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1

[epel-modular-source]
name=Extra Packages for Enterprise Linux Modular $releasever - $basearch - Source
#baseurl=https://download.fedoraproject.org/pub/epel/8/Modular/SRPMS
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-modular-source-$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1
EOF
        cat >$RedHatReposDir/epel-playground.repo <<\EOF
[epel-playground]
name=Extra Packages for Enterprise Linux $releasever - Playground - $basearch
#baseurl=https://download.fedoraproject.org/pub/epel/playground/$releasever/Everything/$basearch/os
metalink=https://mirrors.fedoraproject.org/metalink?repo=playground-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8

[epel-playground-debuginfo]
name=Extra Packages for Enterprise Linux $releasever - Playground - $basearch - Debug
#baseurl=https://download.fedoraproject.org/pub/epel/playground/$releasever/Everything/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=playground-debug-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1

[epel-playground-source]
name=Extra Packages for Enterprise Linux $releasever - Playground - $basearch - Source
#baseurl=https://download.fedoraproject.org/pub/epel/playground/$releasever/Everything/source/tree/
metalink=https://mirrors.fedoraproject.org/metalink?repo=playground-source-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1
EOF
        cat >$RedHatReposDir/epel-testing.repo <<\EOF
[epel-testing]
name=Extra Packages for Enterprise Linux $releasever - Testing - $basearch
#baseurl=https://download.fedoraproject.org/pub/epel/testing/$releasever/Everything/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8

[epel-testing-debuginfo]
name=Extra Packages for Enterprise Linux $releasever - Testing - $basearch - Debug
#baseurl=https://download.fedoraproject.org/pub/epel/testing/$releasever/Everything/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-debug-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1

[epel-testing-source]
name=Extra Packages for Enterprise Linux $releasever - Testing - $basearch - Source
#baseurl=https://download.fedoraproject.org/pub/epel/testing/$releasever/Everything/SRPMS
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-source-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1
EOF
        cat >$RedHatReposDir/epel-testing-modular.repo <<\EOF
[epel-testing-modular]
name=Extra Packages for Enterprise Linux Modular $releasever - Testing - $basearch
#baseurl=https://download.fedoraproject.org/pub/epel/testing/$releasever/Modular/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-modular-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8

[epel-testing-modular-debuginfo]
name=Extra Packages for Enterprise Linux Modular $releasever - Testing - $basearch - Debug
#baseurl=https://download.fedoraproject.org/pub/epel/testing/$releasever/Modular/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-modular-debug-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1

[epel-testing-modular-source]
name=Extra Packages for Enterprise Linux Modular $releasever - Testing - $basearch - Source
#baseurl=https://download.fedoraproject.org/pub/epel/testing/$releasever/Modular/SRPMS
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-modular-source-epel$releasever&arch=$basearch&infra=$infra&content=$contentdir
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8
gpgcheck=1
EOF
    elif [ ${CENTOS_VERSION} -eq "7" ]; then
        EPEL7_RepoFiles='epel.repo epel-testing.repo'
        for REPOS in $EPEL7_RepoFiles; do
            touch $REPOS
        done
        cat >$RedHatReposDir/epel.repo <<\EOF
[epel]
name=Extra Packages for Enterprise Linux 7 - $basearch
#baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch
failovermethod=priority
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[epel-debuginfo]
name=Extra Packages for Enterprise Linux 7 - $basearch - Debug
#baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-debug-7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

[epel-source]
name=Extra Packages for Enterprise Linux 7 - $basearch - Source
#baseurl=http://download.fedoraproject.org/pub/epel/7/SRPMS
metalink=https://mirrors.fedoraproject.org/metalink?repo=epel-source-7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
EOF
        cat >$RedHatReposDir/epel-testing.repo <<\EOF
[epel-testing]
name=Extra Packages for Enterprise Linux 7 - Testing - $basearch
#baseurl=http://download.fedoraproject.org/pub/epel/testing/7/$basearch
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-epel7&arch=$basearch
failovermethod=priority
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

[epel-testing-debuginfo]
name=Extra Packages for Enterprise Linux 7 - Testing - $basearch - Debug
#baseurl=http://download.fedoraproject.org/pub/epel/testing/7/$basearch/debug
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-debug-epel7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1

[epel-testing-source]
name=Extra Packages for Enterprise Linux 7 - Testing - $basearch - Source
#baseurl=http://download.fedoraproject.org/pub/epel/testing/7/SRPMS
metalink=https://mirrors.fedoraproject.org/metalink?repo=testing-source-epel7&arch=$basearch
failovermethod=priority
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
gpgcheck=1
EOF
    fi
}


## 更换基于 RedHat 系 Linux 发行版的国内源
function RedHatMirrors() {
    ## 生成基于 RedHat 发行版和及其衍生发行版的官方 repo 源文件
    case ${SYSTEM_JUDGMENT} in
    RedHat | CentOS)
        CreateCentOSRepoFiles
        ;;
    Fedora)
        CreateReposRepoFiles
        ;;
    esac

    ## 修改源
    cd $RedHatReposDir
    if [ ${SYSTEM_JUDGMENT} = ${SYSTEM_CENTOS} -o ${SYSTEM_JUDGMENT} = ${SYSTEM_RHEL} ]; then
        sed -i 's|^mirrorlist=|#mirrorlist=|g' ${SYSTEM_CENTOS}-*

        ## CentOS 8 操作系统版本结束了生命周期（EOL），Linux 社区已不再维护该操作系统版本，最终版本为 8.5.2011
        ## 原 centos 镜像中的 CentOS 8 相关内容已被官方移动，从 2022-02 开始切换至 centos-vault 源
        if [ ${CENTOS_VERSION} -eq "8" ]; then
            sed -i 's|^#baseurl=http://mirror.centos.org/$contentdir|#baseurl=http://mirror.centos.org/centos-vault|g' ${SYSTEM_CENTOS}-*
            sed -i "s/\$releasever/8.5.2111/g" ${SYSTEM_CENTOS}-*
        fi

        ## WEB协议
        sed -i "s|^#baseurl=http|baseurl=${WEB_PROTOCOL}|g" ${SYSTEM_CENTOS}-*
        ## 更换软件源
        sed -i "s|mirror.centos.org|${SOURCE}|g" ${SYSTEM_CENTOS}-*

        ## Red Hat Enterprise Linux 修改版本号
        if [ ${SYSTEM_JUDGMENT} = ${SYSTEM_RHEL} ]; then
            if [ ${CENTOS_VERSION} -eq "8" ]; then
                sed -i "s/\$releasever/8.5.2111/g" ${SYSTEM_CENTOS}-*
            elif [ ${CENTOS_VERSION} -eq "7" ]; then
                sed -i "s/\$releasever/7/g" ${SYSTEM_CENTOS}-*
            fi
        fi

        ## 安装/更换基于 RHEL/CentOS 的 EPEL 扩展国内源
        [ ${EPEL_INSTALL} = "True" ] && EPELMirrors
    elif [ ${SYSTEM_JUDGMENT} = ${SYSTEM_FEDORA} ]; then
        sed -i 's|^metalink=|#metalink=|g' \
            ${SOURCE_BRANCH}.repo \
            ${SOURCE_BRANCH}-updates.repo \
            ${SOURCE_BRANCH}-modular.repo \
            ${SOURCE_BRANCH}-updates-modular.repo \
            ${SOURCE_BRANCH}-updates-testing.repo \
            ${SOURCE_BRANCH}-updates-testing-modular.repo
        sed -i "s|^#baseurl=http|baseurl=${WEB_PROTOCOL}|g" fedora*
        sed -i "s|download.example/pub/fedora/linux|${SOURCE}/fedora|g" \
            fedora.repo \
            ${SOURCE_BRANCH}-updates.repo \
            ${SOURCE_BRANCH}-modular.repo \
            ${SOURCE_BRANCH}-updates-modular.repo \
            ${SOURCE_BRANCH}-updates-testing.repo \
            ${SOURCE_BRANCH}-updates-testing-modular.repo
    fi
    ## 清理 yum 缓存
    yum clean all >/dev/null 2>&1
}


## 安装/更换基于 RHEL/CentOS 的 EPEL (Extra Packages for Enterprise Linux) 扩展国内源
function EPELMirrors() {
    ## 安装 EPEL 软件包
    if [ ${VERIFICATION_EPEL} -ne 0 ]; then
        echo -e "\n${WORKING} 安装 epel-release 软件包...\n"
        yum install -y epel-release
        # yum install -y https://mirrors.aliyun.com/epel/epel-release-latest-${CENTOS_VERSION}.noarch.rpm
    fi
    ## 删除原有 EPEL 扩展 repo 源文件
    [ ${VERIFICATION_EPELFILES} -eq 0 ] && rm -rf $RedHatReposDir/epel*
    [ ${VERIFICATION_EPELBACKUPFILES} -eq 0 ] && rm -rf $RedHatReposDirBackup/epel*
    ## 生成官方 EPEL 扩展 repo 源文件
    EPELReposCreate
    ## 更换国内源
    sed -i 's|^metalink=|#metalink=|g' $RedHatReposDir/epel*
    case ${CENTOS_VERSION} in
    8)
        sed -i "s|^#baseurl=https|baseurl=${WEB_PROTOCOL}|g" $RedHatReposDir/epel*
        ;;
    7)
        sed -i "s|^#baseurl=http|baseurl=${WEB_PROTOCOL}|g" $RedHatReposDir/epel*
        ;;
    esac
    sed -i "s|download.fedoraproject.org/pub|${SOURCE}|g" $RedHatReposDir/epel*
    rm -rf $RedHatReposDir/epel*rpmnew
}
## 更新软件包
function UpgradeSoftware() {
    CHOICE_B=$(echo -e "\n${BOLD}└─ 是否更新软件包? [Y/n] ${PLAIN}")
    read -p "${CHOICE_B}" INPUT
    [ -z ${INPUT} ] && INPUT=Y
    case $INPUT in
    [Yy] | [Yy][Ee][Ss])
        echo -e ''
        yum upgrade -y
        CHOICE_C=$(echo -e "\n${BOLD}└─ 是否清理已下载的软件包缓存? [Y/n] ${PLAIN}")
        read -p "${CHOICE_C}" INPUT
        [ -z ${INPUT} ] && INPUT=Y
        case $INPUT in
        [Yy] | [Yy][Ee][Ss])
           
            yum autoremove -y >/dev/null 2>&1
            yum clean packages -y >/dev/null 2>&1
           
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
}

# 执行
RunMain