#!/bin/bash
for i in `grep -Ev "^#|^$" /mnt/lotus/hosts-all|awk -F':' '{print $1}'|sort|uniq`
do
	echo ${i}
	for z in `ssh ${i} find /mnt/lotus/.lotusworker/cache/ -type d -name s-*  -mmin +480`
	do
		c=`ssh ${i} du -h ${z}|awk  '/353G/{print $2}'`
		if [ -z ${c} ];then
			continue
		else
			ssh ${i} "rm -rf  ${c}"
		fi
	done
done
