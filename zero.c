#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/types.h>
#include <strings.h>
#include <string.h>
#include <time.h>
#include <pwd.h>
#include <signal.h> 
#include <errno.h>
#include <sys/wait.h>
#include <curl/curl.h>
#include <sys/stat.h>
#define OS_RELEASE_FILE "/etc/os-release"
#define UBUNTU_ID "ubuntu"
#define DEBIAN_ID "debian"
#define Scripts_Start_Name "./zero.bin"
#define Project_Version "3.0"
#define Author_Name "Shirley"
#define Project_Name "Zero Panel"  
#define Last_update_time "2025.02.04 00:00:00"  
/*
--------------------------------------------------------------------

	版权说明: 
	
	流控版权为Shirley所有！！
	
	项目开源地址: https://github.com/Shirley-Jones/Zero-Panel
	
--------------------------------------------------------------------

	下载地址说明: 
	
	请搜索 raw.githubusercontent.com 您可以快速定位到该位置。
	
	下载地址末尾不加斜杆，否则搭建会报错
	
	任何问题不要问我，不要问我，不要问我。
	
--------------------------------------------------------------------
*/

//声明函数
char* cmd_system(char* command);
char buff[1024];
int code = 0;
void Readme(char* main_network_card);
void Install_Option(char* IP,char* main_network_card);
void Install_Zero(char* IP,char* Installation_type, char* main_network_card);
void Uninstall_Zero(void);
void remove_colon(char* str);
const char *get_os_version_codename();

// 自定义函数: 获取操作系统的版本代号
const char *get_os_version_codename() {
    FILE *file;
    char *line = NULL;
    size_t len = 0;
    ssize_t read;

    file = fopen(OS_RELEASE_FILE, "r");
    if (file == NULL) {
        perror("无法打开 /etc/os-release 文件!!!");
        return NULL;
    }

    while ((read = getline(&line, &len, file)) != -1) {
        if (strstr(line, "VERSION_CODENAME=") != NULL) {
            char *codename = strchr(line, '=') + 1;
            codename[strcspn(codename, "\n")] = 0;
            fclose(file);
            free(line);
            return strdup(codename);
        }
    }

    fclose(file);
    if (line) {
        free(line);
    }

    return NULL;
}

// 自定义函数: 清空输入缓冲区
void Clear_Buffer() {
    int c;
    while ((c = getchar()) != '\n' && c != EOF);
}

// 自定义函数: 创建目录
void create_directory(const char* path, mode_t mode) {
    if (mkdir(path, mode) != 0) {
        perror("文件夹创建失败!!!");
        exit(1);
    }
}

// 自定义函数: 去除字符串中的冒号
void remove_colon(char* str) {
    char* src = str;
    char* dst = str;
    while (*src) {
        if (*src != ':') {
            *dst++ = *src;
        }
        src++;
    }
    *dst = '\0';
}

// 自定义函数: 检查当前用户是否有 root 权限
int is_root_user() {
    // 获取当前用户的 UID
    uid_t uid = getuid();
    // root 用户的 UID 是 0
    return (uid == 0);
}

// 自定义函数: 获取系统类型和版本号
int get_os_info(char *os_name, size_t os_name_size, char *os_version, size_t os_version_size) {
    FILE *file = fopen(OS_RELEASE_FILE, "r");
    if (!file) {
        perror("无法打开 /etc/os-release 文件!!!");
        return -1; // 打开文件失败
    }

    char line[256];
    int os_type = 0; // 0: unknown, 1: Ubuntu, 2: Debian
    while (fgets(line, sizeof(line), file)) {
        // 判断系统类型
        if (strstr(line, "ID=") == line) {
            char *id = strchr(line, '=') + 1;
            // 去除换行符和引号
            id[strcspn(id, "\n")] = 0;
            if (id[0] == '"') {
                memmove(id, id + 1, strlen(id));
                id[strlen(id) - 1] = 0;
            }
            if (strcmp(id, UBUNTU_ID) == 0) {
                os_type = 1; // Ubuntu
                strncpy(os_name, "Ubuntu", os_name_size);
            } else if (strcmp(id, DEBIAN_ID) == 0) {
                os_type = 2; // Debian
                strncpy(os_name, "Debian", os_name_size);
            }
        }
        // 获取版本号
        if (strstr(line, "VERSION_ID=") == line) {
            char *version = strchr(line, '=') + 1;
            // 去除换行符和引号
            version[strcspn(version, "\n")] = 0;
            if (version[0] == '"') {
                memmove(version, version + 1, strlen(version));
                version[strlen(version) - 1] = 0;
            }
            strncpy(os_version, version, os_version_size);
        }
    }

    fclose(file);
    return os_type; // 返回系统类型
}

// 自定义函数: 比较版本号
int is_version_supported(const char *os_name, const char *os_version) {
    if (strcmp(os_name, "Ubuntu") == 0) {
        // Ubuntu 版本号格式为 XX.XX（如 20.04）
        float version = atof(os_version);
        if (version >= 20.04) {
            return 1; // 版本符合要求
        } else {
            return 0; // 版本不符合要求
        }
    } else if (strcmp(os_name, "Debian") == 0) {
        // Debian 版本号格式为 X（如 10）
        int version = atoi(os_version);
        if (version >= 10) {
            return 1; // 版本符合要求
        } else {
            return 0; // 版本不符合要求
        }
    }
    return -1; // 未知系统
}

// 自定义函数: 处理返回的字符数据
size_t WriteCallback(void *ptr, size_t size, size_t nmemb, char *data) {
    strcat(data, (char*)ptr);  // 将返回的内容追加到 data 中
    return size * nmemb;
}

// 自定义函数：获取URL结果
void Obtain_URL_results(char *url, char *ip_buffer, size_t buffer_size) {
    CURL *curl;  // curl handle
    CURLcode res;  // curl function result

    // 初始化 libcurl
    curl_global_init(CURL_GLOBAL_DEFAULT);
    curl = curl_easy_init();

    if (curl) {
        // 设置目标 URL
        curl_easy_setopt(curl, CURLOPT_URL, url);
		
		// 设置 User-Agent 头，模拟浏览器
        curl_easy_setopt(curl, CURLOPT_USERAGENT, "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36");
		
        // 设置回调函数，处理服务器返回的数据
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, WriteCallback);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, ip_buffer);

        // 执行 HTTP 请求
        res = curl_easy_perform(curl);

        // 检查请求是否成功
        if (res != CURLE_OK) {
            fprintf(stderr, "curl_easy_perform() failed: %s\n", curl_easy_strerror(res));
            strncpy(ip_buffer, "Error", buffer_size);  // 出错时返回一个错误字符串
        }

        // 清理 libcurl
        curl_easy_cleanup(curl);
    }

    // 退出 libcurl
    curl_global_cleanup();
}

char* shellcmd(char* cmd, char* buff, int size)
{
  char temp[256];
  FILE* fp = NULL;
  int offset = 0;
  int len;
  
  fp = popen(cmd, "r");
  if(fp == NULL)
  {
    return NULL;
  }
 
  while(fgets(temp, sizeof(temp), fp) != NULL)
  {
    len = strlen(temp);
    if(offset + len < size)
    {
      strcpy(buff+offset, temp);
      offset += len;
    }
    else
    {
      buff[offset] = 0;
      break;
    }
  }
  
  if(fp != NULL)
  {
    pclose(fp);
  }
 
  return buff;
}
// 修改参数类型为 const char*
int Yum_Install(const char* pack) {
    char co_install[100000];
    sprintf(co_install, "yum install %s -y > /dev/null 2>&1;echo -n $?", pack);
    if (strcat(cmd_system(co_install), "0") != "0") {
        return 1;
    } else {
        return 0;
    }
}

int Yum_Uninstall(const char* pack) {
    char co_install[100000];
    sprintf(co_install, "yum remove %s -y > /dev/null 2>&1;echo -n $?", pack);
    if (strcat(cmd_system(co_install), "0") != "0") {
        return 1;
    } else {
        return 0;
    }
}

int Apt_Install(const char* pack) {
    char co_install[100000];
    sprintf(co_install, "apt install %s -y > /dev/null 2>&1;echo -n $?", pack);
    if (strcat(cmd_system(co_install), "0") != "0") {
        return 1;
    } else {
        return 0;
    }
}

