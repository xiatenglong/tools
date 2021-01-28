#!/bin/bash
#ip列表(列表数大于35 分为两个文件执行 更快)
host_ip=/home/fil/xia/chun_1.txt
#本地被传输文件路径
spath=/tmp/.lotus
#目的地文件路径
dpath=/mnt/lotus/tmp/.lotus

#子机传输本地路径
sspath=/mnt/lotus/tmp/.lotus
#子机传输目的地路径
ddpath=/mnt/lotus/tmp/


for i in `cat ${host_ip}`
do
   expect <<EOF
#!/bin/bash
   spawn ssh-copy-id -i ${i}
   expect {
      "(yes/no)?" { send "yes\n";exp_continue}
      "password:" { send "storage\n"}
   }
   expect eof
EOF
done

#ip分批
tail -20 ${host_ip}|head -4 >/tmp/sum1.txt
tail -16 ${host_ip}|head -4 >/tmp/sum2.txt
tail -12 ${host_ip}|head -4 >/tmp/sum3.txt
tail -8  ${host_ip}|head -4 >/tmp/sum4.txt
tail -4  ${host_ip}	    >/tmp/sum5.txt

cat > /tmp/cc_y.sh <<EOF
#!/bin/bash
	expect <<QQQ
	spawn ssh-keygen
	expect {
	"*:" 		{send "\n";exp_continue}
	"(y/n)?"	{send "\n";exp_continue}
	}
	expect eof
QQQ

for i in \`cat /tmp/sum_ip.txt\`
do
	expect <<EEE
	spawn ssh-copy-id -i \${i}
	expect {
	   "(yes/no*?" { send "yes\n";exp_continue}
	   "password:" { send "storage\n"}
	}
	expect eof
EEE
	scp -r ${sspath} \${i}:${ddpath}&
done
EOF


p=1
for i in `cat ${host_ip}|head -5`
do
	echo ${i}
	scp /tmp/cc_y.sh ${i}:~
	scp /tmp/sum${p}.txt ${i}:/tmp/sum_ip.txt
	scp -r ${spath} ${i}:${dpath} &
	echo -e "\n\n\n"
	let p++
done

wait
for i in `cat ${host_ip}|head -5`
do
	ssh ${i} 'setsid bash /home/fil/cc_y.sh &'&
done
