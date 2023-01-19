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

function DownloadScript(){
    RemoveScript
    echo -e "\n$GREEN 下载脚本中...${PLAIN}\n"
    sleep 2s
    curl -sSLo /tmp/dev.zip https://github.com/midoks/change-linux-mirrors/archive/refs/heads/main.zip
    cd /tmp && unzip /tmp/dev.zip
}

function RemoveScript(){
    if [ -f /tmp/dev.zip ];then 
        cd /tmp && rm -rf /tmp/dev.zip
    fi

    if [ -d /tmp/change-linux-mirrors-main ];then
        cd /tmp && rm -rf /tmp/change-linux-mirrors-main
    fi
}

# 安装
function InstallScript(){
    sleep 1
    clear
    if grep -Eq "openSUSE" /etc/*-release; then
        OSNAME='opensuse'
    elif grep -Eq "FreeBSD" /etc/*-release; then
        OSNAME='freebsd'
    elif grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        OSNAME='rhel'
        yum install -y unzip
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        OSNAME='fedora'
        yum install -y unzip
    elif grep -Eqi "Rocky" /etc/issue || grep -Eq "Rocky" /etc/*-release; then
        OSNAME='rhel'
        yum install -y unzip
    elif grep -Eqi "AlmaLinux" /etc/issue || grep -Eq "AlmaLinux" /etc/*-release; then
        OSNAME='rhel'
        yum install -y unzip
    elif grep -Eqi "Amazon Linux" /etc/issue || grep -Eq "Amazon Linux" /etc/*-release; then
        OSNAME='rhel'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        OSNAME='debian'
        apt install -y unzip
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        OSNAME='debian'
        apt install -y unzip
    else
        echo -e "\n$ERROR 无法判断当前运行环境，请先确认本脚本针对当前操作系统是否适配\n"
        exit
    fi
    echo "use system: ${OSNAME}"

    script_file=/tmp/change-linux-mirrors-main/script/${OSNAME}.sh
    # echo $script_file
    if [ -f $script_file ];then
        # bash -x $script_file
        bash $script_file
    fi
}


function RunMain(){
	PermissionJudgment
    DownloadScript
    InstallScript
    RemoveScript
    AuthorMessage
}

# 执行
RunMain