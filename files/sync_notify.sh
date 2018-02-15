#!/bin/sh
cd /root
./sync.sh|tee /root/notify.out
HOSTNAME=`hostname -f`
cat /root/notify.out|grep Task > /root/tasks.txt
#mailx -s "Pulp Run for ${HOSTNAME}" nick.fosdick@lark-it.com < /root/tasks.txt
