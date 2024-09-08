
## 常见问题
* Q：流控搭建后Zero_AUTH启动失败怎么办？
* A：请手动停止+运行Zero_AUTH服务，停止: systemctl stop zero_auth.service 启动: systemctl start zero_auth.service

* Q：openvpn用户连接显示密码错误？
* A：请检查用户名和密码是否正确，系统做了用户和密码长度验证，最短字符不能低于5位数，如果是节点模式请检查对接API是否正确，api配置文件位于/zero/config/api_config.php

####其他问题待补充....

