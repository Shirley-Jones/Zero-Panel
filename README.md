# Zero Panel (OpenVPN+Trojan免域名版)

## 准备工作
* 准备一台服务器 (推荐腾讯云 阿里云 IDC大宽带)
* 支持的系统：CentOS7 X64
* CPU/内存：服务器配置最低0.5核0.5G内存
* 带宽：推荐5Mbps以上
* 网络：必须具有固定公网IP（IPV4）

## 安装脚本
* 如果出现安装失败，请全格重装系统，手动更新yum(centos)源后重新执行安装脚本即可。
* 常见问题请访问: https://github.com/Shirley-Jones/Zero-Panel/blob/main/help.md

* Github
```shell script
wget --no-check-certificate -O zero.sh https://raw.githubusercontent.com/Shirley-Jones/Zero-Panel/main/zero.sh && chmod +x ./zero.sh && ./zero.sh
```

## 常用命令

> 重启流控 zero restart

> 系统工具 zero tools

> 内存清理 zero clean

> 系统负载请在后台中添加节点服务器


## 免责声明
* 脚本写的很辣鸡，还请大佬多多包涵。
* 这个版本为Shirley编写!!!
* 本脚本仅用于学习交流，禁止商业，下载安装后请在24小时内删除！
* 用户流量监控文件暂时不考虑开源，谢谢，如果不放心怕有后门什么的，请直接删除即可 rm -rf /Zero/Core/zero_auth.bin (这个只是监控用户流量和天数的作用)
* Trojan项目请点击https://github.com/trojan-gfw/trojan


## 温馨提醒
* 脚本资源下载地址请搜索 Download_Host 变量 自行替换！下载地址末尾不加斜杆，否则搭建会报错
* 其他功能等有空再更新，谢谢
* 任何问题不要问我，不要问我，不要问我。
* 任何问题不要问我，不要问我，不要问我。
* 任何问题不要问我，不要问我，不要问我。