int Apt_Uninstall(const char* pack) {
    char co_install[100000];
    sprintf(co_install, "apt remove %s -y > /dev/null 2>&1;echo -n $?", pack);
    if (strcat(cmd_system(co_install), "0") != "0") {
        return 1;
    } else {
        return 0;
    }
}

// 修改参数类型为 const char*
int runshell(int way, const char* content) {
    /*
    指令说明   by Shirley
    checkcode(runshell(1,""));   Yum install 快速安装指令
    checkcode(runshell(2,""));   Yum remove 快速卸载指令
    checkcode(runshell(3,""));   apt install 快速安装指令
    checkcode(runshell(4,""));   apt remove 快速卸载指令
    checkcode(runshell(5,""));   直接执行命令
    */

    if (way == 1) {
        return Yum_Install(content);
    } else if (way == 2) {
        return Yum_Uninstall(content);
    } else if (way == 3) {
        return Apt_Install(content);
    } else if (way == 4) {
        return Apt_Uninstall(content);
    } else if (way == 5) {
        char com[100000];
        sprintf(com, "%s > /dev/null 2>&1;echo -n $?", content);
        return atoi(cmd_system(com));
    } else {
        printf("\n程序逻辑错误！脚本终止...\n");
        exit(1);
    }
}

void checkcode(int code1) {
    if (code1 != 0) {
        code = code + 1;
    }
}

// 检查二进制文件是否存在于四个路径中的任意一个
int check_tool_paths(const char *filename, const char *paths[], int path_count) {
    for (int i = 0; i < path_count; i++) {
        char full_path[256]; // 假设路径长度不超过 256
        snprintf(full_path, sizeof(full_path), "%s/%s", paths[i], filename);

        // 检查文件是否存在
        if (access(full_path, F_OK) == 0) {
            return 1; // 文件存在
        }
    }
    return 0; // 文件不存在
}

// 自定义函数，用于检查文件是否存在并处理安装逻辑
void check_tool(const char *filename, const char *package, int can_install) {
    const char *paths[] = {
        "/usr/bin",
        "/usr/sbin",
        "/bin",
        "/sbin"
    };
    int path_count = sizeof(paths) / sizeof(paths[0]);

    // 检查文件是否存在于四个路径中的任意一个
    if (!check_tool_paths(filename, paths, path_count)) {
        if (can_install) {
            // 如果文件不存在且可以安装，尝试安装
            checkcode(runshell(3, package));
            // 安装后再次检查
            if (!check_tool_paths(filename, paths, path_count)) {
                printf("\n%s 安装失败，强制退出程序!!!\n", package);
                exit(1);
            }
        } else {
            // 如果文件不存在且不可安装，直接退出
            printf("\n系统环境异常，强制退出程序!!!\n");
            exit(1);
        }
    }
}

void Progress_bar(pid_t Process_pid)  
{ 	
	int i,j;
	char fh[] = {'-','-','\\','\\','|','|','/','/'};
	while(1){
		for (j = 1; j <= 50; ++j)  
		{  		
			
			printf("\r进度：[ "); 
			for (i = 1; i <= 50; ++i)  
			{  
				if(i==j){
					printf("\033[34m#\033[0m");  
				}else{
					printf("\033[33m-\033[0m");  
				}		
			}  	  	
			printf(" ] [ \033[34m %c Runing...\033[0m ]",fh[j%8]); 
			fflush(stdout);
			usleep(50*1000);
			int Process_status;
			if(waitpid(Process_pid, &Process_status, WNOHANG) == Process_pid){
				printf("\r进度：[ "); 
				for (i = 1; i <= 50; ++i)  
				{ 
					printf("\033[34m#\033[0m");  
				}  	  	
				if(errno != EINTR){
					printf(" ] [ \033[32m    done    \033[0m ]");
				}else{
					printf(" ] [ \033[32m    done    \033[0m ]"); 	
				}
				fflush(stdout);
				return;
			}
		}  	
	}
}  
  
void Start_Progress_bar(char* Process_tip,pid_t Process_pid)  
{
	printf("%s\n",Process_tip); 
	Progress_bar(Process_pid) ;
	printf("\n");
}  


int System_Check()
{
	// 检查是否有 root 权限
    if (!is_root_user()) {
        printf("\n没有 ROOT 权限，无法搭建！\n");
        exit(0);
    }
	
	char os_name[32];
    char os_version[32];

    // 获取系统信息
    int os_type = get_os_info(os_name, sizeof(os_name), os_version, sizeof(os_version));

    // 如果不是 Ubuntu 或 Debian，直接退出
    if (os_type != 1 && os_type != 2) {
        printf("无法识别的操作系统！\n");
        exit(1); // 系统不符合要求，终止程序
    }

    // 检查版本号是否符合要求
	int is_supported = is_version_supported(os_name, os_version);
	if (is_supported == 0) {
		printf("当前系统: %s, 版本: %s (不支持).\n", os_name, os_version);
		exit(1); // 版本号不符合要求，终止程序
	}
	
	// 检查可安装的工具
    check_tool("wget", "wget", 1);       // wget 可以安装
    check_tool("curl", "curl", 1);       // curl 可以安装
    check_tool("virt-what", "virt-what", 1); // virt-what 可以安装

    // 检查系统关键工具（不可安装）
    check_tool("rm", NULL, 0);           // rm 不可安装
    check_tool("cp", NULL, 0);           // cp 不可安装
    check_tool("mv", NULL, 0);           // mv 不可安装
    check_tool("mkdir", NULL, 0);        // mkdir 不可安装
    check_tool("chmod", NULL, 0);        // chmod 不可安装
	
	
	const char* tun_path = "/dev/net/tun";
    // 检查文件是否存在
    if (access(tun_path, F_OK) != 0) {
        printf("TUN不可用\n");
        exit(1);
    }
	
	
	//检查VPS虚拟化
	char* virtualization_info = cmd_system("echo `virt-what` | tr -d '\n'");
	if (strcmp(virtualization_info,"openvz")==0){
		printf("\n当前VPS的虚拟化是: %s，请更换KVM、Hyper-V虚拟化VPS或物理实体主机！\n",virtualization_info);
		exit(0);
    }
	
	// 获取网卡信息
    char* network_info = cmd_system("ifconfig");
    if (network_info == NULL) {
        printf("无法获取网卡信息，强制退出程序!!!\n");
        exit(1);
    }

    // 提取主网卡名称
    char main_network_card[128];
    sscanf(network_info, "%s", main_network_card); // 提取第一个单词（网卡名称）
    remove_colon(main_network_card); // 去除冒号

    // 检查网卡名称是否为空
    if (strlen(main_network_card) == 0) {
        printf("无法获取主网卡信息，强制退出程序!!!\n");
        exit(1);
    }
	
	Readme(main_network_card);
}

int Obtain_IP_address(char* main_network_card)
{
    char IP[100] = "";  // 存储 IP 地址的缓冲区
    char *GET_IP_url = "http://members.3322.org/dyndns/getip";  // 目标 URL
    char Obtain_IP_address_enter[1];  // 用于按回车继续

    setbuf(stdout, NULL);  // 禁用缓冲区，实时输出
    system("clear");

    printf("\n请稍等\n");

    // 获取IP地址
    Obtain_URL_results(GET_IP_url, IP, sizeof(IP));

    // 去掉获取到的 IP 地址中的换行符（如果有的话）
    IP[strcspn(IP, "\r\n")] = 0;

    // 判断获取的 IP 地址是否有效
    if (strcmp(IP, "") == 0 || strcmp(IP, "Error") == 0) {
        printf("\n无法检测您的服务器IP，请手动输入IP进行确认！\n");
        sleep(1);
        printf("\n请输入服务器IP: ");
        fgets(IP, sizeof(IP), stdin);  // 获取手动输入的IP
        // 去除末尾的换行符
        IP[strcspn(IP, "\r\n")] = 0;

        if (strlen(IP) == 0) {
            printf("\n输入错误，请重新运行脚本\n");
            exit(0);
        } else {
            printf("\n您的IP是: %s 如不正确请立即停止安装，回车继续！", IP);
            // 清除缓冲区中的残余字符，特别是换行符
            while (getchar() != '\n'); // 清除缓冲区
            // 等待用户按回车继续
            fgets(Obtain_IP_address_enter, sizeof(Obtain_IP_address_enter), stdin);  // 等待回车
			// 继续安装的代码 (取消注释后可以调用你需要的安装函数)
			Install_Option(IP,main_network_card);
        }
    } else {
        printf("\n您的IP是: %s 如不正确请立即停止安装，回车继续！", IP);
        // 清除缓冲区中的残余字符，特别是换行符
        while (getchar() != '\n'); // 清除缓冲区
        // 等待用户按回车继续
        fgets(Obtain_IP_address_enter, sizeof(Obtain_IP_address_enter), stdin);  // 等待回车
		// 继续安装的代码 (取消注释后可以调用你需要的安装函数)
		Install_Option(IP,main_network_card);
    }

    return 0;  // 返回 0 表示函数结束
}

