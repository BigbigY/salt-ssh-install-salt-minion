#!/bin/bash
USERNAME="root"
PASSWORD="123"
for i in `cat ./host_ip.txt`
do
        echo "$i:" >> /etc/salt/roster ##$i��ʾȡ�ļ���ÿ������
        echo "  host: $i" >> /etc/salt/roster
        echo "  user: $USERNAME" >>/etc/salt/roster
        echo "  passwd: $PASSWORD" >>/etc/salt/roster
#        echo "  sudo: True" >>/etc/salt/roster
        echo "  timeout: 10" >>/etc/salt/roster
done
