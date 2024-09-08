#!/bin/bash
#Project address: https://github.com/Shirley-Jones/Zero-Panel
#Thank you very much for using this project!

Download_address_selection()
{
	
	echo
	echo "请选择下载地址"
	echo "1、Github"
	echo "2、Shirley's"
	read -p "请选择[1-2]: " Download_address_Option
	
	while [[ ${Download_address_Option} == "" ]]
	do
		echo -e "\033[31m检测到下载地址没有选择，请重新尝试！\033[0m"
		echo "请选择下载地址"
		echo "1、Github"
		echo "2、Shirley's(服务器有效期至2025-02-12 00:00:00)"
		read -p "请选择[1-2]: " Download_address_Option
	done
	
	
	#请直接在此处修改您的下载地址
	
	if [[ ${Download_address_Option} == "1" ]];then
		echo "已选择【Github】"
		Download_Host="https://raw.githubusercontent.com/Shirley-Jones/Zero-Panel/main/source"
	fi
	
	if [[ ${Download_address_Option} == "2" ]];then
		echo "已选择【Shirley's】"
		Download_Host="http://api.qiaouu.top/shell/zero_resources"
	fi
	
	return 0;
	
}


System_Check()
{
	
	if grep -Eqii "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
		Linux_OS='CentOS'
		PM='yum'
	elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
		Linux_OS='RHEL'
		PM='yum'
	elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun" /etc/*-release; then
		Linux_OS='Aliyun'
		PM='yum'
	elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
		Linux_OS='Fedora'
		PM='yum'
	elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
		Linux_OS='Debian'
		PM='apt'
	elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
		Linux_OS='Ubuntu'
		PM='apt'
	elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
		Linux_OS='Raspbian'
		PM='apt'
	else
		Linux_OS='Unknown'
	fi
	
	if [[ !${Linux_OS} ==  "CentOS" ]]; then 
		echo "当前Linux系统不支持安装Zero,请更换到CentOS7后重新尝试!!!"
		exit 1;
	fi
	
	
	#获取Linux发行版 版本号
	#加载文件
	source /etc/os-release
	Linux_Version=${VERSION_ID}
	
	if [[ ! ${Linux_Version} == "7" ]]; then 
		echo "当前CentOS版本不支持安装Zero,请更换到CentOS7后重新尝试!!!"
		exit 1;
	fi
	
	return 0;
}


Detect_server_IP_address()
{
	clear
	echo "正在检测您的服务器IP地址！"
	Server_IP=`wget http://members.3322.org/dyndns/getip -O - -q ; echo`;
	if [ ${Server_IP} = "" ]; then
		#空白
		echo -e "\033[31m我们无法检测您的服务器IP地址，会影响到您接下来的搭建工作，强制退出程序！！！~\033[0m"
		exit 1;
	else
		#已获取到信息
		echo
		echo -e "检测到您的IP为: \033[32m"${Server_IP}"\033[0m 如不正确请立刻停止搭建，回车继续！"
		read
		sleep 1
		return 0;
	fi
}

