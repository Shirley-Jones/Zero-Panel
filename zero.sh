#!/bin/bash
#Project address: https://github.com/Shirley-Jones/Zero-Panel
#Thank you very much for using this project!

Download_address_selection()
{
	clear 
	echo 
	echo "正在加载下载节点,请稍等..."
	
	
	#下载地址请在此设置，其他配置请不要乱动。
	Download_Host_One="https://raw.githubusercontent.com/Shirley-Jones/Zero-Panel/main/source"
	Download_Host_Two=""
	
	
	Download_Host_One_Name="Github";
	Download_Host_Two_Name="Shirley's";
	
	hostname_One="${Download_Host_One#*//}"
	hostname_One="${hostname_One%%/*}"
	
	hostname_Two="${Download_Host_Two#*//}"
	hostname_Two="${hostname_Two%%/*}"
	
	# 使用ping命令检测One连通性
	PING_OUTPUT_One=$(ping -c 4 $hostname_One)
	# 使用ping命令检测Two连通性
	PING_OUTPUT_Two=$(ping -c 4 $hostname_Two)
	
	#获取One延迟
	AVG_DELAY_One=$(echo "$PING_OUTPUT_One" | grep "avg" | awk '{print $4}' | cut -d'/' -f2 | cut -d'=' -f2 | cut -d'.' -f1)
	#获取Two延迟
	AVG_DELAY_Two=$(echo "$PING_OUTPUT_Two" | grep "avg" | awk '{print $4}' | cut -d'/' -f2 | cut -d'=' -f2 | cut -d'.' -f1)
	
	
	# 输出One平均延迟时间，并根据延迟时间设置颜色
	if [ -n "$AVG_DELAY_One" ] && [ "$AVG_DELAY_One" -le 100 ]; then
		Delay_One="[\e[32m$AVG_DELAY_One ms\e[0m] 推荐"
	elif [ -n "$AVG_DELAY_One" ] && [ "$AVG_DELAY_One" -le 200 ]; then
		Delay_One="[\e[33m$AVG_DELAY_One ms\e[0m]"
	elif [ -n "$AVG_DELAY_One" ]; then
		Delay_One="[\e[31m$AVG_DELAY_One ms\e[0m]"
	else
		Delay_One="[\e[31mN/A\e[0m]"
	fi
	
	# 输出Two平均延迟时间，并根据延迟时间设置颜色
	if [ -n "$AVG_DELAY_Two" ] && [ "$AVG_DELAY_Two" -le 100 ]; then
		Delay_Two="[\e[32m$AVG_DELAY_Two ms\e[0m] 推荐"
	elif [ -n "$AVG_DELAY_Two" ] && [ "$AVG_DELAY_Two" -le 200 ]; then
		Delay_Two="[\e[33m$AVG_DELAY_Two ms\e[0m]"
	elif [ -n "$AVG_DELAY_Two" ]; then
		Delay_Two="[\e[31m$AVG_DELAY_Two ms\e[0m]"
	else
		Delay_Two="[\e[31mN/A\e[0m]"
	fi
	
	# 使用无限循环来不断提示用户输入
	while true; do
		# 提示用户选择下载地址
		echo
		echo "请选择下载节点"
		echo -e "1、${Download_Host_One_Name} ${Delay_One}"
		echo -e "2、${Download_Host_Two_Name} ${Delay_Two}"
		read -p "请选择[1-2]: " Download_address_Option

		# 检查用户输入是否为空白
		if [[ -z ${Download_address_Option} ]]; then
			echo "输入不能为空，请重新选择！"
			continue
		fi

		# 检查用户输入是否为有效选项
		if [[ ${Download_address_Option} == "1" ]]; then
			echo "已选择【${Download_Host_One_Name}】"
			Download_Host=${Download_Host_One}
			break  # 跳出循环
		elif [[ ${Download_address_Option} == "2" ]]; then
			echo "已选择【${Download_Host_Two_Name}】"
			Download_Host=${Download_Host_Two}
			break  # 跳出循环
		else
			echo "输入错误，请重新选择！"
		fi
	done
	
	sleep 3
	
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
	
	if [[ ${Linux_OS} ==  "Ubuntu" ]]; then 
		#获取Linux发行版 版本号
		#加载文件
		source /etc/os-release
		Linux_Version=${VERSION_ID}
		# 使用bc工具进行比较，并将结果赋值给result
		result=$(echo "$Linux_Version < 20.04" | bc -l)
		 
		# 如果result是1，则New_VERSION大于VERSION
		if [ $result -eq 1 ]; then
			echo "当前Linux系统不支持安装Zero,请更换到Ubuntu20+后重新尝试!!!"
			exit 1;
		fi
	else
		echo "当前Linux系统不支持安装Zero,请更换到Ubuntu20+后重新尝试!!!"
		exit 1;
	fi
	
	if [[ "$EUID" -ne 0 ]]; then  
		echo "对不起，您需要以root身份运行"  
		exit 1;
	fi
	
	
	if [[ ! -e /dev/net/tun ]]; then  
		echo "TUN不可用"  
		exit 1;
	fi
	
	#获取代号
	Ubuntu_code=$(lsb_release -c --short)
	
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
	
	
	
	# 使用if语句和-f运算符来判断
	# 检查wget是否存在于系统的几个常见路径中
	if [ ! -f /usr/bin/wget ] && [ ! -f /bin/wget ] && [ ! -f /usr/sbin/wget ] && [ ! -f /sbin/wget ]; then
		# 尝试安装wget
		apt-get update >/dev/null 2>&1
		apt-get install wget -y >/dev/null 2>&1

		# 再次检查wget是否安装成功
		if [ ! -f /usr/bin/wget ] && [ ! -f /bin/wget ] && [ ! -f /usr/sbin/wget ] && [ ! -f /sbin/wget ]; then
			echo "wget 安装失败，强制退出程序!!!"
			exit 1
		fi
	fi
	
	# 检查curl是否存在于系统的几个常见路径中
	if [ ! -f /usr/bin/curl ] && [ ! -f /bin/curl ] && [ ! -f /usr/sbin/curl ] && [ ! -f /sbin/curl ]; then
		# 尝试安装curl
		apt-get update >/dev/null 2>&1
		apt-get install curl -y >/dev/null 2>&1

		# 再次检查curl是否安装成功
		if [ ! -f /usr/bin/curl ] && [ ! -f /bin/curl ] && [ ! -f /usr/sbin/curl ] && [ ! -f /sbin/curl ]; then
			echo "curl 安装失败，强制退出程序!!!"
			exit 1
		fi
	fi
	
	
	# 检查net-tools是否存在于系统的几个常见路径中
	if [ ! -f /usr/bin/ifconfig ] && [ ! -f /bin/ifconfig ] && [ ! -f /usr/sbin/ifconfig ] && [ ! -f /sbin/ifconfig ]; then
		# 尝试安装net-tools
		apt-get update >/dev/null 2>&1
		apt-get install net-tools -y >/dev/null 2>&1

		# 再次检查net-tools是否安装成功
		if [ ! -f /usr/bin/ifconfig ] && [ ! -f /bin/ifconfig ] && [ ! -f /usr/sbin/ifconfig ] && [ ! -f /sbin/ifconfig ]; then
			echo "net-tools 安装失败，强制退出程序!!!"
			exit 1
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
	read -p "请设置SSH端口: " SSH_Port
	while [[ ${SSH_Port} == "" ]]
	do
		echo -e "\033[31m检测到SSH端口没有输入,请重新尝试!!!\033[0m"
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
	else
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
	fi
	
	
	
	Download_address_selection
	
	
	clear
	echo 
	echo "-------------您设置的信息如下-------------"
	echo "SSH端口: ${SSH_Port}"
	echo "Apache端口: ${Apache_Port}"
	echo "通讯密码: ${Communication_password}"
	#验证安装模式
	if [[ ${Installation_mode} == "ALL" ]]; then
		echo "数据库密码: ${Database_Password}"
	else
		echo "主机/远程数据库地址: ${Database_Address}"
		echo "主机/远程数据库端口: ${Database_Ports}"
		echo "主机/远程数据库账户: ${Database_Username}"
		echo "主机/远程数据库密码: ${Database_Password}"
	fi
	
	if [[ ${Download_address_Option} == "1" ]];then
		echo "下载节点: ${Download_Host_One_Name}"
	fi
	
	if [[ ${Download_address_Option} == "2" ]];then
		echo "下载节点: ${Download_Host_Two_Name}"
	fi
	
	echo "------------------------------------------"
	sleep 1
	echo
	read -p "请确认您的安装信息无误[Y/N]: " Installation_Qualification
	if [[ ${Installation_Qualification} == "Y" ]] || [[ ${Installation_Qualification} == "y" ]];then
		# 等于
		sleep 1
		echo
		echo "您已确认安装信息，即将开始安装！"
		sleep 3
	else
		# 不等于
		sleep 1
		echo "即将返回到安装引导界面"
		sleep 2
		Zero_install_guide
	fi
	
	return 0;
}



