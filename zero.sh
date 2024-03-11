#!/bin/bash
#Project address: https://github.com/Shirley-Jones/OpenVPN-Zero-Panel
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
		echo "2、Shirley's"
		read -p "请选择[1-2]: " Download_address_Option
	done
	
	
	#请直接在此处修改您的下载地址
	
	if [[ ${Download_address_Option} == "1" ]];then
		echo "已选择【Github】"
		Download_Host="https://raw.githubusercontent.com/Shirley-Jones/OpenVPN-Zero-Panel/main/source"
	fi
	
	if [[ ${Download_address_Option} == "2" ]];then
		echo "已选择【Shirley's】"
		Download_Host="https://api.qiaouu.com/zero_resources"
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
	
	if [[ !${Linux_OS} ==  "CentOS" ]] || [[ !${Linux_OS} ==  "Debian" ]] || [[ !${Linux_OS} ==  "Ubuntu" ]]; then 
		echo "当前的Linux系统不支持安装Zero!!!"
		exit 1;
	fi
	
	
	#获取Linux发行版 版本号
	#加载文件
	source /etc/os-release
	Linux_Version=${VERSION_ID}
	
	
	ALL_RAM_free=$(echo `free | grep Mem | awk '{print $2 / 1024}'`|sed "s/\..*//g")
	
	if [[ ${ALL_RAM_free} -lt "800" ]]; then
		echo "警告, 系统RAM少于800MB(当前 "${ALL_RAM_free}"MB),只能安装节点服务器!!!"
		sleep 3
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
	
	if [[ ${Linux_OS} == "CentOS" ]]; then 
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
		
		if [ ! -f /usr/sbin/ifconfig ]; then
			yum install net-tools -y >/dev/null 2>&1
			if [ ! -f /usr/sbin/ifconfig ]; then
				echo "net-tools 安装失败，强制退出程序!!!"
				exit 1;
			fi
		fi
	fi
	
	if [[ ${Linux_OS} == "Debian" ]] || [[ ${Linux_OS} == "Ubuntu" ]]; then 
		
		apt-get update >/dev/null 2>&1
		
		if [ -f /etc/needrestart ]; then
			apt purge needrestart -y >/dev/null 2>&1
		fi
		
		if [ ! -f /usr/bin/wget ]; then
			apt install wget -y >/dev/null 2>&1
			if [ ! -f /usr/bin/wget ]; then
				echo "wget 安装失败，强制退出程序!!!"
				exit 1;
			fi
		fi
		
		if [ ! -f /usr/bin/curl ]; then
			apt install curl -y >/dev/null 2>&1
			if [ ! -f /usr/bin/curl ]; then
				echo "curl 安装失败，强制退出程序!!!"
				exit 1;
			fi
		fi
	
		if [ ! -f /usr/bin/ifconfig ] && [ ! -f /usr/sbin/ifconfig ] && [ ! -f /bin/ifconfig ] && [ ! -f /sbin/ifconfig ]; then
			apt install net-tools -y >/dev/null 2>&1
			if [ ! -f /usr/bin/ifconfig ] && [ ! -f /usr/sbin/ifconfig ] && [ ! -f /bin/ifconfig ] && [ ! -f /sbin/ifconfig ]; then
				echo "net-tools 安装失败，强制退出程序!!!"
				exit 1;
			fi
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
	
	echo
	read -p "请输入SSH端口号: " SSH_Port
	while [[ ${SSH_Port} == "" ]]
	do
		echo -e "\033[31m检测到SSH端口号没有输入，请重新尝试！\033[0m"
		read -p "请输入SSH端口号: " SSH_Port
	done
	
	echo
	read -p "请设置Apache端口: " Apache_Port
	while [[ ${Apache_Port} == "" ]]
	do
		echo -e "\033[31m检测到Apache端口没有输入，请重新尝试！\033[0m"
		read -p "请设置Apache端口: " Apache_Port
	done
	
	echo
	read -p "请设置通讯密码: " Communication_password
	while [[ ${Communication_password} == "" ]]
	do
		echo -e "\033[31m检测到通讯密码没有输入，请重新尝试！\033[0m"
		read -p "请设置通讯密码: " Communication_password
	done
	
	
	#验证安装模式
	if [[ ${Installation_mode} == "ALL" ]]; then
		echo
		read -p "请设置数据库密码: " Database_Password
		while [[ ${Database_Password} == "" ]]
		do
			echo -e "\033[31m检测到数据库密码没有输入，请重新尝试！\033[0m"
			read -p "请设置数据库密码: " Database_Password
		done
		OpenVPN_Api=${Server_IP}:${Apache_Port}
	else
		echo
		echo "Tips:"
		echo "API地址开头不需要添加 http:// 和 https:// 末尾也不需要加斜杆"
		echo "示例: api.google.com 如果有web端口 请加上web端口 示例: api.google.com:8888"
		echo
		read -p "请输入API地址: " OpenVPN_Api
		while [[ ${OpenVPN_Api} == "" ]]
		do
			echo -e "\033[31m检测到API地址没有输入，请重新尝试！\033[0m"
			read -p "请输入API地址: " OpenVPN_Api
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
	
	if [[ ${ALL_RAM_free} -lt "800" ]]; then
		#内存少于800MB  创建虚拟内存Swap 1GB
		fallocate -l 1G /ZeroSwap
		ls -lh /ZeroSwap >/dev/null 2>&1
		chmod 600 /ZeroSwap
		mkswap /ZeroSwap >/dev/null 2>&1
		swapon /ZeroSwap >/dev/null 2>&1
		echo "/ZeroSwap none swap sw 0 0" >> /etc/fstab
	fi
	
	
	if [[ ${Linux_OS} == "CentOS" ]]; then 
		#设置SELinux宽容模式
		setenforce 0 >/dev/null 2>&1
		sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config >/dev/null 2>&1
		yum install make openssl gcc gdb net-tools unzip psmisc wget curl zip vim telnet -y >/dev/null 2>&1
		yum install nss telnet avahi openssl openssl-libs openssl-devel lzo lzo-devel pam pam-devel automake pkgconfig gawk tar zip unzip net-tools psmisc gcc pkcs11-helper libxml2 libxml2-devel bzip2 bzip2-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel gmp gmp-devel libmcrypt libmcrypt-devel readline readline-devel libxslt libxslt-devel --skip-broken -y >/dev/null 2>&1
		yum install epel-release -y >/dev/null 2>&1
		#创建新缓存 国内服务器安装较慢请耐心等待
		yum clean all >/dev/null 2>&1
		yum makecache >/dev/null 2>&1
		if [[ ${Linux_Version} == "7" ]]; then 
			#CentOS7
			#add php 国内服务器安装较慢请耐心等待
			yum install yum-utils -y >/dev/null 2>&1
			rpm -ivh https://rpms.remirepo.net/enterprise/remi-release-7.rpm >/dev/null 2>&1
			if [ ! -f /etc/yum.repos.d/remi.repo ] && [ ! -f /etc/yum.repos.d/remi-modular.repo ] && [ ! -f remi-safe.repo ]; then
				#不存在 重新安装
				echo "remi-release安装失败，强制退出程序 -1"
				exit 1;
			fi
			yum-config-manager --enable remi-php74 -y >/dev/null 2>&1
		else
			#CentOS stream 8 9+
			#add php 国内服务器安装较慢请耐心等待
			#centos-release-stream 需要安装两次 原因不知道
			dnf install centos-release-stream -y >/dev/null 2>&1
			dnf install centos-release-stream -y >/dev/null 2>&1
			rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-${Linux_Version}.noarch.rpm >/dev/null 2>&1
			rpm -ivh http://rpms.remirepo.net/enterprise/remi-release-${Linux_Version}.rpm >/dev/null 2>&1
			dnf module enable php:remi-7.4 -y >/dev/null 2>&1
			release_stream_install="0"
			Repetitions="5"
			#-lt：less than（小于）
			#-ge：greater than or equal（大于或等于）
			while [ ${release_stream_install} -lt ${Repetitions} ]
			do
				if [ ${release_stream_install} -ge ${Repetitions} ]; then
					#大于或等于
					echo "remi-release多次安装失败，强制退出程序 -1"
					exit 1;
				fi
				
				if [ ! -f /etc/yum.repos.d/remi.repo ] && [ ! -f /etc/yum.repos.d/remi-modular.repo ] && [ ! -f remi-safe.repo ]; then
					#不存在 重新安装
					#centos-release-stream 需要安装两次 原因不知道
					dnf install centos-release-stream -y >/dev/null 2>&1
					dnf install centos-release-stream -y >/dev/null 2>&1
					rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-${Linux_Version}.noarch.rpm >/dev/null 2>&1
					rpm -ivh http://rpms.remirepo.net/enterprise/remi-release-${Linux_Version}.rpm >/dev/null 2>&1
					dnf module enable php:remi-7.4 -y >/dev/null 2>&1
					let release_stream_install++
				else
					#已安装 跳转下一步
					release_stream_install="5"
				fi
			done
		fi
		
		#创建新缓存 国内服务器安装较慢请耐心等待
		yum clean all >/dev/null 2>&1
		yum makecache >/dev/null 2>&1
	fi
	
	if [[ ${Linux_OS} == "Debian" ]] || [[ ${Linux_OS} == "Ubuntu" ]]; then 
		#--force-yes
		apt-get update >/dev/null 2>&1
		apt purge needrestart -y >/dev/null 2>&1
		DEBIAN_FRONTEND=noninteractive apt install lsb-release ca-certificates -y >/dev/null 2>&1
		DEBIAN_FRONTEND=noninteractive apt install apt-transport-https software-properties-common -y  >/dev/null 2>&1
		DEBIAN_FRONTEND=noninteractive apt install make openssl gcc gdb net-tools unzip psmisc wget curl zip vim telnet -y >/dev/null 2>&1
	fi
	
	
	#add php
	if [[ ${Linux_OS} == "Ubuntu" ]]; then
		if [[ $(lsb_release -sc) == "xenial" ]]; then
			#ubuntu 16 
			DEBIAN_FRONTEND=noninteractive apt install python-software-properties -y >/dev/null 2>&1
			add-apt-repository ppa:jczaplicki/xenial-php74-temp -y >/dev/null 2>&1
		else
			#ubuntu 18+
			add-apt-repository ppa:ondrej/php -y >/dev/null 2>&1
		fi
		
		apt-get update >/dev/null 2>&1
		#查看源中的版本:  
		#Check_PHP_Version=$(apt list 2>/dev/null | grep php7.4)
	fi
	
	if [[ ${Linux_OS} == "Debian" ]]; then
		wget -q -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg >/dev/null 2>&1
		echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list
		apt-get update >/dev/null 2>&1
	fi
	
	#lsb_release -a
	
	echo "正在安装Apache+PHP(国内服务器安装较慢请耐心等待 境外无视)..."
	
	if [[ ${Linux_OS} == "CentOS" ]]; then
		yum install httpd httpd-tools -y >/dev/null 2>&1
		yum remove php-* -y >/dev/null 2>&1
		yum install php php-cli php-common php-gd php-ldap php-mysql php-odbc php-xmlrpc -y >/dev/null 2>&1
		sed -i "s/#ServerName www.example.com:80/ServerName localhost:"${Apache_Port}"/g" /etc/httpd/conf/httpd.conf
		sed -i "s/Listen 80/Listen "${Apache_Port}"/g" /etc/httpd/conf/httpd.conf
		#禁用Apache目录浏览
		#sed -i "s/Options Indexes FollowSymLinks/Options FollowSymLinks/g" /etc/httpd/conf/httpd.conf
		systemctl restart httpd.service
		systemctl enable httpd.service >/dev/null 2>&1
	fi
	
	if [[ ${Linux_OS} == "Debian" ]] || [[ ${Linux_OS} == "Ubuntu" ]]; then 
		DEBIAN_FRONTEND=noninteractive apt install apache2 -y --force-yes >/dev/null 2>&1
		if [[ $(lsb_release -sc) == "xenial" ]]; then
			#Ubuntu16 安装PHP7.4  没有mcrypt拓展 默认不安装
			DEBIAN_FRONTEND=noninteractive apt install php7.4-cli php7.4-common php7.4-gd php7.4-ldap php7.4-mysql php7.4-odbc php7.4-xmlrpc php7.4-cli php7.4-dev php-pear libapache2-mod-php7.4 --force-yes -y >/dev/null 2>&1
		elif [[ $(lsb_release -sc) == "bionic" ]]; then
			#Ubuntu18 安装PHP7.2  没有mcrypt拓展 默认不安装
			DEBIAN_FRONTEND=noninteractive apt install php7.2-cli php7.2-common php7.2-gd php7.2-ldap php7.2-mysql php7.2-odbc php7.2-xmlrpc php7.2-cli php7.2-dev php-pear libapache2-mod-php7.2 --force-yes -y >/dev/null 2>&1
		else
			#ubuntu 20 22+ | Debian 10+ 安装7.4
			DEBIAN_FRONTEND=noninteractive apt install php7.4-cli php7.4-common php7.4-gd php7.4-ldap php7.4-mysql php7.4-odbc php7.4-xmlrpc php7.4-cli php7.4-dev php-pear libapache2-mod-php7.4 --force-yes -y >/dev/null 2>&1
			DEBIAN_FRONTEND=noninteractive apt install php7.4-mcrypt --force-yes -y >/dev/null 2>&1
		fi
		
		sed -i "s/Listen 80/Listen "${Apache_Port}"/g" /etc/apache2/ports.conf
		#禁用Apache目录浏览
		sed -i "s/Options Indexes FollowSymLinks/Options FollowSymLinks/g" /etc/apache2/apache2.conf
		systemctl restart apache2.service
		systemctl enable apache2.service >/dev/null 2>&1
	fi
	
	
	if [ ! -f /usr/bin/php ] && [ ! -f /usr/sbin/php ] && [ ! -f /bin/php ] && [ ! -f /sbin/php ]; then
		echo "PHP软件包安装失败，可能是apt源站点错误或系统版本过低！程序无法继续，请尝试更换源站点或更换最新版本的系统 Debian/Ubuntu/CentOS"
		exit 1;
	fi
	
	#验证安装模式
	if [[ ${Installation_mode} == "ALL" ]]; then
		#主机模式 追加安装MySQL
		echo "正在安装Database Services..."
		if [[ ${Linux_OS} == "CentOS" ]]; then
			yum install mariadb mariadb-server mariadb-devel -y >/dev/null 2>&1
			if [ ! -f /usr/bin/mysql ] && [ ! -f /usr/sbin/mysql ] && [ ! -f /bin/mysql ] && [ ! -f /sbin/mysql ]; then
				echo "Database(Mariadb)软件包安装失败，可能是源站点错误请反馈给Shirley！程序强制退出!!!"
				exit 1;
			fi
		fi
		
		if [[ ${Linux_OS} == "Debian" ]] || [[ ${Linux_OS} == "Ubuntu" ]]; then 
			DEBIAN_FRONTEND=noninteractive apt install mariadb-server mariadb-client -y >/dev/null 2>&1
			if [ ! -f /usr/bin/mysql ] && [ ! -f /usr/sbin/mysql ] && [ ! -f /bin/mysql ] && [ ! -f /sbin/mysql ]; then
				DEBIAN_FRONTEND=noninteractive apt install mysql-server mysql-client -y >/dev/null 2>&1
				if [ ! -f /usr/bin/mysql ] && [ ! -f /usr/sbin/mysql ] && [ ! -f /bin/mysql ] && [ ! -f /sbin/mysql ]; then
					echo "Database(Mariadb)软件包多次安装失败，可能是源站点错误请反馈给Shirley！程序强制退出!!!"
					exit 1;
				fi
			fi
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
	wget -q --no-check-certificate ${Download_Host}/Zero_Core.zip -P /Zero
	cd /Zero
	unzip -o /Zero/Zero_Core.zip >/dev/null 2>&1
	rm -rf /Zero/Zero_Core.zip
	chmod -R 0777 /Zero
	
	
	#安装iptables
	if [[ ${Linux_OS} == "CentOS" ]]; then
		yum install iptables iptables-services -y >/dev/null 2>&1
		#禁用 firewalld
		systemctl stop firewalld.service >/dev/null 2>&1
		systemctl disable firewalld.service >/dev/null 2>&1
	fi
	
	if [[ ${Linux_OS} == "Debian" ]] || [[ ${Linux_OS} == "Ubuntu" ]]; then 
		DEBIAN_FRONTEND=noninteractive apt install iptables -y >/dev/null 2>&1
	fi
	
	if [ ! -f /usr/bin/iptables ] && [ ! -f /usr/sbin/iptables ] && [ ! -f /bin/iptables ] && [ ! -f /sbin/iptables ]; then
		echo "iptables软件包安装失败，可能是apt源站点错误或系统版本过低！程序无法继续，请尝试更换源站点或更换最新版本的系统 Debian/Ubuntu/CentOS"
		exit 1;
	fi
	
	iptables -A INPUT -s 127.0.0.1/32  -j ACCEPT
	iptables -A INPUT -d 127.0.0.1/32  -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport ${SSH_Port} -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport ${Apache_Port} -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 8081 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 8082 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 8083 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 8084 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 1194 -j ACCEPT
	iptables -A INPUT -p udp -m udp --dport 636 -j ACCEPT
	iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o ${Main_network_card_name} -j MASQUERADE
	iptables -t nat -A POSTROUTING -s 10.9.0.0/24 -o ${Main_network_card_name} -j MASQUERADE
	echo "127.0.0.1 localhost" > /etc/hosts
	
	if [[ ${Linux_OS} == "CentOS" ]]; then
		service iptables save >/dev/null 2>&1
		systemctl restart iptables.service
		systemctl enable iptables.service >/dev/null 2>&1
	fi
	
	if [[ ${Linux_OS} == "Debian" ]] || [[ ${Linux_OS} == "Ubuntu" ]]; then 
		iptables-save > /Zero/iptables/iptables.rules
		echo "iptables-restore < /Zero/iptables/iptables.rules" >> /Zero/Config/auto_run
	fi 
	
	#安装OpenVPN
	
	if [[ ${Linux_OS} == "CentOS" ]]; then
		yum install openvpn openvpn-devel gcc -y >/dev/null 2>&1
	fi
	
	if [[ ${Linux_OS} == "Debian" ]] || [[ ${Linux_OS} == "Ubuntu" ]]; then 
		DEBIAN_FRONTEND=noninteractive apt install openvpn gcc -y >/dev/null 2>&1
	fi
	
	
	if [ ! -f /usr/bin/openvpn ] && [ ! -f /usr/sbin/openvpn ] && [ ! -f /bin/openvpn ] && [ ! -f /sbin/openvpn ]; then
		echo "OpenVPN软件包安装失败，可能是源站点错误或系统版本过低！程序无法继续，请尝试更换源站点或更换最新版本的系统 Debian/Ubuntu/CentOS"
		exit 1;
	fi
	
	
	rm -rf /etc/openvpn
	mv /Zero/openvpn /etc/openvpn
	#启动OpenVPN
	systemctl restart openvpn@server-tcp.service
	systemctl restart openvpn@server-udp.service
	systemctl enable openvpn@server-tcp.service >/dev/null 2>&1
	systemctl enable openvpn@server-udp.service >/dev/null 2>&1
	
	
	
	#编译OpenVPN Proxy
	if [ ! -f /Zero/Core/Proxy.c ]; then
		echo "警告，Proxy源码文件不存在，请在程序安装完成后手动编译Proxy文件到/Zero/Core/Proxy.bin  否则OpenVPN不能正常工作！！！"
		#exit 1;
	else
		rm -rf /Zero/Core/Proxy.bin
		gcc -o /Zero/Core/Proxy.bin /Zero/Core/Proxy.c >/dev/null 2>&1
		if [ ! -f /Zero/Core/Proxy.bin ]; then
			echo "OpenVPN Proxy编译失败，请在程序安装完成后手动编译Proxy文件到/Zero/Core/Proxy.bin  否则OpenVPN不能正常工作！！！"
		else
			chmod -R 0777 /Zero/Core/Proxy.bin >/dev/null 2>&1
		fi
	fi
	
	
	#创建软连接（快捷方式）
	ln -s /Zero/bin/* /usr/bin
	#移动配置文件
	rm -rf /etc/sysctl.conf
	mv /Zero/Config/sysctl.conf /etc/sysctl.conf
	sysctl -p >/dev/null 2>&1
	mv /Zero/api.php /var/www/html/api.php
	sed -i "s/Communication_password/"${Communication_password}"/g" /Zero/Config/Config.php
	#修改配置文件
	sed -i "s/API_ADDRESS/"${OpenVPN_Api}"/g" /Zero/Config/Config.php
	sed -i "s/Server_IP/"${Server_IP}"/g" /Zero/Config/Zero.conf
	sed -i "s/content1/"${Linux_OS}"/g" /Zero/Config/Zero.conf
	sed -i "s/content2/"${Linux_Version}"/g" /Zero/Config/Zero.conf
	
	
	#配置服务并设置Zero proxy开机自启
	mv /Zero/proxy.service /lib/systemd/system/proxy.service
	#添加开机自动执行shell服务 
	mv /Zero/auto_run.service /lib/systemd/system/auto_run.service

	#重新加载所有服务
	systemctl daemon-reload >/dev/null 2>&1
	#启动服务
	systemctl start auto_run.service >/dev/null 2>&1
	systemctl restart proxy.service >/dev/null 2>&1
	#设置开机自启
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
		echo "主要信息: "
		echo "后台面板: http://"${Server_IP}":"${Apache_Port}"/admin"
		echo "账户: admin  密码: admin"
		echo "用户账户面板: http://"${Server_IP}":"${Apache_Port}"/user"
		echo "数据库管理: http://"${Server_IP}":"${Apache_Port}"/phpMyAdmin"
		echo "数据库账户: root  数据库密码: "${Database_Password}""
		echo "服务器证书密钥与线路文件下载: "${Download_Host}"/Zero_certificates_and_keys.zip"
		echo "服务器通讯密码: "${Communication_password}""
		echo "服务器PHP已经开启SystemShell高级指令，请务必保管好您的通讯密码。"
		echo "Zero没有加盟商/代理后台管理系统，仅供个人非商业性使用，请您须知！"
		echo "---------------------------------------------------------------"
		echo "端口信息"
		echo "请您在服务器后台面板 防火墙/安全组 中 开启以下端口"
		echo "TCP 1194 8081 8082 8083 8084 "${SSH_Port}" "${Apache_Port}" "
		echo "UDP 636"
		echo "---------------------------------------------------------------"
		echo "温馨提醒"
		echo "OpenVPN TCP直连端口: 1194   OpenVPN UDP直连端口: 636"
		echo "如果您是在(中华人民共和国)使用海外服务器 那么不建议使用TCP UDP直连端口(容易被封端口)"
		echo "海外服务器建议使用Proxy模块进行网络代理!!! 默认已开启 TCP 8081 8082 8083 8084 代理端口"
		echo "Proxy模块具有网络加密功能，基本不会被封端口!!! 灰常安全"
		echo "---------------------------------------------------------------"
		echo "Zero命令信息"
		echo "Zero服务管理命令: zero restart/start/stop/state"
		echo "Zero OpenVPN开启端口命令: zero port"
		echo "小工具命令； zero tools "
		echo "快捷开机自启文件 /Zero/Config/auto_run"
		echo "---------------------------------------------------------------"
		echo "其他信息"
		echo "系统时区已修改为:"$(timedatectl | grep "Asia/Hong_Kong")" "
		echo "安装后有问题联系技术  "
		echo "谢谢您!"
		echo "---------------------------------------------------------------"
	else
		clear
		echo "问候！"
		echo "您的Zero节点系统安装完成，以下是您的安装信息"
		echo "---------------------------------------------------------------"
		echo "主要信息: "
		echo "节点版本没有任何后台面板，请您须知。"
		echo "服务器证书密钥与线路文件下载: "${Download_Host}"/Zero_certificates_and_keys.zip"
		echo "服务器通讯密码: "${Communication_password}""
		echo "服务器PHP已经开启SystemShell高级指令，请务必保管好您的通讯密码。"
		echo "---------------------------------------------------------------"
		echo "端口信息"
		echo "请您在服务器后台面板 防火墙/安全组中 开启以下端口"
		echo "TCP 1194 8081 8082 8083 8084 "${SSH_Port}" "${Apache_Port}" "
		echo "UDP 636"
		echo "---------------------------------------------------------------"
		echo "温馨提醒"
		echo "OpenVPN TCP直连端口: 1194   OpenVPN UDP直连端口: 636"
		echo "如果您是在(中华人民共和国)使用海外服务器 那么不建议使用TCP UDP直连端口(容易被封端口)"
		echo "海外服务器建议使用Proxy模块进行网络代理!!! 默认已开启 TCP 8081 8082 8083 8084 代理端口"
		echo "Proxy模块具有网络加密功能，基本不会被封端口!!! 灰常安全"
		echo "---------------------------------------------------------------"
		echo "Zero命令信息"
		echo "Zero服务管理命令: zero restart/start/stop/state"
		echo "Zero OpenVPN开启端口命令: zero port"
		echo "小工具命令； zero tools "
		echo "快捷开机自启文件 /Zero/Config/auto_run"
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



Zero_Simple_install_guide()
{
	clear
	sleep 1
	
	echo
	read -p "请输入SSH端口号: " SSH_Port
	while [[ ${SSH_Port} == "" ]]
	do
		echo -e "\033[31m检测到SSH端口号没有输入，请重新尝试！\033[0m"
		read -p "请输入SSH端口号: " SSH_Port
	done
	
	
	
	Download_address_selection
	
	
	sleep 1
	echo
	echo "安装信息收集已完成，即将开始安装！"
	sleep 3
	
	return 0;
}




Install_Zero_Simple()
{
	
	
		
	#----------开始安装----------
	
	clear
	sleep 1
	
	echo
	echo "正在初始化环境..."
	
	if [[ ${ALL_RAM_free} -lt "800" ]]; then
		#内存少于800MB  创建虚拟内存Swap 1GB
		fallocate -l 1G /ZeroSwap
		ls -lh /ZeroSwap >/dev/null 2>&1
		chmod 600 /ZeroSwap
		mkswap /ZeroSwap >/dev/null 2>&1
		swapon /ZeroSwap >/dev/null 2>&1
		echo "/ZeroSwap none swap sw 0 0" >> /etc/fstab
	fi
	
	
	if [[ ${Linux_OS} == "CentOS" ]]; then 
		#设置SELinux宽容模式
		setenforce 0 >/dev/null 2>&1
		sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config >/dev/null 2>&1
		yum install make openssl gcc gdb net-tools unzip psmisc wget curl zip vim telnet -y >/dev/null 2>&1
		yum install nss telnet avahi openssl openssl-libs openssl-devel lzo lzo-devel pam pam-devel automake pkgconfig gawk tar zip unzip net-tools psmisc gcc pkcs11-helper libxml2 libxml2-devel bzip2 bzip2-devel libcurl libcurl-devel libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel gmp gmp-devel libmcrypt libmcrypt-devel readline readline-devel libxslt libxslt-devel --skip-broken -y >/dev/null 2>&1
		yum install epel-release -y >/dev/null 2>&1
		#创建新缓存 国内服务器安装较慢请耐心等待
		yum clean all >/dev/null 2>&1
		yum makecache >/dev/null 2>&1
	fi
	
	if [[ ${Linux_OS} == "Debian" ]] || [[ ${Linux_OS} == "Ubuntu" ]]; then 
		#--force-yes
		apt-get update >/dev/null 2>&1
		apt purge needrestart -y >/dev/null 2>&1
		DEBIAN_FRONTEND=noninteractive apt install lsb-release ca-certificates -y >/dev/null 2>&1
		DEBIAN_FRONTEND=noninteractive apt install apt-transport-https software-properties-common -y  >/dev/null 2>&1
		DEBIAN_FRONTEND=noninteractive apt install make openssl gcc gdb net-tools unzip psmisc wget curl zip vim telnet -y >/dev/null 2>&1
	fi
	
	#lsb_release -a
	
	
	echo "正在安装Zero Core..."
	
	rm -rf /Zero
	mkdir /Zero
	wget -q --no-check-certificate ${Download_Host}/Zero_Core_Simple.zip -P /Zero
	cd /Zero
	unzip -o /Zero/Zero_Core_Simple.zip >/dev/null 2>&1
	rm -rf /Zero/Zero_Core_Simple.zip
	chmod -R 0777 /Zero
	
	
	#安装iptables
	if [[ ${Linux_OS} == "CentOS" ]]; then
		yum install iptables iptables-services -y >/dev/null 2>&1
		#禁用 firewalld
		systemctl stop firewalld.service >/dev/null 2>&1
		systemctl disable firewalld.service >/dev/null 2>&1
	fi
	
	if [[ ${Linux_OS} == "Debian" ]] || [[ ${Linux_OS} == "Ubuntu" ]]; then 
		DEBIAN_FRONTEND=noninteractive apt install iptables -y >/dev/null 2>&1
	fi
	
	if [ ! -f /usr/bin/iptables ] && [ ! -f /usr/sbin/iptables ] && [ ! -f /bin/iptables ] && [ ! -f /sbin/iptables ]; then
		echo "iptables软件包安装失败，可能是apt源站点错误或系统版本过低！程序无法继续，请尝试更换源站点或更换最新版本的系统 Debian/Ubuntu/CentOS"
		exit 1;
	fi
	
	iptables -A INPUT -s 127.0.0.1/32  -j ACCEPT
	iptables -A INPUT -d 127.0.0.1/32  -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport ${SSH_Port} -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 8081 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 8082 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 8083 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 8084 -j ACCEPT
	iptables -A INPUT -p tcp -m tcp --dport 1194 -j ACCEPT
	iptables -A INPUT -p udp -m udp --dport 636 -j ACCEPT
	iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o ${Main_network_card_name} -j MASQUERADE
	iptables -t nat -A POSTROUTING -s 10.9.0.0/24 -o ${Main_network_card_name} -j MASQUERADE
	echo "127.0.0.1 localhost" > /etc/hosts
	
	if [[ ${Linux_OS} == "CentOS" ]]; then
		service iptables save >/dev/null 2>&1
		systemctl restart iptables.service
		systemctl enable iptables.service >/dev/null 2>&1
	fi
	
	if [[ ${Linux_OS} == "Debian" ]] || [[ ${Linux_OS} == "Ubuntu" ]]; then 
		iptables-save > /Zero/iptables/iptables.rules
		echo "iptables-restore < /Zero/iptables/iptables.rules" >> /Zero/Config/auto_run
	fi 
	
	#安装OpenVPN
	
	if [[ ${Linux_OS} == "CentOS" ]]; then
		yum install openvpn openvpn-devel gcc -y >/dev/null 2>&1
	fi
	
	if [[ ${Linux_OS} == "Debian" ]] || [[ ${Linux_OS} == "Ubuntu" ]]; then 
		DEBIAN_FRONTEND=noninteractive apt install openvpn gcc -y >/dev/null 2>&1
	fi
	
	
	if [ ! -f /usr/bin/openvpn ] && [ ! -f /usr/sbin/openvpn ] && [ ! -f /bin/openvpn ] && [ ! -f /sbin/openvpn ]; then
		echo "OpenVPN软件包安装失败，可能是源站点错误或系统版本过低！程序无法继续，请尝试更换源站点或更换最新版本的系统 Debian/Ubuntu/CentOS"
		exit 1;
	fi
	
	
	rm -rf /etc/openvpn
	mv /Zero/openvpn /etc/openvpn
	#启动OpenVPN
	systemctl restart openvpn@server-tcp.service
	systemctl restart openvpn@server-udp.service
	systemctl enable openvpn@server-tcp.service >/dev/null 2>&1
	systemctl enable openvpn@server-udp.service >/dev/null 2>&1
	
	
	
	#编译OpenVPN Proxy
	if [ ! -f /Zero/Core/Proxy.c ]; then
		echo "警告，Proxy源码文件不存在，请在程序安装完成后手动编译Proxy文件到/Zero/Core/Proxy.bin  否则OpenVPN不能正常工作！！！"
		#exit 1;
	else
		rm -rf /Zero/Core/Proxy.bin
		gcc -o /Zero/Core/Proxy.bin /Zero/Core/Proxy.c >/dev/null 2>&1
		if [ ! -f /Zero/Core/Proxy.bin ]; then
			echo "OpenVPN Proxy编译失败，请在程序安装完成后手动编译Proxy文件到/Zero/Core/Proxy.bin  否则OpenVPN不能正常工作！！！"
		else
			chmod -R 0777 /Zero/Core/Proxy.bin >/dev/null 2>&1
		fi
	fi
	
	
	#创建软连接（快捷方式）
	ln -s /Zero/bin/* /usr/bin
	#移动配置文件
	rm -rf /etc/sysctl.conf
	mv /Zero/Config/sysctl.conf /etc/sysctl.conf
	sysctl -p >/dev/null 2>&1
	#修改配置文件
	sed -i "s/Server_IP/"${Server_IP}"/g" /Zero/Config/Zero.conf
	sed -i "s/content1/"${Linux_OS}"/g" /Zero/Config/Zero.conf
	sed -i "s/content2/"${Linux_Version}"/g" /Zero/Config/Zero.conf
	
	
	#配置服务并设置Zero proxy开机自启
	mv /Zero/proxy.service /lib/systemd/system/proxy.service
	#添加开机自动执行shell服务 
	mv /Zero/auto_run.service /lib/systemd/system/auto_run.service

	#重新加载所有服务
	systemctl daemon-reload >/dev/null 2>&1
	#启动服务
	systemctl start auto_run.service >/dev/null 2>&1
	systemctl start proxy.service >/dev/null 2>&1
	#设置开机自启
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
	
	
	echo "所有文件安装已完成，即将结束安装...."
	sleep 3
	
	/Zero/bin/zero clean
	/Zero/bin/zero restart
	sleep 3
	clear
	echo "问候！"
	echo "您的Zero1.0简易版系统安装完成，以下是您的安装信息"
	echo "---------------------------------------------------------------"
	echo "主要信息: "
	echo "简易版本没有任何后台面板，请您须知。"
	echo "用户身份验证文件位于/Zero/user_auth.list"
	echo "每个用户一行，用户名在前，后面跟一个或多个空格或选项卡，然后输入密码。"
	echo "服务器证书密钥与线路文件下载: "${Download_Host}"/Zero_certificates_and_keys.zip"
	echo "---------------------------------------------------------------"
	echo "端口信息"
	echo "请您在服务器后台面板 防火墙/安全组中 开启以下端口"
	echo "TCP 1194 8081 8082 8083 8084 "${SSH_Port}""
	echo "UDP 636"
	echo "---------------------------------------------------------------"
	echo "温馨提醒"
	echo "OpenVPN TCP直连端口: 1194   OpenVPN UDP直连端口: 636"
	echo "如果您是在(中华人民共和国)使用海外服务器 那么不建议使用TCP UDP直连端口(容易被封端口)"
	echo "海外服务器建议使用Proxy模块进行网络代理!!! 默认已开启 TCP 8081 8082 8083 8084 代理端口"
	echo "Proxy模块具有网络加密功能，基本不会被封端口!!! 灰常安全"
	echo "---------------------------------------------------------------"
	echo "Zero命令信息"
	echo "Zero服务管理命令: zero restart/start/stop/state"
	echo "Zero OpenVPN开启端口命令: zero port"
	echo "小工具命令； zero tools "
	echo "快捷开机自启文件 /Zero/Config/auto_run"
	echo "---------------------------------------------------------------"
	echo "其他信息"
	echo "系统时区已修改为:"$(timedatectl | grep "Asia/Hong_Kong")" "
	echo "安装后有问题联系技术  "
	echo "谢谢您!"
	echo "---------------------------------------------------------------"
	return 0;
	
	
}




Installation_Selection()
{
	clear
	echo "请选择安装类型："
	echo "Zero 1.0 (Simplified version)"
	echo "101.全新安装(一台服务器推荐)"
	echo
	echo "Zero 2.0 (Official version)"
	echo "201.全新安装(一台服务器推荐)"
	echo "202.安装节点"
	echo
	echo "Other"
	echo "001.卸载Zero"
	echo "002.退出脚本"
	echo
	read -p "请选择: " Install_options
	
	
	case ${Install_options} in
		"101")
			Zero_Simple_install_guide
			Install_Zero_Simple
			return 0;
		;;
		"201")
			if [[ ${ALL_RAM_free} -lt "800" ]]; then
				echo "警告, 系统RAM少于800MB(当前 "${ALL_RAM_free}"MB),不能选择【全新安装】!!!"
				exit 1;
			fi
			Installation_mode="ALL";
			Zero_install_guide
			Install_Zero
			return 0;
		;;
		"202")
			Installation_mode="Node";
			Zero_install_guide
			Install_Zero
			return 0;
		;;
		"001")
			Uninstall_Zero
			return 0;
		;;	
		"002")
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