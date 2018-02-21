#!/bin/bash
for file in `ls /etc/zabbix/selinux/*.pp | sort`
do
  echo $file
  semodule -i $file
done