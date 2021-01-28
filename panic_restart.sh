#!/bin/bash
for i in $(grep bench /mnt/lotus/log/miner.log | grep panic|grep -E  "`date -d "-4 min" +%FT%H:%M`|`date -d "-3 min" +%FT%H:%M`|`date -d "-2 min" +%FT%H:%M`|`date -d "-1 min" +%FT%H:%M`|`date  +%FT%H:%M`"|awk '{print $8}'|sort|uniq)
do
	echo ${i}
	echo "${i}    `date +%F:%T`" >>/mnt/lotus/log/panic_restart.log
	c=`grep ${i} /mnt/lotus/hosts-all`
	(cd /mnt/lotus/tools;/mnt/lotus/tools/restart-p2.sh ${i};/mnt/lotus/tools/connect-p1p2.sh  ${c})
done