void Readme(char* main_network_card)
{ 
	char Readme_enter;
	setbuf(stdout,NULL);
	system("clear");
	sleep(1);
	printf("------------------------------------------------------------------\n");
	printf("                  欢迎使用%s                   \n",Project_Name);
	printf("                     版本 V%s                      \n",Project_Version);
	printf("流控作者: %s \n",Author_Name);
	printf("\n");
	printf("免责声明：\n");
	printf("本程序仅用于学习交流，禁止商业，下载安装后请在24小时内删除！\n");
	printf("项目源码已经全部开源，更多说明请查看项目自述文件。\n");
	printf("项目开源地址: https://github.com/Shirley-Jones/Zero-Panel\n");
	printf("----------------------------------------------------------------\n");
	printf("-----------------------同意 请回车继续--------------------------\n");
	// 循环等待用户按回车键
    while (1) {
        Readme_enter = getchar();  // 获取用户输入

        // 如果用户按下了回车键
        if (Readme_enter == '\n') {
            Obtain_IP_address(main_network_card);
            break;  // 按下回车后退出循环
        }
        // 如果按下其他键，什么都不做
    }
	exit(0);
}



void Install_Zero(char* IP, char* Installation_type, char* main_network_card) {
	// 声明函数
	char MySQL_Host[32] = "localhost";
	char MySQL_Port[32] = "3306";
	char MySQL_User[32] = "root";
	char MySQL_Pass[32];
	char APP_Name[32];
	char Installation_Qualification[5];
	char Random_MySQL_Pass[32];
	char Download_Host_Select[20];
	char Download_Host[256];
    setbuf(stdout, NULL);
    system("clear");

    // 检测MySQL是否已安装
    if (!access("/usr/bin/mysql", 0)) {
        printf("\n错误，检测到有MySQL残留或已安装流控系统/MySQL Server，请先卸载或重装系统后在试！\n");
        exit(1);
    }

    // 判断安装类型
    if (strcmp(Installation_type, "One") == 0) {
        printf("\n开始安装%s\n",Project_Name);
        sleep(1);

        // 随机数据库密码
        strcpy(Random_MySQL_Pass, cmd_system("echo `date +%s%N | md5sum | head -c 20` | tr -d '\n'"));

        // 数据库密码
        while (1) {
            printf("\n请设置数据库密码: ");
            fgets(MySQL_Pass, sizeof(MySQL_Pass), stdin);
            MySQL_Pass[strcspn(MySQL_Pass, "\n")] = 0; // 移除换行符
            if (strcmp(MySQL_Pass, "") == 0) {
                strcpy(MySQL_Pass, Random_MySQL_Pass);
                printf("已设置数据库密码为: %s\n", MySQL_Pass);
                break;
            } else {
                printf("已设置数据库密码为: %s\n", MySQL_Pass);
                break;
            }
        }

        // APP名称
        while (1) {
            printf("\n请设置APP名称: ");
            fgets(APP_Name, sizeof(APP_Name), stdin);
            APP_Name[strcspn(APP_Name, "\n")] = 0; // 移除换行符
            if (strcmp(APP_Name, "") == 0) {
                strcpy(APP_Name, "流量卫士");
                printf("已设置APP名称为: %s\n", APP_Name);
                break;
            } else {
                printf("已设置APP名称为: %s\n", APP_Name);
                break;
            }
        }

    } else if (strcmp(Installation_type, "Two") == 0) {
        printf("\n开始安装%s节点版本\n",Project_Name);
        sleep(1);

        // 主机数据库/云数据库地址
        while (1) {
            printf("\n请输入主机数据库/云数据库地址: ");
            fgets(MySQL_Host, sizeof(MySQL_Host), stdin);
            MySQL_Host[strcspn(MySQL_Host, "\n")] = 0;
            if (strcmp(MySQL_Host, "") == 0) {
                printf("数据库地址不能为空，请重新输入。\n");
            } else {
                printf("已输入主机数据库/云数据库地址为: %s\n", MySQL_Host);
                break;
            }
        }

        // 主机数据库/云数据库端口
        while (1) {
            printf("\n请输入主机数据库/云数据库端口: ");
            fgets(MySQL_Port, sizeof(MySQL_Port), stdin);
            MySQL_Port[strcspn(MySQL_Port, "\n")] = 0;
            if (strcmp(MySQL_Port, "") == 0) {
                printf("数据库端口不能为空，请重新输入。\n");
            } else {
                printf("已输入主机数据库/云数据库端口为: %s\n", MySQL_Port);
                break;
            }
        }

        // 主机数据库/云数据库账户
        while (1) {
            printf("\n请输入主机数据库/云数据库账户: ");
            fgets(MySQL_User, sizeof(MySQL_User), stdin);
            MySQL_User[strcspn(MySQL_User, "\n")] = 0;
            if (strcmp(MySQL_User, "") == 0) {
                printf("数据库账户不能为空，请重新输入。\n");
            } else {
                printf("已输入主机数据库/云数据库账户为: %s\n", MySQL_User);
                break;
            }
        }

        // 主机数据库/云数据库密码
        while (1) {
            printf("\n请输入主机数据库/云数据库密码: ");
            fgets(MySQL_Pass, sizeof(MySQL_Pass), stdin);
            MySQL_Pass[strcspn(MySQL_Pass, "\n")] = 0;
            if (strcmp(MySQL_Pass, "") == 0) {
                printf("数据库密码不能为空，请重新输入。\n");
            } else {
                printf("已输入主机数据库/云数据库密码为: %s\n", MySQL_Pass);
                break;
            }
        }

    } else {
        printf("\n安装类型判断失败,程序逻辑错误,脚本已被终止!!!\n");
        exit(1);
    }

    // SSH端口设置
    char SSH_Port[10];
    while (1) {
        printf("\n请输入SSH端口: ");
        fgets(SSH_Port, sizeof(SSH_Port), stdin);
        SSH_Port[strcspn(SSH_Port, "\n")] = 0;
        if (strcmp(SSH_Port, "") == 0) {
            strcpy(SSH_Port, cmd_system("echo `netstat -tulpn | grep sshd | awk '{print $4}' | cut -d: -f2 | head -n 1` | tr -d '\n'"));
            printf("已输入SSH端口为: %s\n", SSH_Port);
            break;
        } else {
            printf("已输入SSH端口为: %s\n", SSH_Port);
            break;
        }
    }
	// apache端口设置
	char Apache_Port[10];
    while (1) {
		printf("\n请设置WEB端口: ");
		fgets(Apache_Port, sizeof(Apache_Port), stdin);
		Apache_Port[strcspn(Apache_Port, "\n")] = 0;
		if (strcmp(Apache_Port, "") == 0) {
			printf("WEB端口不能为空，请重新输入。\n");
		} else {
			printf("已输入WEB端口为: %s\n", Apache_Port);
			break;
		}
    }
	
	
	char Communication_password[32];
    while (1) {
		printf("\n请设置通讯密码: ");
		fgets(Communication_password, sizeof(Communication_password), stdin);
		Communication_password[strcspn(Communication_password, "\n")] = 0;
		if (strcmp(Communication_password, "") == 0) {
			printf("通讯密码不能为空，请重新输入。\n");
		} else {
			printf("已输入通讯密码为: %s\n", Communication_password);
			break;
		}
    }
	
	//下载地址 ‘name’ 在此处修改
	char Download_Host_One_Name[20] = "GitHub";
	char Download_Host_Two_Name[20] = "私有源";
	char Download_Host_Three_Name[50] = "手动指定资源位置(本机)";
	
	//下载地址请在此处修改
	char Download_Host_One[100] = "https://raw.githubusercontent.com/Shirley-Jones/Zero-Panel/master/Source";
	char Download_Host_Two[100] = "#";
	char Download_Host_Three[100] = "./";
	
	printf("\n请选择下载源");
	printf("\n1、%s",Download_Host_One_Name);
	printf("\n2、%s",Download_Host_Two_Name);
	printf("\n3、%s",Download_Host_Three_Name);
	printf("\n");
	printf("\n请选择[1-3]: ");
	fgets(Download_Host_Select, sizeof(Download_Host_Select), stdin);
    Download_Host_Select[strcspn(Download_Host_Select, "\n")] = 0;
	if (strcmp(Download_Host_Select,"1")==0){
		//资源1地址
		printf("你已选择 1、%s\n",Download_Host_One_Name);
		strcpy(Download_Host,Download_Host_One);
	}else if (strcmp(Download_Host_Select,"2")==0){
		//资源2地址
		printf("你已选择 2、%s\n",Download_Host_Two_Name);
		strcpy(Download_Host,Download_Host_Two);
	}else if (strcmp(Download_Host_Select,"3")==0){
		//资源3地址
		printf("你已选择 3、%s\n",Download_Host_Three_Name);
		while (1) {
			printf("\n请输入资源文件位置(举个栗子: /root): ");
			fgets(Download_Host, sizeof(Download_Host), stdin);
			Download_Host[strcspn(Download_Host, "\n")] = 0;
			if (strcmp(Download_Host, "") == 0) {
				printf("输入不能为空，请重新选择！\n");
			} else {
				break;
			}
		}
	}else{
		//默认资源地址
		printf("输入无效，系统自动选择 1、%s\n",Download_Host_One_Name);
		strcpy(Download_Host,Download_Host_One);
	}
	
	sleep(1);
	
	//清屏
	setbuf(stdout,NULL);
	system("clear");
	printf("\n");
	sleep(1);
	
	printf("-------------您设置的信息如下-------------\n");
	printf("SSH端口: %s\n",SSH_Port);
	printf("WEB端口: %s\n",Apache_Port);
	printf("通讯密码: %s\n",Communication_password);
	// 判断安装类型
    if (strcmp(Installation_type, "One") == 0) {
		printf("数据库密码: %s\n",MySQL_Pass);
    } else if (strcmp(Installation_type, "Two") == 0) {
		printf("主机/远程数据库地址: %s\n",MySQL_Host);
		printf("主机/远程数据库端口: %s\n",MySQL_Port);
		printf("主机/远程数据库账户: %s\n",MySQL_User);
		printf("主机/远程数据库密码: %s\n",MySQL_Pass);
    } else {
        printf("安装类型判断失败,程序逻辑错误,脚本已被终止!!!\n");
        exit(1);
    }
	// 判断下载节点
    if (strcmp(Download_Host_Select, "1") == 0) {
		printf("下载节点: %s\n",Download_Host_One_Name);
    } else if (strcmp(Download_Host_Select, "2") == 0) {
		printf("下载节点: %s\n",Download_Host_Two_Name);
	} else if (strcmp(Download_Host_Select, "3") == 0) {
		printf("下载节点: %s\n",Download_Host_Three_Name);
    } else {
        printf("下载节点判断失败,程序逻辑错误,脚本已被终止!!!\n");
        exit(1);
    }
	printf("------------------------------------------\n");
	
	printf("请确认您的安装信息无误[Y/N]: ");
	fgets(Installation_Qualification, sizeof(Installation_Qualification), stdin);
    Installation_Qualification[strcspn(Installation_Qualification, "\n")] = 0;
	if (strcmp(Installation_Qualification, "y") != 0 && strcmp(Installation_Qualification, "Y") != 0) {
        // 如果输入不是 "y" 或 "Y"，退出程序
        printf("用户取消安装，程序退出。\n");
        exit(0);
    }
	sleep(1);
	printf("请稍等...\n");
	sleep(3);
	setbuf(stdout, NULL);
    system("clear");
	
	sleep(1);
	// 开始安装
	// 创建pid进程
	pid_t Process_pid;
	
	//正在初始化环境
	Process_pid = fork();
    if (Process_pid < 0) {
        printf("当前进程出错\n");
        exit(0);
    } else if (Process_pid == 0) {
		//shell代码
		// 清理内存
		checkcode(runshell(5, "sync"));
		checkcode(runshell(5, "echo 1 > /proc/sys/vm/drop_caches"));
		checkcode(runshell(5, "echo 2 > /proc/sys/vm/drop_caches"));
		checkcode(runshell(5, "echo 3 > /proc/sys/vm/drop_caches"));

		// 扫描总内存
		char* ram_free = cmd_system("free | grep Mem | awk '{print $2 / 1024}' | sed 's/\\..*//g'");
		int all_ram_free = atoi(ram_free);

		if (all_ram_free < 800) {
			// 内存少于 800MB，创建虚拟内存 Swap 1GB
			char* swap_free = cmd_system("free | grep Swap | awk '{print $2 / 1024}' | sed 's/\\..*//g'");
			int all_swap_free = atoi(swap_free);

			if (all_swap_free < 1024) {
				checkcode(runshell(5, "fallocate -l 1G /ZeroSwap"));
				checkcode(runshell(5, "chmod 600 /ZeroSwap"));
				checkcode(runshell(5, "mkswap /ZeroSwap"));
				checkcode(runshell(5, "swapon /ZeroSwap"));
				checkcode(runshell(5, "echo '/ZeroSwap none swap sw 0 0' >> /etc/fstab"));
			}
		}

		// 设置 SELinux 宽容模式
		checkcode(runshell(3, "selinux-utils"));
		checkcode(runshell(5, "setenforce 0"));
		exit(0);
    } else {
        Start_Progress_bar("正在初始化环境...", Process_pid);
		int status;
        waitpid(Process_pid, &status, 0); // 等待子进程结束

        if (WIFEXITED(status)) {
            int exit_status = WEXITSTATUS(status);
            if (exit_status != 0) {
                printf("子进程执行过程中出现错误，父进程退出!!!\n");
                exit(1); // 父进程退出
            }
        }
    }
	
	
	
	
	Process_pid = fork();
    if (Process_pid < 0) {
        printf("当前进程出错\n");
        exit(0);
    } else if (Process_pid == 0) {
        //shell代码
		checkcode(runshell(3, "make openssl gcc gdb net-tools unzip psmisc wget curl zip vim telnet"));
		checkcode(runshell(3, "telnet openssl libssl-dev automake gawk tar zip unzip net-tools psmisc gcc libxml2 bzip2 libcurl4-openssl-dev libboost-all-dev"));
		exit(0);
    } else {
        Start_Progress_bar("正在安装系统程序...", Process_pid);
		int status;
        waitpid(Process_pid, &status, 0); // 等待子进程结束

        if (WIFEXITED(status)) {
            int exit_status = WEXITSTATUS(status);
            if (exit_status != 0) {
                printf("子进程执行过程中出现错误，父进程退出!!!\n");
                exit(1); // 父进程退出
            }
        }
    }
	
	// 正在安装Apache+PHP
	Process_pid = fork();
    if (Process_pid < 0) {
        printf("当前进程出错\n");
        exit(0);
    } else if (Process_pid == 0) {
        //shell代码
		char System_Command[512];
		checkcode(runshell(3, "software-properties-common"));
		checkcode(runshell(5, "add-apt-repository ppa:ondrej/php -y"));
		
		// 获取操作系统的版本代号
		const char *codename = get_os_version_codename();
		if (codename == NULL) {
			printf("无法获取操作系统的版本代号\n");
			exit(1);
		}
		
		// 生成文件路径
		char ondrej_name[256];
		snprintf(ondrej_name, sizeof(ondrej_name), "/etc/apt/sources.list.d/ondrej-ubuntu-php-%s.list", codename);
		int ondrej_retry_count = 1;
		while (access(ondrej_name, F_OK) != 0) {
			if (ondrej_retry_count >= 15) {
				printf("[Ondrej/php] PPA 添加失败,请检查服务器网络环境或 ondrej 网站正在维护~\n");
				printf("安装失败，强制退出程序!!!\n");
				exit(1);
			}
			checkcode(runshell(5, "add-apt-repository ppa:ondrej/php -y"));
			ondrej_retry_count++;
			sleep(3);
		}
		free((void *)codename); // 释放动态分配的内存
		
		// 再次更新
		checkcode(runshell(5, "apt update"));
		
		checkcode(runshell(3, "apache2"));
		int apache2_retry_count = 1;
		while (access("/usr/bin/apache2", F_OK) != 0 && access("/usr/sbin/apache2", F_OK) != 0 && access("/bin/apache2", F_OK) != 0 && access("/sbin/apache2", F_OK) != 0) {
			if (apache2_retry_count >= 15) {
				printf("Apache2 安装失败,请检查服务器网络环境或 apt 安装源配置错误~\n");
				printf("安装失败，强制退出程序!!!\n");
				exit(1);
			}
			checkcode(runshell(3, "apache2"));
			apache2_retry_count++;
			sleep(3);
		}
		checkcode(runshell(3, "php7.4 php7.4-cli php7.4-common php7.4-gd php7.4-ldap php7.4-mysql php7.4-odbc php7.4-xmlrpc"));
		int php7_retry_count = 1;
		while (access("/usr/bin/php", F_OK) != 0 && access("/usr/sbin/php", F_OK) != 0 && access("/bin/php", F_OK) != 0 && access("/sbin/php", F_OK) != 0) {
			if (php7_retry_count >= 15) {
				printf("PHP7.4 安装失败,请检查服务器网络环境或 Ondrej/Sury 网站正在维护~\n");
				printf("安装失败，强制退出程序!!!\n");
				exit(1);
			}
			checkcode(runshell(3, "php7.4 php7.4-cli php7.4-common php7.4-gd php7.4-ldap php7.4-mysql php7.4-odbc php7.4-xmlrpc"));
			php7_retry_count++;
			sleep(3);
		}

		// 修改 Apache 配置
		snprintf(System_Command, sizeof(System_Command),"sed -i 's/80/%s/g' /etc/apache2/sites-enabled/000-default.conf",Apache_Port);
		checkcode(runshell(5,System_Command));
		snprintf(System_Command, sizeof(System_Command),"sed -i 's/Listen 80/Listen %s/g' /etc/apache2/ports.conf",Apache_Port);
		checkcode(runshell(5,System_Command));
		checkcode(runshell(5, "sed -i 's/Options Indexes FollowSymLinks/Options FollowSymLinks/g' /etc/apache2/apache2.conf"));
		checkcode(runshell(5, "a2enmod headers"));
		checkcode(runshell(5, "sed -i '/<Directory \\/>/a\\Header set Access-Control-Allow-Origin \"*\"' /etc/apache2/apache2.conf"));
		checkcode(runshell(5, "systemctl restart apache2.service"));
		checkcode(runshell(5, "systemctl enable apache2.service"));
		exit(0);
    } else {
		// 父进程
        Start_Progress_bar("正在安装Apache+PHP...", Process_pid);
        int status;
        waitpid(Process_pid, &status, 0); // 等待子进程结束

        if (WIFEXITED(status)) {
            int exit_status = WEXITSTATUS(status);
            if (exit_status != 0) {
                printf("子进程执行过程中出现错误，父进程退出!!!\n");
                exit(1); // 父进程退出
            }
        }
    }
	
	// 验证安装模式
    if (strcmp(Installation_type, "One") == 0) {
		Process_pid = fork();
		if (Process_pid < 0) {
			printf("当前进程出错\n");
			exit(0);
		} else if (Process_pid == 0) {
			//shell代码
			char System_Command[512];
			checkcode(runshell(3, "mariadb-test mariadb-server mysql-common"));
			checkcode(runshell(3, "libmysqlclient-dev"));
			int mariadb_retry_count = 1;
			while (access("/usr/bin/mysql", F_OK) != 0 && access("/usr/sbin/mysql", F_OK) != 0 && access("/bin/mysql", F_OK) != 0 && access("/sbin/mysql", F_OK) != 0) {
				if (mariadb_retry_count >= 15) {
					printf("MariaDB 安装失败,请检查服务器网络环境或 apt 安装源配置错误~\n");
					printf("安装失败，强制退出程序!!!\n");
					exit(1);
				}
				checkcode(runshell(3, "mariadb-test mariadb-server mysql-common"));
				checkcode(runshell(3, "libmysqlclient-dev"));
				mariadb_retry_count++;
				sleep(3);
			}

			checkcode(runshell(5, "systemctl start mariadb.service"));
			snprintf(System_Command, sizeof(System_Command),"mysql -e \"USE mysql;ALTER USER 'root'@'localhost' IDENTIFIED BY '%s';FLUSH PRIVILEGES;\"",MySQL_Pass);
			checkcode(runshell(5,System_Command));
			
			snprintf(System_Command, sizeof(System_Command),"mysql -h127.0.0.1 -P3306 -uroot -p%s -e 'create database zero;'",MySQL_Pass);
			checkcode(runshell(5,System_Command));
			
			snprintf(System_Command, sizeof(System_Command),"mysql -h127.0.0.1 -P3306 -uroot -p%s -e \"use mysql;GRANT ALL PRIVILEGES ON *.* TO 'root'@'%%' IDENTIFIED BY '%s' WITH GRANT OPTION;flush privileges;\"",MySQL_Pass, MySQL_Pass);
			checkcode(runshell(5,System_Command));
			
			checkcode(runshell(5, "echo '[mysqld]\nbind-address = 0.0.0.0' >> /etc/mysql/my.cnf"));
			checkcode(runshell(5, "systemctl restart mariadb.service"));
			checkcode(runshell(5, "systemctl enable mariadb.service"));
			exit(0);
		} else {
			Start_Progress_bar("正在安装MySQL...", Process_pid);
			int status;
			waitpid(Process_pid, &status, 0); // 等待子进程结束

			if (WIFEXITED(status)) {
				int exit_status = WEXITSTATUS(status);
				if (exit_status != 0) {
					printf("子进程执行过程中出现错误，父进程退出!!!\n");
					exit(1); // 父进程退出
				}
			}
		}
		
		Process_pid = fork();
		if (Process_pid < 0) {
			printf("当前进程出错\n");
			exit(0);
		} else if (Process_pid == 0) {
			//shell代码
			char System_Command[512];
			checkcode(runshell(5, "rm -rf /var/www/html/*"));
			
			if (strcmp(Download_Host_Select, "3") == 0) {
				snprintf(System_Command, sizeof(System_Command), "cp %s/Zero_Panel.zip /var/www/html/Zero_Panel.zip", Download_Host);
				checkcode(runshell(5, System_Command));
			} else {
				snprintf(System_Command, sizeof(System_Command), "wget -q --no-check-certificate %s/Zero_Panel.zip -P /var/www/html", Download_Host);
				checkcode(runshell(5, System_Command));
			}
			
			checkcode(runshell(5, "unzip -o /var/www/html/Zero_Panel.zip -d /var/www/html"));
			checkcode(runshell(5, "rm -rf /var/www/html/Zero_Panel.zip"));
			checkcode(runshell(5, "chmod -R 0777 /var/www/html/*"));

			// 修改数据库信息
			checkcode(runshell(5, "sed -i 's/Zero_MySQL_Host/127.0.0.1/g' /var/www/html/Config/MySQL.php"));
			checkcode(runshell(5, "sed -i 's/Zero_MySQL_Port/3306/g' /var/www/html/Config/MySQL.php"));
			checkcode(runshell(5, "sed -i 's/Zero_MySQL_User/root/g' /var/www/html/Config/MySQL.php"));
			snprintf(System_Command, sizeof(System_Command),"sed -i 's/Zero_MySQL_Pass/%s/g' /var/www/html/Config/MySQL.php",MySQL_Pass);
			checkcode(runshell(5,System_Command));

			// 导入数据表到数据库
			snprintf(System_Command, sizeof(System_Command),"sed -i 's/server_ip_modify/%s/g' /var/www/html/new_zero.sql",IP);
			checkcode(runshell(5,System_Command));
			
			snprintf(System_Command, sizeof(System_Command),"sed -i 's/server_port_modify/%s/g' /var/www/html/new_zero.sql",Apache_Port);
			checkcode(runshell(5,System_Command));
			
			snprintf(System_Command, sizeof(System_Command),"sed -i 's/server_realm_name_modify/%s/g' /var/www/html/new_zero.sql",IP);
			checkcode(runshell(5,System_Command));
			
			snprintf(System_Command, sizeof(System_Command),"sed -i 's/server_api_key_modify/%s/g' /var/www/html/new_zero.sql",Communication_password);
			checkcode(runshell(5,System_Command));
			
			snprintf(System_Command, sizeof(System_Command),"mysql -uroot -p%s zero < /var/www/html/new_zero.sql",MySQL_Pass);
			checkcode(runshell(5,System_Command));
			
			checkcode(runshell(5, "rm -rf /var/www/html/new_zero.sql"));

			// 安装 phpMyAdmin
		
			if (strcmp(Download_Host_Select, "3") == 0) {
				snprintf(System_Command, sizeof(System_Command), "cp %s/phpMyAdmin-5.2.1-all-languages.zip /var/www/html/phpMyAdmin-5.2.1-all-languages.zip", Download_Host);
				checkcode(runshell(5, System_Command));
			} else {
				snprintf(System_Command, sizeof(System_Command), "wget -q --no-check-certificate %s/phpMyAdmin-5.2.1-all-languages.zip -P /var/www/html", Download_Host);
				checkcode(runshell(5, System_Command));
			}
			checkcode(runshell(5, "unzip -o /var/www/html/phpMyAdmin-5.2.1-all-languages.zip -d /var/www/html"));
			checkcode(runshell(5, "rm -rf /var/www/html/phpMyAdmin-5.2.1-all-languages.zip"));
			checkcode(runshell(5, "mv /var/www/html/phpMyAdmin-5.2.1-all-languages /var/www/html/phpMyAdmin"));
			exit(0);
		} else {
			Start_Progress_bar("正在安装Zero Panel...", Process_pid);
			int status;
			waitpid(Process_pid, &status, 0); // 等待子进程结束

			if (WIFEXITED(status)) {
				int exit_status = WEXITSTATUS(status);
				if (exit_status != 0) {
					printf("子进程执行过程中出现错误，父进程退出!!!\n");
					exit(1); // 父进程退出
				}
			}
		}
	} else if (strcmp(Installation_type, "Two") == 0) {
		Process_pid = fork();
		if (Process_pid < 0) {
			printf("当前进程出错\n");
			exit(0);
		} else if (Process_pid == 0) {
			//shell代码
			// 解决节点版本编译失败问题
			checkcode(runshell(3, "libmysqlclient-dev"));
			exit(0);
		} else {
			Start_Progress_bar("正在安装MySQL拓展...", Process_pid);
			int status;
			waitpid(Process_pid, &status, 0); // 等待子进程结束

			if (WIFEXITED(status)) {
				int exit_status = WEXITSTATUS(status);
				if (exit_status != 0) {
					printf("子进程执行过程中出现错误，父进程退出!!!\n");
					exit(1); // 父进程退出
				}
			}
		}
    } else {
        printf("\n安装类型判断失败,程序逻辑错误,脚本已被终止!!!\n");
        exit(1);
    }
	
	
	Process_pid = fork();
    if (Process_pid < 0) {
        printf("当前进程出错\n");
        exit(0);
    } else if (Process_pid == 0) {
        //shell代码
		char System_Command[512];
		// 删除旧目录并创建新目录
		checkcode(runshell(5, "rm -rf /Zero"));
		create_directory("/Zero", 0777);

		// 下载 Zero_Core.zip
		if (strcmp(Download_Host_Select, "3") == 0) {
			snprintf(System_Command, sizeof(System_Command), "cp %s/Zero_Core.zip /Zero/Zero_Core.zip", Download_Host);
			checkcode(runshell(5, System_Command));
		} else {
			snprintf(System_Command, sizeof(System_Command), "wget -q --no-check-certificate %s/Zero_Core.zip -P /Zero", Download_Host);
			checkcode(runshell(5, System_Command));
		}

		// 解压 Zero_Core.zip
		checkcode(runshell(5, "unzip -o /Zero/Zero_Core.zip -d /Zero"));
		checkcode(runshell(5, "rm -rf /Zero/Zero_Core.zip"));
		checkcode(runshell(5, "chmod -R 0777 /Zero"));
		
		checkcode(runshell(5, "gcc -o /Zero/Core/ZeroAUTH.bin /Zero/Core/ZeroAUTH_V1.6.c -lmysqlclient -lcurl -lcrypto"));
		if (access("/Zero/Core/ZeroAUTH.bin", F_OK) != 0) {
			printf("ZeroAUTH文件编译失败,请等待脚本运行完成后尝试手动编译文件到 /Zero/Core/ZeroAUTH.bin\n");
			printf("否则监控无法启动!!!\n");
		} else {
			checkcode(runshell(5, "rm -rf /Zero/Core/ZeroAUTH_V1.6.c"));
			checkcode(runshell(5, "chmod -R 0777 /Zero/Core/ZeroAUTH.bin"));
		}
		
		checkcode(runshell(5, "gcc -o /Zero/Core/Proxy.bin /Zero/Core/Proxy.c"));
		if (access("/Zero/Core/Proxy.bin", F_OK) != 0) {
			printf("Proxy文件编译失败,请等待脚本运行完成后尝试手动编译文件到 /Zero/Core/Proxy.bin\n");
			printf("否则OpenVPN Proxy无法启动!!!\n");
		} else {
			checkcode(runshell(5, "rm -rf /Zero/Core/Proxy.c"));
			checkcode(runshell(5, "chmod -R 0777 /Zero/Core/Proxy.bin"));
		}
		
		checkcode(runshell(5, "gcc -o /Zero/Core/Rate.bin /Zero/Core/Rate.c"));
		if (access("/Zero/Core/Rate.bin", F_OK) != 0) {
			printf("Rate文件编译失败,请等待脚本运行完成后尝试手动编译文件到 /Zero/Core/Rate.bin\n");
			printf("否则Rate无法启动!!!\n");
		} else {
			checkcode(runshell(5, "rm -rf /Zero/Core/Rate.c"));
			checkcode(runshell(5, "chmod -R 0777 /Zero/Core/Rate.bin"));
		}
		
		
		checkcode(runshell(5, "gcc -o /Zero/Core/Socket.bin /Zero/Core/Socket.c"));
		if (access("/Zero/Core/Socket.bin", F_OK) != 0) {
			printf("Socket文件编译失败,请等待脚本运行完成后尝试手动编译文件到 /Zero/Core/Socket.bin\n");
			printf("否则Socket无法启动!!!\n");
		} else {
			checkcode(runshell(5, "rm -rf /Zero/Core/Socket.c"));
			checkcode(runshell(5, "chmod -R 0777 /Zero/Core/Socket.bin"));
		}
		
		checkcode(runshell(3, "iptables"));
		int iptables_retry_count = 1;
		while (access("/usr/bin/iptables", F_OK) != 0 && access("/usr/sbin/iptables", F_OK) != 0 && access("/bin/iptables", F_OK) != 0 && access("/sbin/iptables", F_OK) != 0) {
			if (iptables_retry_count >= 15) {
				printf("iptables安装失败,请检查服务器网络环境或apt安装源配置错误~\n");
				printf("安装失败，强制退出程序!!!\n");
				exit(1);
			}
			checkcode(runshell(3, "iptables"));
			iptables_retry_count++;
			sleep(3);
		}
		
		
		checkcode(runshell(5, "iptables -A INPUT -s 127.0.0.1/32 -j ACCEPT"));
		checkcode(runshell(5, "iptables -A INPUT -d 127.0.0.1/32 -j ACCEPT"));
		snprintf(System_Command, sizeof(System_Command), "iptables -A INPUT -p tcp -m tcp --dport %s -j ACCEPT", SSH_Port);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "iptables -A INPUT -p tcp -m tcp --dport %s -j ACCEPT", Apache_Port);
		checkcode(runshell(5, System_Command));
		checkcode(runshell(5, "iptables -A INPUT -p tcp -m tcp --dport 8081 -j ACCEPT"));
		checkcode(runshell(5, "iptables -A INPUT -p tcp -m tcp --dport 8082 -j ACCEPT"));
		checkcode(runshell(5, "iptables -A INPUT -p tcp -m tcp --dport 8083 -j ACCEPT"));
		checkcode(runshell(5, "iptables -A INPUT -p tcp -m tcp --dport 8084 -j ACCEPT"));
		checkcode(runshell(5, "iptables -A INPUT -p tcp -m tcp --dport 1194 -j ACCEPT"));
		checkcode(runshell(5, "iptables -A INPUT -p tcp -m tcp --dport 1195 -j ACCEPT"));
		checkcode(runshell(5, "iptables -A INPUT -p tcp -m tcp --dport 1196 -j ACCEPT"));
		checkcode(runshell(5, "iptables -A INPUT -p tcp -m tcp --dport 1197 -j ACCEPT"));
		checkcode(runshell(5, "iptables -A INPUT -p udp -m udp --dport 54 -j ACCEPT"));
		checkcode(runshell(5, "iptables -A INPUT -p udp -m udp --dport 67 -j ACCEPT"));
		checkcode(runshell(5, "iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT"));
		checkcode(runshell(5, "iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT"));
		checkcode(runshell(5, "iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT"));
		checkcode(runshell(5, "iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT"));
		snprintf(System_Command, sizeof(System_Command), "iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o %s -j MASQUERADE", main_network_card);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "iptables -t nat -A POSTROUTING -s 10.1.0.0/24 -o %s -j MASQUERADE", main_network_card);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "iptables -t nat -A POSTROUTING -s 10.2.0.0/24 -o %s -j MASQUERADE", main_network_card);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "iptables -t nat -A POSTROUTING -s 10.3.0.0/24 -o %s -j MASQUERADE", main_network_card);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "iptables -t nat -A POSTROUTING -s 10.4.0.0/24 -o %s -j MASQUERADE", main_network_card);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "iptables -t nat -A POSTROUTING -s 10.5.0.0/24 -o %s -j MASQUERADE", main_network_card);
		checkcode(runshell(5, System_Command));
		checkcode(runshell(5, "echo '127.0.0.1 localhost' > /etc/hosts"));
		checkcode(runshell(5, "iptables-save > /Zero/iptables/zero_rules.v4"));
		
		
		checkcode(runshell(3, "openvpn"));

		int openvpn_retry_count = 1;
		while (access("/usr/bin/openvpn", F_OK) != 0 && access("/usr/sbin/openvpn", F_OK) != 0 && access("/bin/openvpn", F_OK) != 0 && access("/sbin/openvpn", F_OK) != 0) {
			if (openvpn_retry_count >= 15) {
				printf("OpenVPN安装失败,请检查服务器网络环境或apt安装源配置错误~\n");
				printf("安装失败，强制退出程序!!!\n");
				exit(1);
			}
			checkcode(runshell(3, "openvpn"));
			openvpn_retry_count++;
			sleep(3);
		}
		checkcode(runshell(5, "rm -rf /etc/openvpn"));
		checkcode(runshell(5, "mv /Zero/openvpn /etc/openvpn"));
		checkcode(runshell(5, "systemctl restart openvpn@server-tcp1194.service"));
		checkcode(runshell(5, "systemctl restart openvpn@server-tcp1195.service"));
		checkcode(runshell(5, "systemctl restart openvpn@server-tcp1196.service"));
		checkcode(runshell(5, "systemctl restart openvpn@server-tcp1197.service"));
		checkcode(runshell(5, "systemctl restart openvpn@server-udp54.service"));
		checkcode(runshell(5, "systemctl restart openvpn@server-udp67.service"));
		checkcode(runshell(5, "systemctl enable openvpn@server-tcp1194.service"));
		checkcode(runshell(5, "systemctl enable openvpn@server-tcp1195.service"));
		checkcode(runshell(5, "systemctl enable openvpn@server-tcp1196.service"));
		checkcode(runshell(5, "systemctl enable openvpn@server-tcp1197.service"));
		checkcode(runshell(5, "systemctl enable openvpn@server-udp54.service"));
		checkcode(runshell(5, "systemctl enable openvpn@server-udp67.service"));
		checkcode(runshell(5,"ln -s /Zero/bin/* /usr/bin"));
		checkcode(runshell(5,"rm -rf /etc/sysctl.conf"));
		checkcode(runshell(5,"mv /Zero/Config/sysctl.conf /etc/sysctl.conf"));
		checkcode(runshell(5,"sysctl -p"));
		checkcode(runshell(5,"mv /Zero/api.php /var/www/html/api.php"));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content1/%s/g' /Zero/www/Config/API_Config.php", Communication_password);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content1/%s/g' /Zero/www/Config/MySQL.php", MySQL_Host);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content2/%s/g' /Zero/www/Config/MySQL.php", MySQL_Port);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content3/%s/g' /Zero/www/Config/MySQL.php", MySQL_User);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content4/%s/g' /Zero/www/Config/MySQL.php", MySQL_Pass);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content5/%s/g' /Zero/www/Config/MySQL.php", IP);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content1/%s/g' /Zero/Config/auth_config.conf", MySQL_Host);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content2/%s/g' /Zero/Config/auth_config.conf", MySQL_Port);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content3/%s/g' /Zero/Config/auth_config.conf", MySQL_User);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content4/%s/g' /Zero/Config/auth_config.conf", MySQL_Pass);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content5/%s/g' /Zero/Config/auth_config.conf", IP);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content5/%s/g' /Zero/Config/zero_config.conf", IP);
		checkcode(runshell(5, System_Command));
		checkcode(runshell(5,"mv /Zero/proxy.service /lib/systemd/system/proxy.service"));
		checkcode(runshell(5,"mv /Zero/zero_auth.service /lib/systemd/system/zero_auth.service"));
		checkcode(runshell(5,"mv /Zero/rate.service /lib/systemd/system/rate.service"));
		checkcode(runshell(5,"mv /Zero/socket.service /lib/systemd/system/socket.service"));
		checkcode(runshell(5,"mv /Zero/auto_run.service /lib/systemd/system/auto_run.service"));
		checkcode(runshell(5,"systemctl daemon-reload"));
		checkcode(runshell(5,"systemctl start socket.service"));
		checkcode(runshell(5,"systemctl start rate.service"));
		checkcode(runshell(5,"systemctl start zero_auth.service"));
		checkcode(runshell(5,"systemctl start auto_run.service"));
		checkcode(runshell(5,"systemctl restart proxy.service"));
		checkcode(runshell(5,"systemctl enable socket.service"));
		checkcode(runshell(5,"systemctl enable rate.service"));
		checkcode(runshell(5,"systemctl enable zero_auth.service"));
		checkcode(runshell(5,"systemctl enable auto_run.service"));
		checkcode(runshell(5,"systemctl enable proxy.service"));
		checkcode(runshell(5,"rm -rf /etc/motd"));
		checkcode(runshell(5,"mv /Zero/Config/motd /etc/motd"));
		checkcode(runshell(5,"chmod -R 0644 /etc/motd"));
		
		exit(0);
    } else {
        Start_Progress_bar("正在安装Zero Core...", Process_pid);
		int status;
        waitpid(Process_pid, &status, 0); // 等待子进程结束

        if (WIFEXITED(status)) {
            int exit_status = WEXITSTATUS(status);
            if (exit_status != 0) {
                printf("子进程执行过程中出现错误，父进程退出!!!\n");
                exit(1); // 父进程退出
            }
        }
    }
	
	
	Process_pid = fork();
    if (Process_pid < 0) {
        printf("当前进程出错\n");
        exit(0);
    } else if (Process_pid == 0) {
        //shell代码
		char System_Command[512];
		checkcode(runshell(3, "gnutls-bin"));
		checkcode(runshell(5, "rm -rf /etc/trojan"));
		checkcode(runshell(5, "mv /Zero/trojan /etc/trojan"));

		// 编辑配置文件
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content1/%s/g' /etc/trojan/ca.txt", IP);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content2/Shirleylin/g' /etc/trojan/ca.txt");
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content1/%s/g' /etc/trojan/trojan.txt", IP);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content2/Shirleylin/g' /etc/trojan/trojan.txt");
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content1/%s/g' /etc/trojan/config.json", MySQL_Host);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content2/%s/g' /etc/trojan/config.json", MySQL_Port);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content3/%s/g' /etc/trojan/config.json", MySQL_User);
		checkcode(runshell(5, System_Command));
		snprintf(System_Command, sizeof(System_Command), "sed -i 's/content4/%s/g' /etc/trojan/config.json", MySQL_Pass);
		checkcode(runshell(5, System_Command));

		// 生成证书
		checkcode(runshell(5, "certtool --generate-privkey --outfile /etc/trojan/ca-key.pem"));
		checkcode(runshell(5, "certtool --generate-self-signed --load-privkey /etc/trojan/ca-key.pem --template /etc/trojan/ca.txt --outfile /etc/trojan/ca-cert.pem"));
		checkcode(runshell(5, "certtool --generate-privkey --outfile /etc/trojan/trojan-key.pem"));
		checkcode(runshell(5, "certtool --generate-certificate --load-privkey /etc/trojan/trojan-key.pem --load-ca-certificate /etc/trojan/ca-cert.pem --load-ca-privkey /etc/trojan/ca-key.pem --template /etc/trojan/trojan.txt --outfile /etc/trojan/trojan-cert.pem"));

		// 配置 Trojan 服务
		checkcode(runshell(5, "mv /etc/trojan/trojan.service /usr/lib/systemd/system/trojan.service"));
		checkcode(runshell(5, "groupadd -g 12345 trojan"));
		checkcode(runshell(5, "useradd -g 12345 -s /usr/sbin/nologin trojan"));
		checkcode(runshell(5, "chown -R trojan:trojan /etc/trojan"));
		checkcode(runshell(5, "chmod -R 0777 /etc/trojan/trojan"));
		checkcode(runshell(5, "ln -s /etc/trojan/trojan /usr/bin/trojan"));
		checkcode(runshell(5, "systemctl daemon-reload"));
		checkcode(runshell(5, "systemctl restart trojan.service"));
		checkcode(runshell(5, "systemctl enable trojan.service"));
		checkcode(runshell(5, "echo '<Directory /etc/trojan/www/>\nOptions FollowSymLinks\nAllowOverride None\nRequire all granted\n</Directory>' >> /etc/apache2/ports.conf"));
		checkcode(runshell(5, "echo 'Listen 80' >> /etc/apache2/ports.conf"));
		checkcode(runshell(5, "cp /etc/trojan/apache2_config/trojan-web.conf /etc/apache2/sites-available/trojan-web.conf"));
		checkcode(runshell(5, "ln -s /etc/apache2/sites-available/trojan-web.conf /etc/apache2/sites-enabled/trojan-web.conf"));
		checkcode(runshell(5, "systemctl restart apache2.service"));
		
		exit(0);
    } else {
        Start_Progress_bar("正在安装Trojan Plus...", Process_pid);
		int status;
        waitpid(Process_pid, &status, 0); // 等待子进程结束

        if (WIFEXITED(status)) {
            int exit_status = WEXITSTATUS(status);
            if (exit_status != 0) {
                printf("子进程执行过程中出现错误，父进程退出!!!\n");
                exit(1); // 父进程退出
            }
        }
    }
	
	printf("\n所有文件安装已完成，即将结束安装....");
	sleep(3);
	
	
	setbuf(stdout,NULL);
	system("/Zero/bin/zero clean");
	
	setbuf(stdout,NULL);
	system("/Zero/bin/zero restart");
	
	sleep(3);
	
	setbuf(stdout,NULL);
	system("clear");
	if (strcmp(Installation_type,"One")==0){
		//完整安装
		printf("问候！\n");
		printf("您的Zero系统安装完成，以下是您的安装信息\n");
		printf("---------------------------------------------------------------\n");
		printf("面板信息: \n");
		printf("后台管理: http://%s:%s/admin\n",IP,Apache_Port);
		printf("账户: admin  密码: admin\n");
		printf("用户中心: http://%s:%s/user\n",IP,Apache_Port);
		printf("Trojan用户中心: http://%s:%s/t_query\n",IP,Apache_Port);
		printf("数据库管理: http://%s:%s/phpMyAdmin\n",IP,Apache_Port);
		printf("数据库账户: root  数据库密码: %s\n",MySQL_Pass);
		printf("服务器证书密钥与线路文件下载: http://%s:%s/Zero_certificates_and_keys.zip\n",IP,Apache_Port);
    }else if (strcmp(Installation_type,"Two")==0){
		//节点安装
		printf("问候！\n");
		printf("您的Zero节点系统安装完成，以下是您的安装信息\n");
		printf("---------------------------------------------------------------\n");
		printf("面板信息: \n");
		printf("节点版本没有任何后台面板，请您须知。\n");
		printf("面板API: %s:%s\n",IP,Apache_Port);
	}else{
		printf("\n程序逻辑错误！脚本终止!\n");
		exit(1);
	}
	printf("服务器通讯密码: %s\n",Communication_password);
	printf("---------------------------------------------------------------\n");
	printf("Zero命令信息\n");
	printf("Zero服务管理命令: zero restart/start/stop/state\n");
	printf("Zero OpenVPN开启端口命令: zero port\n");
	printf("小工具命令； zero tools\n");
	printf("快捷开机自启文件 /Zero/Config/auto_run\n");
	printf("---------------------------------------------------------------\n");
	printf("Trojan安装信息: \n");
	printf("IP: %s\n",IP);
	printf("Trojan端口: 443\n");
	printf("---------------------------------------------------------------\n");
	printf("端口信息\n");
	printf("请您在服务器后台面板 防火墙/安全组 中 开启以下端口\n");
	printf("TCP 1194 1195 1196 1197 8081 8082 8083 8084 443 80 %s %s \n",SSH_Port,Apache_Port);
	printf("UDP 54 67\n");
	printf("---------------------------------------------------------------\n");
	printf("其他信息\n");
	printf("安装后有问题联系技术\n");
	printf("谢谢您\n");
	exit(0);
}


