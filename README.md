# Zero Panel
OpenVPN Zero流控|拥有简单的后台管理|仅供个人使用|支持Debian、Ubuntu、CentOS

## 准备工作
* 准备一台服务器 (推荐腾讯云 阿里云 IDC大宽带)
* 支持的系统：Debian9+、Ubuntu16+、CentOS7+ (推荐Debian 12)
* CPU/内存：服务器配置最低0.5核0.5G内存
* 带宽：推荐5Mbps以上
* 网络：必须具有固定公网IP（IPV4）

## 版本说明
* 1.0版本只安装了 OPENVPN，没有其他功能，精简，节省服务器性能，服务器只需要0.5C 0.5G即可带动，适合个人使用。(用户验证文件位于/Zero/user_auth.list 需要自己手动使用编辑器添加用户，后续在更新一键添加的。)
* 2.0版本安装了 OPENVPN+ZEROPANEL 适合多人使用，因为使用到了数据库服务，需要服务器最低1C1G配置。


## 安装脚本
* 如果出现安装失败，请全格重装系统，手动更新yum(centos)/apt(ubuntu debian)源后重新执行安装脚本即可。

* Github
```shell script
wget --no-check-certificate -O zero.sh https://raw.githubusercontent.com/Shirley-Jones/Zero-Panel/main/zero.sh && chmod +x ./zero.sh && ./zero.sh
```

* Shirley's (Asia HK)
```shell script
wget --no-check-certificate -O zero.sh https://api.qiaouu.com/shell/zero_resources/zero.sh && chmod +x ./zero.sh && ./zero.sh
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
* 所有源码全部开源，我个人没有加入任何后门，欢迎检查，不放心的不要用，谢谢大家！

## 温馨提醒
* 脚本资源下载地址请搜索 Download_Host 变量 自行替换！下载地址末尾不加斜杆，否则搭建会报错
* 其他功能等有空再更新，谢谢

* 任何问题不要问我，不要问我，不要问我。
* 任何问题不要问我，不要问我，不要问我。
* 任何问题不要问我，不要问我，不要问我。
* 脚本问题请反馈至: xshirleyjones02@gmail.com (仅处理脚本搭建报错问题，Bug等问题。)




