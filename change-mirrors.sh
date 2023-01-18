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
}

function RunMain(){
	PermissionJudgment
    EnvJudgment

}

# 执行
RunMain