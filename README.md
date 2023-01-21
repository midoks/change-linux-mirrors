# change-linux-mirrors

[![](https://data.jsdelivr.com/v1/package/gh/midoks/change-linux-mirrors/badge?style=for-the-badge)](https://www.jsdelivr.com/package/gh/midoks/change-linux-mirrors)

- 一键更换Linux系统源脚本

```
bash <(curl -sSL https://raw.githubusercontent.com/midoks/change-linux-mirrors/main/change-mirrors.sh)
```

- Docker

```
bash <(curl -sSL https://raw.githubusercontent.com/midoks/change-linux-mirrors/main/docker.sh)
```


### Stargazers over time

[![Stargazers over time](https://starchart.cc/midoks/change-linux-mirrors.svg)](https://starchart.cc/midoks/change-linux-mirrors)


### FAQ

- 如果提示 `Command 'curl' not found` 则说明当前未安装 `curl` 软件包

```bash
yum install -y curl || apt-get install -y curl
```

- 如果提示 `Command 'wget' not found` 则说明当前未安装 `wget` 软件包

```bash
yum install -y wget || apt-get install -y wget
```

- 如果提示 `bash: /proc/self/fd/11: No such file or directory`，请切换至 `Root` 用户执行