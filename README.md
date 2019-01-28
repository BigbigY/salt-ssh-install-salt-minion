# Saltstack？ #
Salt 一种全新的基础设施管理方式，部署轻松，在几分钟内可运行起来，扩展性好，很容易管理上万台服务器，速度够快，服务器之间秒级通讯。

salt底层采用动态的连接总线, 使其可以用于编配, 远程执行, 配置管理等等.

# 批量部署salt-minion客户端 #

大规模部署salt的时候，为了减轻运维工作，需要批量来安装salt-minion客户端。

salt-ssh是Saltstack的另一种管理方式，无需安装minion端，可以运用Salt的一切功能，管理和使用方式和基本和Salt一样。但是执行效率会比有minion端慢很多，不适合大规模批量操作

## 环境： ##
```
192.168.1.14  服务端：salt-ssh salt-master salt-minion
192.168.1.15  客户端：salt-minion
192.168.1.16  客户端：salt-minion
192.168.1.17  客户端：salt-minion
```

# 一、salt-ssh安装（master端） #

### 1、克隆代码： ###
```
$ git clone https://github.com/BigbigY/salt-ssh-install-salt-minion.git
```

### 2、导入SaltStack存储密钥： ###
```
$ rpm --import SALTSTACK-GPG-KEY.pub
```

### 3、将saltstack.repo拷贝到/etc/yum.repos.d/ ###

### 4、Run sudo yum clean expire-cache. ###

### 5、Run sudo yum update. ###

### 6、安装salt-ssh ###
提示：salt-ssh不需要启动服务,只需要启动下salt-master服务
```
$ yum -y install salt-ssh salt-master
$ systemctl start salt-master
```


# 二、配置salt-ssh客户端信息，通信 #

### 1、ip文件： ###
把所有minion_ip放到文件中，格式如下：
```
$ cat host_ip.txt 
192.168.1.14
192.168.1.15
192.168.1.16
192.168.1.17
```

### 2、批量添加脚本： ###
USERNAME是客户端用户名，PASSWORD是客户端密码，这里的话客户端账号密码都相同，所有我写了个批量添加的脚本
```
$ cat ip.sh
#!/bin/bash
USERNAME="root"
PASSWORD="123"
for i in `cat /root/host_ip.txt`
do
        echo "$i:" >> /etc/salt/roster ##$i表示取文件的每行内容
        echo "  host: $i" >> /etc/salt/roster
        echo "  user: $USERNAME" >>/etc/salt/roster
        echo "  passwd: $PASSWORD" >>/etc/salt/roster
#        echo "  sudo: True" >>/etc/salt/roster
        echo "  timeout: 10" >>/etc/salt/roster
done
```

### 3、执行，查看 ###
```
$ cat /etc/salt/roster
# Sample salt-ssh config file
#web1:
#  host: 192.168.42.1 # The IP addr or DNS hostname
#  user: fred         # Remote executions will be executed as user fred
#  sudo: True         # Whether to sudo to root, not enabled by default
#web2:
#  host: 192.168.42.2
192.168.1.14:
  host: 192.168.1.14
  user: root
  passwd: 123
  timeout: 10
192.168.1.15:
  host: 192.168.1.15
  user: root
  passwd: 123
  timeout: 10
192.168.1.16:
  host: 192.168.1.16
  user: root
  passwd: 123
  timeout: 10
192.168.1.17:
  host: 192.168.1.17
  user: root
  passwd: 123
  timeout: 10
```

### 4、测试 ###
```
$ salt-ssh -i '*' test.ping
192.168.1.17:
    True
192.168.1.14:
    True
192.168.1.16:
    True
192.168.1.15:
    True
```

# 三、批量安装salt-minion #

### 1、目录结构： ###
```
$ pwd
/srv/salt
$ tree minions/
minions/
├── 5
│   └── README.md
├── 6
│   └── README.md
└── 7
    ├── conf
    │   ├── minion
    │   ├── SALTSTACK-GPG-KEY.pub
    │   └── saltstack.repo
    └── install.sls

4 directories, 6 files
```

### 2、需要在控制端/etc/hosts文件增加Host解析（master） ###
```
$ cat /etc/hosts
192.168.1.14  salt.node1.com
192.168.1.15  salt.node2.com
192.168.1.16  salt.node3.com
192.168.1.17  salt.node4.com
```


### 3、执行： ###
minion配置文件根据自己master_ip修改，id根据自身情况获取

```
$ pwd
/srv/salt
salt-ssh -i '*' state.sls minions.7.install
```

### 4、查看需要授权的主机： ###
```
$ salt-key
Accepted Keys:
Denied Keys:
Unaccepted Keys:
192.168.1.14
192.168.1.15
192.168.1.16
192.168.1.17
Rejected Keys:
```

### 5、授权要管理的主机： ###
```
$ salt-key -A
The following keys are going to be accepted:
Unaccepted Keys:
192.168.1.14
192.168.1.15
192.168.1.16
192.168.1.17
Proceed? [n/Y] y
Key for minion 192.168.1.14 accepted.
Key for minion 192.168.1.15 accepted.
Key for minion 192.168.1.16 accepted.
Key for minion 192.168.1.17 accepted.
```

### 查看 ###
```
$ salt-key
Accepted Keys:
192.168.1.14
192.168.1.15
192.168.1.16
192.168.1.17
Denied Keys:
Unaccepted Keys:
Rejected Keys:
```

### 6、salt测试 ###
```
$ salt '*' test.ping
192.168.1.14:
    True
192.168.1.15:
    True
192.168.1.16:
    True
192.168.1.17:
    True
```

### 7、取消salt-ssh： ###
在/etc/salt/roster清除添加的认证主机

### 8、测试 ###
```
$ salt '*' test.ping
192.168.1.14:
    True
192.168.1.15:
    True
192.168.1.16:
    True
192.168.1.17:
    True
```


温馨提示：
此篇以ip为minion_id，如果需要根据主机名，可以先把主机名写命名好，然后改写install.sls grains获取改成host主机名就可以了。
或者可以自己编写个grains模块来获取。