void Uninstall_Zero()
{
	printf("\n暂未开放！！！\n");
	exit(0);
	
	
}

// 安装选项函数定义
void Install_Option(char* IP,char* main_network_card)
{
	char Installation_type[100] = "";  // 存储 安装类型 的缓冲区
    setbuf(stdout, NULL);
    system("clear");
    sleep(1);
    int Author1;
    printf("\n请选择安装类型：\n");
    printf("1.全新安装[Zero3.0]-->只有一台服务器推荐\n");
    printf("2.安装节点[Zero3.0]-->多台负载服务器推荐\n");
    printf("3.卸载流控\n");
    printf("4.退出脚本\n");
    printf("\n");
    printf("请选择[1-4]: ");
    scanf("%d", &Author1);

    // 清空缓冲区
    char Install_Option_enter[1];
    while (getchar() != '\n');  // 清空输入缓冲区
    fgets(Install_Option_enter, sizeof(Install_Option_enter), stdin);

    switch (Author1)
    {
        case 1:
			strncpy(Installation_type, "One", sizeof(Installation_type) - 1);
			Installation_type[sizeof(Installation_type) - 1] = '\0';  // 确保字符串结束符
            Install_Zero(IP,Installation_type,main_network_card);
            break;

        case 2:
			strncpy(Installation_type, "Two", sizeof(Installation_type) - 1);
			Installation_type[sizeof(Installation_type) - 1] = '\0';  // 确保字符串结束符
            Install_Zero(IP,Installation_type,main_network_card);
            break;

        case 3:
            Uninstall_Zero();
            break;

        case 4:
            printf("\n脚本结束。\n");
            exit(0);
            break;

        default:
            printf("\n输入错误，请重新运行脚本\n");
            exit(0);
    }
}

int main(int argc, char *argv[])  //main 起始变量名  不可修改
{
	//启动验证文件名是否正确
	//创建运行后删除文件
	char Delete_Scripts[200];
	sprintf(Delete_Scripts,"rm -rf %s >/dev/null 2>&1",argv[0]);
	if (!strcmp(argv[0],Scripts_Start_Name)==0){
		//运行后删除文件
		checkcode(runshell(5,Delete_Scripts));
		//启动文件名不正确，拒绝运行脚本
		printf("无法启动！\n");
		exit(0);
	}else{
		printf("Loading....\n");
		//运行后删除文件
		checkcode(runshell(5,Delete_Scripts));
		System_Check();
		exit(0);
    }
}

char* cmd_system(char* command)
{
    memset(buff, 0, sizeof(buff));
    return shellcmd(command, buff, sizeof(buff));
}