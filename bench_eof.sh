#!/bin/bash
grep -a bench /mnt/lotus/log/miner.log | grep sector:|grep "EOF while parsing" | grep 2021-01-21T21 | awk -F 'sector:' '{print $2}'|awk -F'[ :]+' '{print $1,$3}'|sort |uniq |awk '{print $2}'|sort|uniq >/tmp/cbench_ip.txt
grep -a bench /mnt/lotus/log/miner.log | grep sector:|grep "EOF while parsing" | grep 2021-01-21T21 | awk -F 'sector:' '{print $2}'|awk -F'[ :]+' '{print $1,$3}'|sort |uniq |awk '{print $2,$1}' >/tmp/cbench_sector.txt




for i in `cat /tmp/cbench_ip.txt`
do
        del=`grep "${i}" /tmp/cbench_sector.txt|awk '{print $2}'`
        for c in ${del}
        do
                ssh ${i} rm -f /mnt/lotus/.lotusworker/sealed/s-t09652-${c}
        done

done
