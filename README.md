# Zero Panel (OpenVPN+Trojan免域名版)

## 准备工作
* 准备一台服务器 (推荐腾讯云 阿里云 IDC大宽带)
* 支持的系统：Ubuntu20+ X64
* CPU/内存：服务器配置最低0.5核0.5G内存
* 带宽：推荐5Mbps以上
* 网络：必须具有固定公网IP（IPV4）

## 安装说明
* 新手小白安装前请先执行以下指令
* echo "nameserver 8.8.8.8" >> /etc/resolv.conf
* apt update
* apt install curl wget -y
* Github安装脚本
```shell script
wget --no-check-certificate -O zero.bin https://raw.githubusercontent.com/Shirley-Jones/Zero-Panel/main/zero.bin && chmod +x ./zero.bin && ./zero.bin
```


## 编译说明
* apt update
* apt install curl libcurl4-openssl-dev openssl gcc gdb -y
* gcc -o /root/zero.bin /root/zero.c -lcurl


## 常用命令

> 重启流控 zero restart

> 系统工具 zero tools

> 内存清理 zero clean

> 系统负载请在后台中添加节点服务器


## 脚本声明
* 脚本写的很辣鸡，还请大佬多多包涵。
* 目前脚本不支持Debian，请先使用Ubuntu系统!!!(2025.02.04)
* 本脚本仅用于学习交流，禁止商业，下载安装后请在24小时内删除！
* 所有文件全部已经开源!!!
* Trojan项目请点击https://github.com/trojan-gfw/trojan


## 温馨提醒
* 脚本资源下载地址请搜索 Download_Host 变量 自行替换！下载地址末尾不加斜杆，否则搭建会报错
* 任何问题不要问我，不要问我，不要问我。
* 任何问题不要问我，不要问我，不要问我。
* 任何问题不要问我，不要问我，不要问我。