Installation_requires_software()
{
	#lsb_release -a
	
	if [ ! -f /usr/bin/wget ]; then
		yum install wget -y >/dev/null 2>&1
		if [ ! -f /usr/bin/wget ]; then
			echo "wget 安装失败，强制退出程序!!!"
			exit 1;
		fi
	fi
	
	
	if [ ! -f /usr/bin/curl ]; then
		yum install curl -y >/dev/null 2>&1
		if [ ! -f /usr/bin/curl ]; then
			echo "curl 安装失败，强制退出程序!!!"
			exit 1;
		fi
	fi
	
	if [ ! -f /usr/bin/ifconfig ] && [ ! -f /usr/sbin/ifconfig ]; then
		yum install net-tools -y >/dev/null 2>&1
		if [ ! -f /usr/bin/ifconfig ] && [ ! -f /usr/sbin/ifconfig ]; then
			echo "net-tools 安装失败，强制退出程序!!!"
			exit 1;
		fi
	fi
	
	
	if [ ! -f /usr/bin/rm ] && [ ! -f /usr/sbin/rm ] && [ ! -f /bin/rm ] && [ ! -f /sbin/rm ]; then
		echo "系统环境异常，强制退出程序 -1!!!"
		exit 1;
	fi
	
	
	
	if [ ! -f /usr/bin/cp ] && [ ! -f /usr/sbin/cp ] && [ ! -f /bin/cp ] && [ ! -f /sbin/cp ]; then
		echo "系统环境异常，强制退出程序 -2!!!"
		exit 1;
	fi
	
	
	if [ ! -f /usr/bin/mv ] && [ ! -f /usr/sbin/mv ] && [ ! -f /bin/mv ] && [ ! -f /sbin/mv ]; then
		echo "系统环境异常，强制退出程序 -3!!!"
		exit 1;
	fi
	
	
	if [ ! -f /usr/bin/chmod ] && [ ! -f /usr/sbin/chmod ] && [ ! -f /bin/chmod ] && [ ! -f /sbin/chmod ]; then
		echo "系统环境异常，强制退出程序 -4!!!"
		exit 1;
	fi
	
	
	Read_network_card_information=`ifconfig`;
	Read_main_network_card_information=`echo $Read_network_card_information|awk '{print $1}'`;
	Main_network_card_name=`printf ${Read_main_network_card_information/:/}`
	if [[ ${Main_network_card_name} == "" ]]; then 
		echo "无法获取主网卡信息，强制退出程序!!!"
		exit 1;
	fi
	
	

	return 0;
}


Zero_install_guide()
{
	clear
	sleep 1
	
	
	SSH_Port=$(netstat -tulpn | grep sshd | awk '{print $4}' | cut -d: -f2)
	echo
	while [[ ${SSH_Port} == "" ]]
	do
		read -p "请设置SSH端口: " SSH_Port
	done
	
	
	echo
	read -p "请设置Apache端口: " Apache_Port
	while [[ ${Apache_Port} == "" ]]
	do
		echo -e "\033[31m检测到Apache端口没有输入,请重新尝试!!!\033[0m"
		read -p "请设置Apache端口: " Apache_Port
	done
	
	echo
	read -p "请设置通讯密码: " Communication_password
	while [[ ${Communication_password} == "" ]]
	do
		echo -e "\033[31m检测到通讯密码没有输入,请重新尝试!!!\033[0m"
		read -p "请设置通讯密码: " Communication_password
	done
	
	
	echo
	read -p "请设置Trojan密码: " Trojan_Password
	while [[ ${Trojan_Password} == "" ]]
	do
		echo -e "\033[31m检测到Trojan密码没有输入,请重新尝试!!!\033[0m"
		read -p "请设置Trojan密码: " Trojan_Password
	done
	
	
	#验证安装模式
	if [[ ${Installation_mode} == "ALL" ]]; then
		echo
		read -p "请设置数据库密码: " Database_Password
		while [[ ${Database_Password} == "" ]]
		do
			echo -e "\033[31m检测到数据库密码没有输入,请重新尝试!!!\033[0m"
			read -p "请设置数据库密码: " Database_Password
		done
		Database_Address="127.0.0.1";
		Database_Ports="3306";
		Database_Username="root";
		OpenVPN_Api=${Server_IP}:${Apache_Port}
	else
		echo
		echo "Tips:"
		echo "API地址开头不需要添加 http:// 和 https:// 末尾也不需要加斜杆"
		echo "示例: api.google.com 如果有web端口,请加上web端口,示例: api.google.com:8888"
		echo "api地址用于用户身份验证,数据库信息用于用户流量监控"
		echo
		read -p "请输入API地址: " OpenVPN_Api
		while [[ ${OpenVPN_Api} == "" ]]
		do
			echo -e "\033[31m检测到API地址没有输入,请重新尝试!!!\033[0m"
			read -p "请输入API地址: " OpenVPN_Api
		done
		
		echo
		read -p "请输入主机/远程数据库地址: " Database_Address
		while [[ ${Database_Address} == "" ]]
		do
			echo -e "\033[31m检测到数据库地址没有输入,请重新尝试!!!\033[0m"
			read -p "请输入主机/远程数据库地址: " Database_Address
		done
		
		echo
		read -p "请输入主机/远程数据库端口: " Database_Ports
		while [[ ${Database_Ports} == "" ]]
		do
			echo -e "\033[31m检测到数据库端口没有输入,请重新尝试!!!\033[0m"
			read -p "请输入主机/远程数据库端口: " Database_Ports
		done
		
		echo
		read -p "请输入主机/远程数据库账户: " Database_Username
		while [[ ${Database_Username} == "" ]]
		do
			echo -e "\033[31m检测到数据库账户没有输入,请重新尝试!!!\033[0m"
			read -p "请输入主机/远程数据库账户: " Database_Username
		done
		
		echo
		read -p "请输入主机/远程数据库密码: " Database_Password
		while [[ ${Database_Password} == "" ]]
		do
			echo -e "\033[31m检测到数据库密码没有输入,请重新尝试!!!\033[0m"
			read -p "请输入主机/远程数据库密码: " Database_Password
		done
		
		echo
		read -p "请设置Trojan密码: " Trojan_Password
		while [[ ${Trojan_Password} == "" ]]
		do
			echo -e "\033[31m检测到Trojan密码没有输入,请重新尝试!!!\033[0m"
			read -p "请设置Trojan密码: " Trojan_Password
		done
	fi
	
	
	
	Download_address_selection
	
	
	sleep 1
	echo
	echo "安装信息收集已完成，即将开始安装！"
	sleep 3
	
	return 0;
}



