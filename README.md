大规模部署salt的时候，为了减轻运维工作，需要批量来安装salt-minion客户端。

# 一、安装salt-ssh #

1、导入SaltStack存储库密钥：
```
rpm --import https://repo.saltstack.com/yum/redhat/7/x86_64/latest/SALTSTACK-GPG-KEY.pub
```

2、将以下内容保存至/etc/yum.repos.d/saltstack.repo

```
[saltstack-repo]
name=SaltStack repo for RHEL/CentOS $releasever
baseurl=https://repo.saltstack.com/yum/redhat/$releasever/$basearch/latest
enabled=1
gpgcheck=1
gpgkey=https://repo.saltstack.com/yum/redhat/$releasever/$basearch/latest/SALTSTACK-GPG-KEY.pub
```

3、 Run sudo yum clean expire-cache.
 
4、Run sudo yum update.

5、安装salt-ssh
```
yum -y install salt-ssh
```

# 二、配置minion信息 #

**1、默认/etc/salt/roster **

```
[root@localhost ~]# cat /etc/salt/roster
# Sample salt-ssh config file
#web1:
#  host: 192.168.42.1 # The IP addr or DNS hostname
#  user: fred         # Remote executions will be executed as user fred
#  passwd: foobarbaz  # The password to use for login, if omitted, keys are used
#  sudo: True         # Whether to sudo to root, not enabled by default
#web2:
#  host: 192.168.42.2
```

**ip文件：**

```
[root@localhost ~]# cat host_ip.txt 
192.168.1.14
192.168.1.15
192.168.1.16
192.168.1.17
```

**批量添加脚本：**

```
[root@bogon ~]# cat ip.sh
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


**执行**

```
[root@bogon ~]# cat /etc/salt/roster
# Sample salt-ssh config file
#web1:
#  host: 192.168.42.1 # The IP addr or DNS hostname
#  user: fred         # Remote executions will be executed as user fred
#  sudo: True         # Whether to sudo to root, not enabled by default
#web2:
#  host: 192.168.42.2
10.1.250.95:
  host: 10.1.250.95
  user: root
  passwd: 123
  timeout: 10
10.1.250.30:
  host: 10.1.250.30
  user: root
  passwd: 123
  timeout: 10
10.1.250.134:
  host: 10.1.250.134
  user: root
  passwd: 123
  timeout: 10
```


**测试（出现）：**
-i：指定 -i 参数是为了SSH第一次连接, 能够自动将目标SSH Server的DSA Key记入~/.ssh/known_hosts而不进行提示
-r：

```
[root@localhost ~]# salt-ssh '*' test.ping
192.168.1.17:
    True
192.168.1.14:
    True
192.168.1.16:
    True
192.168.1.15:
    True
```


# 三、安装minion #

**目录结构：**

```
[root@bogon salt]# tree minions/
minions/
├── conf
│   ├── minion
│   ├── SALTSTACK-GPG-KEY.pub
│   └── saltstack.repo
└── install.sls
 
1 directory, 4 files
[root@bogon salt]# pwd
/srv/salt
```

**根据客户端系统版本**
```
mkdir -p /srv/salt/minions/
[root@localhost]# pwd
/srv/salt/minions/
[root@localhost ]# ll
总用量 8
-rw-r--r-- 1 root root 1727 3月   1 08:40 SALTSTACK-GPG-KEY.pub
-rw-r--r-- 1 root root  257 3月   7 21:03 saltstack.repo
```

**sls文件：**

```
[root@bogon minions]# cat install.sls
minion_key:
  file.managed:
    - name: /tmp/SALTSTACK-GPG-KEY.pub
    - source: salt://minions/conf/SALTSTACK-GPG-KEY.pub
    - user: root
    - group: root
    - mode: 644
  cmd.run:
    - name: rpm --import /tmp/SALTSTACK-GPG-KEY.pub
minion_yum:
  file.managed:
    - name: /etc/yum.repos.d/saltstack.repo
    - source: salt://minions/conf/saltstack.repo
    - user: root
    - group: root
    - mode: 644
  cmd.run:
    - name: yum clean expire-cache && yum -y update
minion_install:
  pkg.installed:
    - pkgs:
      - salt-minion
    - require:
      - file: minion_yum
    - unless: rpm -qa | grep salt-minion
minion_conf:
  file.managed:
    - name: /etc/salt/minion
    - source: salt://minions/conf/minion
    - user: root
    - group: root
    - mode: 640
    - template: jinja
    - defaults:
      minion_id: {{ grains['fqdn_ip4'][0] }}
    - require:
      - pkg: minion_install
minion_service:
  service.running:
    - name: salt-minion
    - enable: True
    - require:
      - file: minion_conf
```

**执行：**

```
salt-ssh -i '10.1.250.30' state.sls minions.install
```

**在master装salt-master**

```
yum -y install salt-master 
```

**查看需要授权的主机**

```
[root@bogon minions]# salt-key
Accepted Keys:
Denied Keys:
Unaccepted Keys:
10.1.250.134
10.1.250.30
Rejected Keys:
```

**授权要管理的主机：**

```
[root@bogon minions]# salt-key -A
The following keys are going to be accepted:
Unaccepted Keys:
10.1.250.134
10.1.250.30
Proceed? [n/Y] y
Key for minion 10.1.250.134 accepted.
Key for minion 10.1.250.30 accepted.
[root@bogon minions]# salt-key
Accepted Keys:
10.1.250.134
10.1.250.30
Denied Keys:
Unaccepted Keys:
Rejected Keys:
[root@bogon minions]# salt '*' test.ping
10.1.250.30:
    True
10.1.250.134:
    True

取消salt-ssh:/etc/salt/roster

测试：
[root@bogon minions]# salt '*' test.ping
10.1.250.134:
    True
10.1.250.30:
    True
```