Install_Zero()
{
	
	
	#----------开始安装----------
	
	clear
	sleep 1
	
	echo
	echo "正在初始化环境..."
	
	# 清理内存
	sync
	echo 1 > /proc/sys/vm/drop_caches
	echo 2 > /proc/sys/vm/drop_caches
	echo 3 > /proc/sys/vm/drop_caches
	# 扫描总内存
	ALL_RAM_free=$(echo `free | grep Mem | awk '{print $2 / 1024}'`|sed "s/\..*//g")
	if [[ ${ALL_RAM_free} -lt "800" ]]; then
		# 内存少于800MB  创建虚拟内存Swap 1GB
		# 扫描SWAP内存
		ALL_Swap_free=$(echo `free | grep Swap | awk '{print $2 / 1024}'`|sed "s/\..*//g")
		if [[ ${ALL_Swap_free} -lt "1024" ]]; then
			fallocate -l 1G /ZeroSwap
			ls -lh /ZeroSwap >/dev/null 2>&1
			chmod 600 /ZeroSwap
			mkswap /ZeroSwap >/dev/null 2>&1
			swapon /ZeroSwap >/dev/null 2>&1
			echo "/ZeroSwap none swap sw 0 0" >> /etc/fstab
		fi
	fi
	
	
	#设置SELinux宽容模式
	apt update >/dev/null 2>&1
	apt install selinux-utils -y >/dev/null 2>&1
	setenforce 0 >/dev/null 2>&1
	
	echo "正在安装依赖文件..."
	apt install make openssl gcc gdb net-tools unzip psmisc wget curl zip vim telnet -y >/dev/null 2>&1
	apt install telnet openssl libssl-dev automake gawk tar zip unzip net-tools psmisc gcc libxml2 bzip2 libcurl4-openssl-dev libboost-all-dev -y >/dev/null 2>&1
	
	
	echo "正在添加ondrej/php PPA..."
	# 安装software-properties-common软件管理器（这一步不是必须，有些发行版本已经安装好了）
	apt install software-properties-common -y >/dev/null 2>&1
	# 增加 ondrej/php PPA，提供了多个 PHP 版本
	add-apt-repository ppa:ondrej/php -y >/dev/null 2>&1
	ondrej_retry_count="1"
	while [ ! -f /etc/apt/sources.list.d/ondrej-ubuntu-php-${VERSION_CODENAME}.list ]; do
		# 检查重试次数是否大于或等于15
		if [[ ${ondrej_retry_count} -ge "15" ]]; then
			echo "[Ondrej/php] PPA 添加失败,请检查服务器网络环境或ondrej网站正在维护~"
			echo "安装失败，强制退出程序!!!"
			exit 1
		else
			# 增加重试计数
			ondrej_retry_count=$((${ondrej_retry_count}+1))
			# 添加 PPA
			add-apt-repository ppa:ondrej/php -y >/dev/null 2>&1
		fi
		sleep 3
	done
	
	# 再次更新
	apt update >/dev/null 2>&1
	
	echo "正在安装Apache..."
	apt install apache2 -y >/dev/null 2>&1
	apache2_retry_count="1"
	while [ ! -f /usr/bin/apache2 ] && [ ! -f /usr/sbin/apache2 ] && [ ! -f /bin/apache2 ] && [ ! -f /sbin/apache2 ]; do
		# 检查重试次数是否大于或等于15
		if [[ ${apache2_retry_count} -ge "15" ]]; then
			echo "Apache2安装失败,请检查服务器网络环境或apt安装源配置错误~"
			echo "安装失败，强制退出程序!!!"
			exit 1
		else
			# 增加重试计数
			apache2_retry_count=$((${apache2_retry_count}+1))
			# 安装 apache2
			apt install apache2 -y >/dev/null 2>&1
		fi
		sleep 3
	done
	
	echo "正在安装PHP7.4..."
	apt install php7.4 php7.4-cli php7.4-common php7.4-gd php7.4-ldap php7.4-mysql php7.4-odbc php7.4-xmlrpc -y >/dev/null 2>&1
	php7_retry_count="1"
	while [ ! -f /usr/bin/php ] && [ ! -f /usr/sbin/php ] && [ ! -f /bin/php ] && [ ! -f /sbin/php ]; do
		# 检查重试次数是否大于或等于15
		if [[ ${php7_retry_count} -ge "15" ]]; then
			echo "PHP7.4安装失败,请检查服务器网络环境或Ondrej/Sury网站正在维护~"
			echo "安装失败，强制退出程序!!!"
			exit 1
		else
			# 增加重试计数
			php7_retry_count=$((${php7_retry_count}+1))
			# 安装 PHP5.6
			apt install php7.4 php7.4-cli php7.4-common php7.4-gd php7.4-ldap php7.4-mysql php7.4-odbc php7.4-xmlrpc -y >/dev/null 2>&1
		fi
		sleep 3
	done
	
	
	sed -i "s/80/"${Apache_Port}"/g" /etc/apache2/sites-enabled/000-default.conf
	sed -i "s/Listen 80/Listen "${Apache_Port}"/g" /etc/apache2/ports.conf
	#禁用Apache目录浏览
	sed -i "s/Options Indexes FollowSymLinks/Options FollowSymLinks/g" /etc/apache2/apache2.conf
	#启用 a2enmod headers
	a2enmod headers >/dev/null 2>&1
	sed -i '/<Directory \/>/a\Header set Access-Control-Allow-Origin "*"' /etc/apache2/apache2.conf
	systemctl restart apache2.service
	systemctl enable apache2.service >/dev/null 2>&1
	
	#验证安装模式
	if [[ ${Installation_mode} == "ALL" ]]; then
		#主机模式 追加安装MySQL
		echo "正在安装Database Services..."
		apt install mariadb-test mariadb-server mysql-common -y >/dev/null 2>&1
		#apt install libmariadb-dev -y >/dev/null 2>&1
		apt install libmysqlclient-dev -y >/dev/null 2>&1
		MariaDB_retry_count="1"
		while [ ! -f /usr/bin/mysql ] && [ ! -f /usr/sbin/mysql ] && [ ! -f /bin/mysql ] && [ ! -f /sbin/mysql ]; do
			# 检查重试次数是否大于或等于15
			if [[ ${MariaDB_retry_count} -ge "15" ]]; then
				echo "MariaDB安装失败,请检查服务器网络环境或apt安装源配置错误~"
				echo "安装失败，强制退出程序!!!"
				exit 1
			else
				# 增加重试计数
				MariaDB_retry_count=$((${MariaDB_retry_count}+1))
				# 安装 MariaDB
				apt install mariadb-test mariadb-server mysql-common -y >/dev/null 2>&1
				#apt install libmariadb-dev -y >/dev/null 2>&1
				apt install libmysqlclient-dev -y >/dev/null 2>&1
			fi
			sleep 3
		done
		
		systemctl start mariadb.service >/dev/null 2>&1
		# 设置root密码
		mysql -e "USE mysql;ALTER USER 'root'@'localhost' IDENTIFIED BY '${Database_Password}';FLUSH PRIVILEGES;"
		# 尝试连接MySQL数据库
		mysql -h127.0.0.1 -P3306 -uroot -p${Database_Password} -e "exit"
		# 检查命令的返回值
		if [ $? -eq 0 ]; then
			# 连接MySQL数据库成功。
			mysql -h127.0.0.1 -P3306 -uroot -p${Database_Password} -e 'create database zero;'
			mysql -h127.0.0.1 -P3306 -uroot -p${Database_Password} -e "use mysql;GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '"${Database_Password}"' WITH GRANT OPTION;flush privileges;"
			cat >> /etc/mysql/my.cnf <<EOF
[mysqld]
bind-address = 0.0.0.0
EOF
			systemctl restart mariadb.service
			systemctl enable mariadb.service >/dev/null 2>&1
		else
			echo "连接MySQL数据库失败。请重装系统后重新尝试!"
			exit 1;
		fi
		
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
		wget -q --no-check-certificate ${Download_Host}/phpMyAdmin-5.2.1-all-languages.zip -P /var/www/html
		#wget -q --no-check-certificate https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip -P /var/www/html
		cd /var/www/html
		unzip -o /var/www/html/phpMyAdmin-5.2.1-all-languages.zip >/dev/null 2>&1
		rm -rf /var/www/html/phpMyAdmin-5.2.1-all-languages.zip
		mv /var/www/html/phpMyAdmin-5.2.1-all-languages /var/www/html/phpMyAdmin
		#请注意 phpMyAdmin 默认权限不要动 不要改0777  否则一定会报错
	else
		#解决节点版本编译失败问题
		#apt install libmariadb-dev -y >/dev/null 2>&1
		apt install libmysqlclient-dev -y >/dev/null 2>&1
	fi
	
	
	echo "正在安装Zero Core..."
	
	rm -rf /Zero
	mkdir /Zero
	
	wget -q --no-check-certificate ${Download_Host}/Zero_Core.zip -P /Zero
	cd /Zero
	unzip -o /Zero/Zero_Core.zip >/dev/null 2>&1
	rm -rf /Zero/Zero_Core.zip
	chmod -R 0777 /Zero
	# 编译Proxy与ZeroAUTH
	gcc -o /Zero/Core/ZeroAUTH.bin /Zero/Core/ZeroAUTH_V1.6.c -lmysqlclient -lcurl -lcrypto >/dev/null 2>&1
	if [ ! -f /Zero/Core/ZeroAUTH.bin ]; then
		echo "ZeroAUTH文件编译失败,请等待脚本运行完成后尝试手动编译文件到 /Zero/Core/ZeroAUTH.bin"
		echo "否则监控无法启动!!!"
	else
		rm -rf /Zero/Core/ZeroAUTH_V1.6.c
		chmod -R 0777 /Zero/Core/ZeroAUTH.bin
	fi
	gcc -o /Zero/Core/Proxy.bin /Zero/Core/Proxy.c >/dev/null 2>&1
	if [ ! -f /Zero/Core/Proxy.bin ]; then
		echo "Proxy文件编译失败,请等待脚本运行完成后尝试手动编译文件到 /Zero/Core/Proxy.bin"
		echo "否则OpenVPN Proxy无法启动!!!"
	else
		rm -rf /Zero/Core/Proxy.c
		chmod -R 0777 /Zero/Core/Proxy.bin
	fi
	
	#编译Rate
	gcc -o /Zero/Core/Rate.bin /Zero/Core/Rate.c >/dev/null 2>&1
	if [ ! -f /Zero/Core/Rate.bin ]; then
		echo "Rate文件编译失败,请等待脚本运行完成后尝试手动编译文件到 /Zero/Core/Rate.bin"
		echo "否则Rate无法启动!!!"
	else
		rm -rf /Zero/Core/Rate.c
		chmod -R 0777 /Zero/Core/Rate.bin
	fi
	
	#编译Socket
	gcc -o /Zero/Core/Socket.bin /Zero/Core/Socket.c >/dev/null 2>&1
	if [ ! -f /Zero/Core/Socket.bin ]; then
		echo "Socket文件编译失败,请等待脚本运行完成后尝试手动编译文件到 /Zero/Core/Socket.bin"
		echo "否则Socket无法启动!!!"
	else
		rm -rf /Zero/Core/Socket.c
		chmod -R 0777 /Zero/Core/Socket.bin
	fi
	
	#安装iptables
	apt install iptables -y >/dev/null 2>&1
	iptables_retry_count="1"
	while [ ! -f /usr/bin/iptables ] && [ ! -f /usr/sbin/iptables ] && [ ! -f /bin/iptables ] && [ ! -f /sbin/iptables ]; do
		# 检查重试次数是否大于或等于15
		if [[ ${iptables_retry_count} -ge "15" ]]; then
			echo "iptables安装失败,请检查服务器网络环境或apt安装源配置错误~"
			echo "安装失败，强制退出程序!!!"
			exit 1
		else
			# 增加重试计数
			iptables_retry_count=$((${iptables_retry_count}+1))
			# 安装 iptables
			apt install iptables -y >/dev/null 2>&1
		fi
		sleep 3
	done
	
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
	iptables -A INPUT -p udp -m udp --dport 54 -j ACCEPT
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
	
	# 保存规则
	iptables-save > /Zero/iptables/zero_rules.v4
	
	
	#安装OpenVPN
	apt install openvpn -y >/dev/null 2>&1
	openvpn_retry_count="1"
	while [ ! -f /usr/bin/openvpn ] && [ ! -f /usr/sbin/openvpn ] && [ ! -f /bin/openvpn ] && [ ! -f /sbin/openvpn ]; do
		# 检查重试次数是否大于或等于15
		if [[ ${openvpn_retry_count} -ge "15" ]]; then
			echo "OpenVPN安装失败,请检查服务器网络环境或apt安装源配置错误~"
			echo "安装失败，强制退出程序!!!"
			exit 1
		else
			# 增加重试计数
			openvpn_retry_count=$((${openvpn_retry_count}+1))
			# 安装 openvpn
			apt install openvpn -y >/dev/null 2>&1
		fi
		sleep 3
	done
	
	
	rm -rf /etc/openvpn
	mv /Zero/openvpn /etc/openvpn
	#启动OpenVPN
	systemctl restart openvpn@server-tcp1194.service
	systemctl restart openvpn@server-tcp1195.service
	systemctl restart openvpn@server-tcp1196.service
	systemctl restart openvpn@server-tcp1197.service
	systemctl restart openvpn@server-udp54.service
	systemctl restart openvpn@server-udp67.service
	systemctl enable openvpn@server-tcp1194.service >/dev/null 2>&1
	systemctl enable openvpn@server-tcp1195.service >/dev/null 2>&1
	systemctl enable openvpn@server-tcp1196.service >/dev/null 2>&1
	systemctl enable openvpn@server-tcp1197.service >/dev/null 2>&1
	systemctl enable openvpn@server-udp54.service >/dev/null 2>&1
	systemctl enable openvpn@server-udp67.service >/dev/null 2>&1
	
	#创建软连接（快捷方式）
	ln -s /Zero/bin/* /usr/bin
	#移动配置文件
	rm -rf /etc/sysctl.conf
	mv /Zero/Config/sysctl.conf /etc/sysctl.conf
	sysctl -p >/dev/null 2>&1
	mv /Zero/api.php /var/www/html/api.php
	sed -i "s/content1/"${Communication_password}"/g" /Zero/www/Config/API_Config.php
	sed -i "s/content1/"${Database_Address}"/g" /Zero/www/Config/MySQL.php
	sed -i "s/content2/"${Database_Ports}"/g" /Zero/www/Config/MySQL.php
	sed -i "s/content3/"${Database_Username}"/g" /Zero/www/Config/MySQL.php
	sed -i "s/content4/"${Database_Password}"/g" /Zero/www/Config/MySQL.php
	sed -i "s/content5/"${Server_IP}"/g" /Zero/www/Config/MySQL.php
	
	#修改配置文件
	sed -i "s/content1/"${Database_Address}"/g" /Zero/Config/auth_config.conf
	sed -i "s/content2/"${Database_Ports}"/g" /Zero/Config/auth_config.conf
	sed -i "s/content3/"${Database_Username}"/g" /Zero/Config/auth_config.conf
	sed -i "s/content4/"${Database_Password}"/g" /Zero/Config/auth_config.conf
	sed -i "s/content5/"${Server_IP}"/g" /Zero/Config/auth_config.conf
	sed -i "s/content5/"${Server_IP}"/g" /Zero/Config/zero_config.conf
	#配置Zero proxy服务
	mv /Zero/proxy.service /lib/systemd/system/proxy.service
	
	#配置Zero auth服务 
	mv /Zero/zero_auth.service /lib/systemd/system/zero_auth.service
	
	#配置Zero rate服务
	mv /Zero/rate.service /lib/systemd/system/rate.service
	
	#配置Zero socket服务
	mv /Zero/socket.service /lib/systemd/system/socket.service
	
	#配置开机自动执行shell脚本
	mv /Zero/auto_run.service /lib/systemd/system/auto_run.service
	
	#重新加载所有服务
	systemctl daemon-reload >/dev/null 2>&1
	#启动服务
	systemctl start socket.service >/dev/null 2>&1
	systemctl start rate.service >/dev/null 2>&1
	systemctl start zero_auth.service >/dev/null 2>&1
	systemctl start auto_run.service >/dev/null 2>&1
	systemctl restart proxy.service >/dev/null 2>&1
	#设置开机自启
	systemctl enable socket.service >/dev/null 2>&1
	systemctl enable rate.service >/dev/null 2>&1
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
	
	#修改SSH登录界面欢迎词
	rm -rf /etc/motd
	mv /Zero/Config/motd /etc/motd
	chmod -R 0644 /etc/motd
	
	echo "正在安装Trojan免域名版..."
	apt install gnutls-bin -y >/dev/null 2>&1
	rm -rf /etc/trojan
	mv /Zero/trojan /etc/trojan
	#编辑配置文件
	sed -i "s/content1/"${Server_IP}"/g" /etc/trojan/ca.txt
	sed -i "s/content2/Shirleylin/g" /etc/trojan/ca.txt
	sed -i "s/content1/"${Server_IP}"/g" /etc/trojan/trojan.txt
	sed -i "s/content2/Shirleylin/g" /etc/trojan/trojan.txt
	sed -i "s/content1/"${Database_Address}"/g" /etc/trojan/config.json
	sed -i "s/content2/"${Database_Ports}"/g" /etc/trojan/config.json
	sed -i "s/content3/"${Database_Username}"/g" /etc/trojan/config.json
	sed -i "s/content4/"${Database_Password}"/g" /etc/trojan/config.json
	certtool --generate-privkey --outfile /etc/trojan/ca-key.pem >/dev/null 2>&1
	certtool --generate-self-signed --load-privkey /etc/trojan/ca-key.pem --template /etc/trojan/ca.txt --outfile /etc/trojan/ca-cert.pem >/dev/null 2>&1
	certtool --generate-privkey --outfile /etc/trojan/trojan-key.pem >/dev/null 2>&1
	certtool --generate-certificate --load-privkey /etc/trojan/trojan-key.pem --load-ca-certificate /etc/trojan/ca-cert.pem --load-ca-privkey /etc/trojan/ca-key.pem --template /etc/trojan/trojan.txt --outfile /etc/trojan/trojan-cert.pem >/dev/null 2>&1
	mv /etc/trojan/trojan.service /usr/lib/systemd/system/trojan.service
	# 添加trojan用户并设置相关权限
	groupadd -g 12345 trojan >/dev/null 2>&1
	useradd -g 12345 -s /usr/sbin/nologin trojan >/dev/null 2>&1
	chown -R trojan:trojan /etc/trojan >/dev/null 2>&1
	chmod -R 0777 /etc/trojan/trojan
	ln -s /etc/trojan/trojan /usr/bin/trojan
	systemctl daemon-reload >/dev/null 2>&1
	systemctl restart trojan.service >/dev/null 2>&1
	systemctl enable trojan.service >/dev/null 2>&1
	
	
	#添加apache2设置
	cat >> /etc/apache2/apache2.conf <<EOF
<Directory /etc/trojan/www/>
Options FollowSymLinks
AllowOverride None
Require all granted
</Directory>
EOF
	cat >> /etc/apache2/ports.conf <<EOF
Listen 80
EOF
	cp /etc/trojan/apache2_config/trojan-web.conf /etc/apache2/sites-available/trojan-web.conf
	ln -s /etc/apache2/sites-available/trojan-web.conf /etc/apache2/sites-enabled/trojan-web.conf
	systemctl restart apache2.service >/dev/null 2>&1
	
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
		echo "后台管理: http://"${Server_IP}":"${Apache_Port}"/admin"
		echo "账户: admin  密码: admin"
		echo "用户中心: http://"${Server_IP}":"${Apache_Port}"/user"
		echo "Trojan用户中心: http://"${Server_IP}":"${Apache_Port}"/t_query"
		echo "数据库管理: http://"${Server_IP}":"${Apache_Port}"/phpMyAdmin"
		echo "数据库账户: root  数据库密码: "${Database_Password}""
		echo "服务器证书密钥与线路文件下载: http://"${Server_IP}":"${Apache_Port}"/Zero_certificates_and_keys.zip"
		echo "服务器通讯密码: "${Communication_password}""
		echo "---------------------------------------------------------------"
		echo "Zero命令信息"
		echo "Zero服务管理命令: zero restart/start/stop/state"
		echo "Zero OpenVPN开启端口命令: zero port"
		echo "小工具命令； zero tools "
		echo "快捷开机自启文件 /Zero/Config/auto_run"
		echo "---------------------------------------------------------------"
		echo "Trojan安装信息: "
		echo "IP: "${Server_IP}""
		echo "Trojan端口: 443"
		echo "---------------------------------------------------------------"
		echo "端口信息"
		echo "请您在服务器后台面板 防火墙/安全组 中 开启以下端口"
		echo "TCP 1194 1195 1196 1197 8081 8082 8083 8084 443 80 "${SSH_Port}" "${Apache_Port}" "
		echo "UDP 54 67"
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
		echo "WEB端口: "${Apache_Port}""
		echo "---------------------------------------------------------------"
		echo "Zero命令信息"
		echo "Zero服务管理命令: zero restart/start/stop/state"
		echo "Zero OpenVPN开启端口命令: zero port"
		echo "小工具命令； zero tools "
		echo "快捷开机自启文件 /Zero/Config/auto_run"
		echo "---------------------------------------------------------------"
		echo "Trojan安装信息: "
		echo "IP: "${Server_IP}""
		echo "Trojan端口: 443"
		echo "---------------------------------------------------------------"
		echo "端口信息"
		echo "请您在服务器后台面板 防火墙/安全组中 开启以下端口"
		echo "TCP 1194 1195 1196 1197 8081 8082 8083 8084 443 80 "${SSH_Port}" "${Apache_Port}" "
		echo "UDP 54 67"
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
	echo "                   欢迎使用Zero Panel 3.0                         "
	echo "                  支持的系统 Ubuntu20+ X64                        "
	echo "                   最后更新时间2024.10.05                         "
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
	# 设置全局变量，它可以自动处理安装时弹出的交互界面，仅本次脚本有效
	export DEBIAN_FRONTEND=noninteractive
	# 解决临时无网络问题
	echo "nameserver 8.8.8.8" >> /etc/resolv.conf
	System_Check
	Installation_requires_software
	Detect_server_IP_address
	Installation_Selection
	return 0;
}






Main
exit 0;