Install_Zero()
{
	
	
	#----------开始安装----------
	
	clear
	sleep 1
	
	echo
	echo "正在初始化环境..."
	
	#设置SELinux宽容模式
	setenforce 0 >/dev/null 2>&1
	sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config >/dev/null 2>&1
	yum install make openssl gcc gdb net-tools unzip psmisc wget curl zip vim telnet -y >/dev/null 2>&1
	yum install nss telnet avahi openssl openssl-libs openssl-devel lzo lzo-devel pam pam-devel automake pkgconfig gawk tar zip unzip net-tools psmisc gcc pkcs11-helper libxml2 libxml2-devel bzip2 bzip2-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel gmp gmp-devel libmcrypt libmcrypt-devel readline readline-devel libxslt libxslt-devel --skip-broken -y >/dev/null 2>&1
	yum install epel-release -y >/dev/null 2>&1
	#创建新缓存 国内服务器安装较慢请耐心等待
	yum clean all >/dev/null 2>&1
	yum makecache >/dev/null 2>&1
	yum install yum-utils -y >/dev/null 2>&1
	rpm -ivh https://rpms.remirepo.net/enterprise/remi-release-7.rpm >/dev/null 2>&1
	if [ ! -f /etc/yum.repos.d/remi.repo ] && [ ! -f /etc/yum.repos.d/remi-modular.repo ] && [ ! -f remi-safe.repo ]; then
		#不存在 重新安装
		echo "remi-release安装失败，强制退出程序 -1"
		exit 1;
	fi
	yum-config-manager --enable remi-php74 -y >/dev/null 2>&1
		
	#创建新缓存 国内服务器安装较慢请耐心等待
	yum clean all >/dev/null 2>&1
	yum makecache >/dev/null 2>&1
	
	echo "正在安装Apache+PHP..."
	yum install httpd httpd-tools -y >/dev/null 2>&1
	yum remove php-* -y >/dev/null 2>&1
	yum install php php-cli php-common php-gd php-ldap php-mysql php-odbc php-xmlrpc -y >/dev/null 2>&1
	sed -i "s/#ServerName www.example.com:80/ServerName localhost:"${Apache_Port}"/g" /etc/httpd/conf/httpd.conf
	sed -i "s/Listen 80/Listen "${Apache_Port}"/g" /etc/httpd/conf/httpd.conf
	#禁用Apache目录浏览
	sed -i "s/Options Indexes FollowSymLinks/Options FollowSymLinks/g" /etc/httpd/conf/httpd.conf
	systemctl restart httpd.service
	systemctl enable httpd.service >/dev/null 2>&1
	
	if [ ! -f /usr/bin/php ] && [ ! -f /usr/sbin/php ] && [ ! -f /bin/php ] && [ ! -f /sbin/php ]; then
		echo "PHP软件包安装失败。"
		exit 1;
	fi
	
	#验证安装模式
	if [[ ${Installation_mode} == "ALL" ]]; then
		#主机模式 追加安装MySQL
		echo "正在安装Database Services..."
		yum install mariadb mariadb-server mariadb-devel -y >/dev/null 2>&1
		if [ ! -f /usr/bin/mysql ] && [ ! -f /usr/sbin/mysql ] && [ ! -f /bin/mysql ] && [ ! -f /sbin/mysql ]; then
			echo "Database(Mariadb)软件包安装失败。"
			exit 1;
		fi
		
		
		systemctl start mariadb.service >/dev/null 2>&1
		mysqladmin -uroot password ${Database_Password}
		mysql -uroot -p${Database_Password} -e 'create database zero;'
		mysql -uroot -p${Database_Password} -e "use mysql;GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '"${Database_Password}"' WITH GRANT OPTION;flush privileges;"
		systemctl restart mariadb.service
		systemctl enable mariadb.service >/dev/null 2>&1
		
		
		#主机模式 追加安装Zero Panel
		echo "正在安装Zero Panel..."
		rm -rf /var/www/html/*
		wget -q --no-check-certificate ${Download_Host}/Zero_Panel.zip -P /var/www/html
		cd /var/www/html
		unzip -o /var/www/html/Zero_Panel.zip >/dev/null 2>&1
		rm -rf /var/www/html/Zero_Panel.zip
		chmod -R 0777 /var/www/html/*
		
		#修改数据库信息
		sed -i "s/Zero_MySQL_Host/127.0.0.1/g" /var/www/html/Config/MySQL.php
		sed -i "s/Zero_MySQL_Port/3306/g" /var/www/html/Config/MySQL.php
		sed -i "s/Zero_MySQL_User/root/g" /var/www/html/Config/MySQL.php
		sed -i "s/Zero_MySQL_Pass/"${Database_Password}"/g" /var/www/html/Config/MySQL.php
		
		#导入数据表到数据库
		sed -i "s/server_ip_modify/"${Server_IP}"/g" /var/www/html/new_zero.sql
		sed -i "s/server_port_modify/"${Apache_Port}"/g" /var/www/html/new_zero.sql
		sed -i "s/server_realm_name_modify/"${Server_IP}"/g" /var/www/html/new_zero.sql
		sed -i "s/server_api_key_modify/"${Communication_password}"/g" /var/www/html/new_zero.sql
		mysql -uroot -p${Database_Password} zero < /var/www/html/new_zero.sql
		rm -rf /var/www/html/new_zero.sql
		
		#安装phpmyadmin
		#wget -q --no-check-certificate ${Download_Host}/phpMyAdmin-5.2.1-all-languages.zip -P /var/www/html
		wget -q --no-check-certificate https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip -P /var/www/html
		cd /var/www/html
		unzip -o /var/www/html/phpMyAdmin-5.2.1-all-languages.zip >/dev/null 2>&1
		rm -rf /var/www/html/phpMyAdmin-5.2.1-all-languages.zip
		mv /var/www/html/phpMyAdmin-5.2.1-all-languages /var/www/html/phpMyAdmin
		#请注意 phpMyAdmin 默认权限不要动 不要改0777  否则一定会报错
	
	fi
	
	
	echo "正在安装Zero Core..."
	
	rm -rf /Zero
	mkdir /Zero
	
	ALL_RAM_free=$(echo `free | grep Mem | awk '{print $2 / 1024}'`|sed "s/\..*//g")
	if [[ ${ALL_RAM_free} -lt "800" ]]; then
		#内存少于800MB  创建虚拟内存Swap 1GB
		fallocate -l 1G /Zero/ZeroSwap
		ls -lh /Zero/ZeroSwap >/dev/null 2>&1
		chmod 600 /Zero/ZeroSwap
		mkswap /Zero/ZeroSwap >/dev/null 2>&1
		swapon /Zero/ZeroSwap >/dev/null 2>&1
		echo "/Zero/ZeroSwap none swap sw 0 0" >> /etc/fstab
	fi
	
	wget -q --no-check-certificate ${Download_Host}/Zero_Core.zip -P /Zero
	cd /Zero
	unzip -o /Zero/Zero_Core.zip >/dev/null 2>&1
	rm -rf /Zero/Zero_Core.zip
	chmod -R 0777 /Zero
	
	
	#安装iptables
	yum install iptables iptables-services -y >/dev/null 2>&1
	#禁用 firewalld
	systemctl stop firewalld.service >/dev/null 2>&1
	systemctl disable firewalld.service >/dev/null 2>&1
	if [ ! -f /usr/bin/iptables ] && [ ! -f /usr/sbin/iptables ] && [ ! -f /bin/iptables ] && [ ! -f /sbin/iptables ]; then
		echo "iptables软件包安装失败。"
		exit 1;
	fi
	
	iptables -A INPUT -s 127.0.0.1/32  -j ACCEPT
	iptables -A INPUT -d 127.0.0.1/32  -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport ${SSH_Port} -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport ${Apache_Port} -j ACCEPT
	#openvpn proxy
	iptables -A INPUT -p tcp -m tcp --dport 8081 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 8082 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 8083 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 8084 -j ACCEPT
	#openvpn
	iptables -A INPUT -p tcp -m tcp --dport 1194 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 1195 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 1196 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 1197 -j ACCEPT
	iptables -A INPUT -p udp -m udp --dport 53 -j ACCEPT
	iptables -A INPUT -p udp -m udp --dport 67 -j ACCEPT
	#trojan
	iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
	#其他
	iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o ${Main_network_card_name} -j MASQUERADE
	iptables -t nat -A POSTROUTING -s 10.1.0.0/24 -o ${Main_network_card_name} -j MASQUERADE
	iptables -t nat -A POSTROUTING -s 10.2.0.0/24 -o ${Main_network_card_name} -j MASQUERADE
	iptables -t nat -A POSTROUTING -s 10.3.0.0/24 -o ${Main_network_card_name} -j MASQUERADE
	iptables -t nat -A POSTROUTING -s 10.4.0.0/24 -o ${Main_network_card_name} -j MASQUERADE
	iptables -t nat -A POSTROUTING -s 10.5.0.0/24 -o ${Main_network_card_name} -j MASQUERADE
	echo "127.0.0.1 localhost" > /etc/hosts
	service iptables save >/dev/null 2>&1
	systemctl restart iptables.service
	systemctl enable iptables.service >/dev/null 2>&1
	
	#安装OpenVPN
	yum install openvpn openvpn-devel gcc -y >/dev/null 2>&1
	if [ ! -f /usr/bin/openvpn ] && [ ! -f /usr/sbin/openvpn ] && [ ! -f /bin/openvpn ] && [ ! -f /sbin/openvpn ]; then
		echo "OpenVPN软件包安装失败。"
		exit 1;
	fi
	
	
	rm -rf /etc/openvpn
	mv /Zero/openvpn /etc/openvpn
	#启动OpenVPN
	systemctl restart openvpn@server-tcp1194.service
	systemctl restart openvpn@server-tcp1195.service
	systemctl restart openvpn@server-tcp1196.service
	systemctl restart openvpn@server-tcp1197.service
	systemctl restart openvpn@server-udp53.service
	systemctl restart openvpn@server-udp67.service
	systemctl enable openvpn@server-tcp1194.service >/dev/null 2>&1
	systemctl enable openvpn@server-tcp1195.service >/dev/null 2>&1
	systemctl enable openvpn@server-tcp1196.service >/dev/null 2>&1
	systemctl enable openvpn@server-tcp1197.service >/dev/null 2>&1
	systemctl enable openvpn@server-udp53.service >/dev/null 2>&1
	systemctl enable openvpn@server-udp67.service >/dev/null 2>&1
	
	#创建软连接（快捷方式）
	ln -s /Zero/bin/* /usr/bin
	#移动配置文件
	rm -rf /etc/sysctl.conf
	mv /Zero/Config/sysctl.conf /etc/sysctl.conf
	sysctl -p >/dev/null 2>&1
	mv /Zero/api.php /var/www/html/api.php
	sed -i "s/Communication_password/"${Communication_password}"/g" /Zero/Config/API_Config.php
	#修改配置文件
	sed -i "s/API_ADDRESS/"${OpenVPN_Api}"/g" /Zero/Config/API_Config.php
	sed -i "s/content1/"${Database_Address}"/g" /Zero/Config/auth_config.conf
	sed -i "s/content2/"${Database_Ports}"/g" /Zero/Config/auth_config.conf
	sed -i "s/content3/"${Database_Username}"/g" /Zero/Config/auth_config.conf
	sed -i "s/content4/"${Database_Password}"/g" /Zero/Config/auth_config.conf
	sed -i "s/content5/"${Server_IP}"/g" /Zero/Config/auth_config.conf
	sed -i "s/content5/"${Server_IP}"/g" /Zero/Config/zero_config.conf
	
	#配置服务并设置Zero proxy开机自启
	mv /Zero/proxy.service /lib/systemd/system/proxy.service
	
	#配设置Zero auth开机自启 
	mv /Zero/zero_auth.service /lib/systemd/system/zero_auth.service
	
	#添加开机自动执行shell服务 
	mv /Zero/auto_run.service /lib/systemd/system/auto_run.service
	
	#重新加载所有服务
	systemctl daemon-reload >/dev/null 2>&1
	#启动服务
	systemctl start zero_auth.service >/dev/null 2>&1
	systemctl start auto_run.service >/dev/null 2>&1
	systemctl restart proxy.service >/dev/null 2>&1
	#设置开机自启
	systemctl enable zero_auth.service >/dev/null 2>&1
	systemctl enable auto_run.service >/dev/null 2>&1
	systemctl enable proxy.service >/dev/null 2>&1
	
	
	#修改亚洲香港时区
	#列出全球时区 timedatectl list-timezones
	#以下为常用时区
	#韩国首尔 Asia/Seoul
	#台湾台北 Asia/Taipei
	#香港 Asia/Hong_Kong
	#中国上海 Asia/Shanghai
	#美国纽约 America/New_York
	#日本东京 Asia/Tokyo
	Time_zone_detection=$(timedatectl | grep "Asia/Hong_Kong")
	if [[ ${Time_zone_detection} == "" ]]; then 
		timedatectl set-local-rtc 0 >/dev/null 2>&1
		timedatectl set-timezone Asia/Hong_Kong >/dev/null 2>&1
	fi
	
	echo "正在安装Trojan免域名版..."
	
	yum install gnutls-utils -y >/dev/null 2>&1
	rm -rf /etc/trojan
	wget -q --no-check-certificate ${Download_Host}/trojan1.16.zip -P /etc
	cd /etc
	unzip -o /etc/trojan1.16.zip >/dev/null 2>&1
	rm -rf /etc/trojan1.16.zip
	sed -i "s/content1/"${Server_IP}"/g" /etc/trojan/ca.txt
	sed -i "s/content2/Shirleylin/g" /etc/trojan/ca.txt
	sed -i "s/content1/"${Server_IP}"/g" /etc/trojan/trojan.txt
	sed -i "s/content2/Shirleylin/g" /etc/trojan/trojan.txt
	sed -i "s/password1/"${Trojan_Pass}"/g" /etc/trojan/config.json
	sed -i "s/password2/"${Trojan_Pass}"/g" /etc/trojan/config.json
	certtool --generate-privkey --outfile /etc/trojan/ca-key.pem >/dev/null 2>&1
	certtool --generate-self-signed --load-privkey /etc/trojan/ca-key.pem --template /etc/trojan/ca.txt --outfile /etc/trojan/ca-cert.pem >/dev/null 2>&1
	certtool --generate-privkey --outfile /etc/trojan/trojan-key.pem >/dev/null 2>&1
	certtool --generate-certificate --load-privkey /etc/trojan/trojan-key.pem --load-ca-certificate /etc/trojan/ca-cert.pem --load-ca-privkey /etc/trojan/ca-key.pem --template /etc/trojan/trojan.txt --outfile /etc/trojan/trojan-cert.pem >/dev/null 2>&1
	mv /etc/trojan/trojan.service /usr/lib/systemd/system/trojan.service
	groupadd -g 12345 trojan >/dev/null 2>&1
	useradd -g 12345 -s /usr/sbin/nologin trojan >/dev/null 2>&1
	chown -R trojan:trojan /etc/trojan >/dev/null 2>&1
	chmod -R 0777 /etc/trojan/trojan
	ln -s /etc/trojan/trojan /usr/bin/trojan
	systemctl daemon-reload >/dev/null 2>&1
	systemctl restart trojan.service >/dev/null 2>&1
	systemctl enable trojan.service >/dev/null 2>&1
	
	echo "所有文件安装已完成，即将结束安装...."
	sleep 3
	
	/Zero/bin/zero clean
	/Zero/bin/zero restart
	sleep 3
	
	#验证安装模式
	if [[ ${Installation_mode} == "ALL" ]]; then
		#主机模式
		clear
		echo "问候！"
		echo "您的Zero系统安装完成，以下是您的安装信息"
		echo "---------------------------------------------------------------"
		echo "OpenVPN安装信息: "
		echo "后台面板: http://"${Server_IP}":"${Apache_Port}"/admin"
		echo "账户: admin  密码: admin"
		echo "用户账户面板: http://"${Server_IP}":"${Apache_Port}"/user"
		echo "数据库管理: http://"${Server_IP}":"${Apache_Port}"/phpMyAdmin"
		echo "数据库账户: root  数据库密码: "${Database_Password}""
		echo "服务器证书密钥与线路文件下载: http://"${Server_IP}":"${Apache_Port}"/Zero_certificates_and_keys.zip"
		echo "服务器通讯密码: "${Communication_password}""
		echo "服务器PHP已经开启System Shell高级指令，请务必保管好您的通讯密码。"
		echo "Zero没有加盟商/代理后台管理系统，仅供个人非商业性使用，请您须知！"
		echo "---------------------------------------------------------------"
		echo "Zero命令信息"
		echo "Zero服务管理命令: zero restart/start/stop/state"
		echo "Zero OpenVPN开启端口命令: zero port"
		echo "小工具命令； zero tools "
		echo "快捷开机自启文件 /Zero/Config/auto_run"
		echo "---------------------------------------------------------------"
		echo "Trojan安装信息: "
		echo "IP: "${Server_IP}""
		echo "Trojan密码: "${Trojan_Pass}""
		echo "Trojan端口: 443"
		echo "Trojan安装目录: /etc/trojan"
		echo "---------------------------------------------------------------"
		echo "Trojan命令信息"
		echo "Trojan启动: systemctl start trojan.service"
		echo "Trojan停止: systemctl stop trojan.service"
		echo "Trojan重启: systemctl restart trojan.service"
		echo "Trojan状态: systemctl status trojan.service"
		echo "---------------------------------------------------------------"
		echo "端口信息"
		echo "请您在服务器后台面板 防火墙/安全组 中 开启以下端口"
		echo "TCP 1194 1195 1196 1197 8081 8082 8083 8084 443 80 "${SSH_Port}" "${Apache_Port}" "
		echo "UDP 53 67"
		echo "---------------------------------------------------------------"
		echo "其他信息"
		echo "系统时区已修改为:"$(timedatectl | grep "Asia/Hong_Kong")" "
		echo "安装后有问题联系技术  "
		echo "谢谢您!"
		echo "---------------------------------------------------------------"
	else
		#节点模式
		clear
		echo "问候！"
		echo "您的Zero节点系统安装完成，以下是您的安装信息"
		echo "---------------------------------------------------------------"
		echo "OpenVPN安装信息: "
		echo "节点版本没有任何后台面板，请您须知。"
		echo "服务器通讯密码: "${Communication_password}""
		echo "服务器PHP已经开启System Shell高级指令，请务必保管好您的通讯密码。"
		echo "---------------------------------------------------------------"
		echo "Zero命令信息"
		echo "Zero服务管理命令: zero restart/start/stop/state"
		echo "Zero OpenVPN开启端口命令: zero port"
		echo "小工具命令； zero tools "
		echo "快捷开机自启文件 /Zero/Config/auto_run"
		echo "---------------------------------------------------------------"
		echo "Trojan安装信息: "
		echo "IP: "${Server_IP}""
		echo "Trojan密码: "${Trojan_Pass}""
		echo "Trojan端口: 443"
		echo "Trojan安装目录: /etc/trojan"
		echo "---------------------------------------------------------------"
		echo "Trojan命令信息"
		echo "Trojan启动: systemctl start trojan.service"
		echo "Trojan停止: systemctl stop trojan.service"
		echo "Trojan重启: systemctl restart trojan.service"
		echo "Trojan状态: systemctl status trojan.service"
		echo "---------------------------------------------------------------"
		echo "端口信息"
		echo "请您在服务器后台面板 防火墙/安全组中 开启以下端口"
		echo "TCP 1194 1195 1196 1197 8081 8082 8083 8084 443 80 "${SSH_Port}" "${Apache_Port}" "
		echo "UDP 53 67"
		echo "---------------------------------------------------------------"
		echo "其他信息"
		echo "系统时区已修改为:"$(timedatectl | grep "Asia/Hong_Kong")" "
		echo "安装后有问题联系技术  "
		echo "谢谢您!"
		echo "---------------------------------------------------------------"
	fi
	
	
	
	return 0;
}


Uninstall_Zero()
{
	#卸载Zero
	echo "暂未开放！！！"
	return 0;
}


Installation_Selection()
{
	clear
	echo "------------------------------------------------------------------"
	echo ""
	echo "                   欢迎使用Zero Panel 2.0                         "
	echo "                   支持的系统 CentOS7 X64                         "
	echo "                   最后更新时间2024.09.08                         "
	echo "         Thank you very much for using this project!              "
	echo "   Project address: https://github.com/Shirley-Jones/Zero-Panel   "
	echo ""
	echo "------------------------------------------------------------------"
	echo
	echo "请选择安装类型："
	echo
	echo "1.全新安装+Trojan(一台服务器推荐)"
	echo "2.安装节点+Trojan"
	echo "3.卸载Zero"
	echo "4.退出脚本"
	echo
	read -p "请选择: " Install_options
	
	
	case ${Install_options} in
		"1")
			Installation_mode="ALL";
			Zero_install_guide
			Install_Zero
			return 0;
		;;
		"2")
			Installation_mode="Node";
			Zero_install_guide
			Install_Zero
			return 0;
		;;
		"3")
			Uninstall_Zero
			return 0;
		;;	
		"4")
			echo "感谢您的使用，再见！"
			exit 0;
		;;
		
		*) 
			echo "输入错误！请重新运行脚本！"
			exit 1
		;;
	esac 
	
}


Main()
{
	rm -rf /root/test.log
	rm -rf $0
	echo "Loading...";
	System_Check
	Installation_requires_software
	Detect_server_IP_address
	Installation_Selection
	return 0;
}






Main
exit 0;