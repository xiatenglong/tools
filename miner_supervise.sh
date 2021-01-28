#!/bin/bash
#2020.1.0.1
#日志路径~/processor_xia.log
#11110202+5

#p1----------------------------------------------------------p1
#p1----------------------------------------------------------p1
#p1----------------------------------------------------------p1

#频繁执行会使空间不足的补齐任务

#使用方法
#若有不期望被处理的ip请直接传参输入,最大跳过 三个

#防止 上一次有卡顿未执行完成
#if [ -f /tmp/fddfasfasf_fdafdsf ]
#then
#	echo "请检查上一次是否执行成功"'!!!!!!!!!'
#	echo '有未执行完!!!!!!!!!!!!!!!!!!!!!!!!' >>${HOME}/processor_xia.log
#	exit
#fi

#touch /tmp/fddfasfasf_fdafdsf

>/tmp/worker.txt
>/tmp/workers.txt
>/tmp/make_task.txt
>/tmp/task_ago.txt

log="${HOME}/processor_xia.log"
echo -e "\np1处理中\e[5m...\e[0m\n"
echo -e "\n`date +%F:%T`\n----------------------------------------------------------------\n----------------------------------------------------------------\n" >>${HOME}/processor_xia.log

echo -e "#频繁执行会使空间不足的补齐任务\n"

if [[ ! -f ${HOME}/agotime.txt ]]
then
	touch 	${HOME}/agotime.txt
	echo "`date -d "-5 hour" +%F:%T`">>${HOME}/timep1.txt
fi

atime=`wc -l ${HOME}/agotime.txt|awk '{print $1}'`
if [ ${atime} -eq 0 ]
then
	echo "`date -d "-5 hour" +%s`" >>${HOME}/agotime.txt
	echo "`date  +%s`" >>${HOME}/agotime.txt
	echo -e "上一次运行时间   无\n"
	echo -e "当前时间      `date +%F:%T`"
	sleep 1
else
	agotime=`egrep "^[0-2]{3}[0-9]\-[0-9]{1,2}\-[0-9]{1,2}"  processor_xia.log|tail -2|head -1`
	timep1=`tail -1 ${HOME}/timep1.txt`
	echo -e "上一次运行时间${agotime}\n"
	echo -e "上一次p1运行时间 xxx"
	echo -e "当前时间      `date +%F:%T`"

fi

timetxt=`cat ${HOME}/agotime.txt|tail -2|head -1`
curren=`date +%s`

interval=`echo $((${curren}-${timetxt}))`

#p1 if起点
#########
##################################################################################
##################################################################################
##################################################################################
#if [ ${interval} -gt 18000 ]
#then
#echo "`date +%F:%T`" >>${HOME}/timep1.txt
#echo -e "`date +%s`" >>${HOME}/agotime.txt

#echo kil	
#清除颜色字体   过滤以下字段
#每个worker的ip 状态(ture false) 是否空闲  当前任务数 最大任务数
/mnt/lotus/lotus/lotus-miner --repo=/mnt/lotus/.lotus  --miner-repo=/mnt/lotus/.lotusstorage workers list |sed "s#\x1B\[[0-9;]*[a-zA-Z]##g"|grep p1|awk -F'[| /:]+' '{print $5"\t"$4"\t"$(NF-5)"\t"$(NF-4)"\t"$(NF-2)}' >/tmp/worker.txt
#判断是否有传参需要跳过的ip
if [ $# -eq 0 ]
then
	cat /tmp/worker.txt >/tmp/workers.txt
elif [ $# -eq 1 ]
then
	grep -v "$1" /tmp/worker.txt >/tmp/workers.txt
	#echo "$1"
elif [ $# -eq 2 ]
then
	grep -v "$1" /tmp/worker.txt|grep -v "$2" >/tmp/workers.txt
	#echo $2
elif [ $# -eq 3 ]
then
	grep -v "$1" /tmp/worker.txt|grep -v "$2"|grep -v "$3" >/tmp/workers.txt
	#echo $3
fi

#端口字段
/mnt/lotus/lotus/lotus-miner --repo=/mnt/lotus/.lotus  --miner-repo=/mnt/lotus/.lotusstorage workers list |sed "s#\x1B\[[0-9;]*[a-zA-Z]##g"|grep p1|awk -F'[| /:]+' '{print $5"\t"$5":"$6"\t"$4"\t"$(NF-5)"\t"$(NF-4)"\t"$(NF-2)}' >/tmp/p1_port.txt
p=1

echo -e "\n"
#字段收集
for i in `awk '{print $1}' /tmp/workers.txt`
do
	dh=`ssh -n ${i} df -h |grep -E "(/mnt/local|/mnt/lotus)"|awk '{print $4}'`
	if [ $? -eq 0 ];then
		echo -en  "- "
#		echo -e  "${i}   ---------------------   ${dh}" >>${log} 
	else
		echo -e "${i}---------------------不通"
		echo -e "${i}---------------------不通" >>${log}
	fi

	dhm=`ssh -n ${i} df -m |grep -E  "(/mnt/local|/mnt/lotus)"|awk '{print $4}'`

	#在后面添加以m为单位的剩余空间
	sed -ri "${p}s#(.*)#\1   ${dhm}#" /tmp/workers.txt
	sed -ri "${p}s#(.*)#\1   ${dh}#" /tmp/workers.txt
	let p++
done

echo -e "\n"
echo -e "\n" >>${log}

#cat /tmp/workers.txt
echo -e "\n"
echo -e "\n" >> ${log}
#cat /tmp/workers.txt >>${log}
#非空闲及空闲
grep -v "idle" /tmp/workers.txt >/tmp/noidle.txt
grep "idle" /tmp/workers.txt >/tmp/idle.txt
#分批处理不同状态
#正常工作
grep -v "false" /tmp/noidle.txt >/tmp/noidle_one.txt
#错误未显示空闲
grep "false" /tmp/noidle.txt >/tmp/noidle_false.txt
#正常空闲
grep -v "false" /tmp/idle.txt >/tmp/idle_one.txt
#错误空闲
grep "false" /tmp/idle.txt >/tmp/idle_false.txt

idle='/tmp/idle.txt'
noidle='/tmp/noidle.txt'

errnoidle='/tmp/noidle_false.txt'
rignoidle='/tmp/noidle_one.txt'
erridle='/tmp/idle_false.txt'
rigidle='/tmp/idle_one.txt'

#补任务 两段函数
func_xx (){
ggz=$[($disk - 3221440) / 900000 + 1]
[ ${ggz} -lt 0 ] && ggz=0
[ ${ggz} -ge ${numidle} ] && ggz=${numidle}
for i in `seq ${ggz}`
do
	/mnt/lotus/lotus/lotus-miner --repo=/mnt/lotus/.lotus  --miner-repo=/mnt/lotus/.lotusstorage sectors pledge --worker="${ip}:3345"
done
echo -e "${ip} 补齐 ${ggz} 个任务\n"
echo "========================================================================="
echo -e "${ip} 补齐 ${ggz} 个任务\n">>${log}
echo "=========================================================================" >>${log}
echo -e "${ip}\t补齐 ${ggz} " >>/tmp/make_task.txt
}

func_xia (){
	if [ ${numidle} -ne 0 ]
	then
		echo "========================================================================="
		echo -e "\n${ip}\t补齐任务前\t${task}\t最大任务 ${maxtask}\n"
		echo "=========================================================================" >>${log}
		echo -e "\n${ip}\t补齐任务前\t${task}\t最大任务 ${maxtask}\n" >>${log}
		echo -e "\n${ip}\t补齐任务前\t${task}\t最大任务 ${maxtask}\n">>/tmp/task_ago.txt
		
		case ${numidle} in
		1)
			func_xx
		;;
		2)
			func_xx
		;;
		3)
			func_xx
		;;
		4)
			func_xx
		;;
		5)
			func_xx
		;;
		6)
			func_xx
		;;
		7)
			func_xx
		;;
		8)
			func_xx
		;;
		9)
			func_xx
		;;
		10)
			func_xx
		;;
		11)
			func_xx
		;;
		12|13|14|15)
			func_xx
		;;
		esac
	fi
}

>/tmp/make_task.txt
>/tmp/task_ago.txt

#正常工作的
#echo -e "${ip}\n${state}\n${idle}\n${task}\n${maxtask}\n${disk}"
echo -e "----------------------rignoidle"
echo -e "----------------------rignoidle" >>${log}
cat ${rignoidle}|while read a
do
	ip=`echo ${a}|awk '{print $1}'`
	state=`echo ${a}|awk '{print $2}'`
	idle=`echo ${a}|awk '{print $3}'`
	task=`echo ${a}|awk '{print $4}'`
	maxtask=`echo ${a}|awk '{print $5}'`
	disk=`echo ${a}|awk '{print $6}'`
	diskh=`echo ${a}|awk '{print $7}'`
	numidle=`echo $((${maxtask}-${task}))`
	func_xia

done

echo -e "\n"
echo -e "\n\n" >>${log}

#错误未显示空闲
#echo -e "${ip}\n${state}\n${idle}\n${task}\n${maxtask}\n${disk}"


echo -e "----------------------errnoidle\n"
echo -e "----------------------errnoidle\n" >>${log}
cat ${errnoidle}|while read b
do
	ip=`echo ${b}|awk '{print $1}'`
	state=`echo ${b}|awk '{print $2}'`
	idle=`echo ${b}|awk '{print $3}'`
	task=`echo ${b}|awk '{print $4}'`
	maxtask=`echo ${b}|awk '{print $5}'`
	disk=`echo ${b}|awk '{print $6}'`
	diskh=`echo ${b}|awk '{print $7}'`
	numidle=`echo $((${maxtask}-${task}))`
	ping -c10 -w10 ${ip} >/dev/null

	if [ $? -eq 0 ];then
		echo "###############################################################\n${ip}false\n###############################################################"
		echo "###############################################################\n${ip}false\n###############################################################" >>${log}
#		echo restart...
#		(cd /mnt/lotus/tools/;/mnt/lotus/tools/restart-p1.sh "${ip}:3345" >/dev/null)
#		sleep 5
#		connect=`egrep -v "(^#|^$)"  /mnt/lotus/hosts-all|grep "${ip}:3345"`
#		if [ $? -eq 0 ];then
#			echo connect...
#			/mnt/lotus/tools/connect-p1p2.sh ${connect} >/dev/null
#			sleep 10
#			status=`/mnt/lotus/lotus/lotus-miner --repo=/mnt/lotus/.lotus  --miner-repo=/mnt/lotus/.lotusstorage workers list|sed "s#\x1B\[[0-9;]*[a-zA-Z]##g"|grep p1|grep ${i}|awk -F'[| /:]+' '{print $4}'`
#			if [[ ${status} =~ false ]];then
#			#if [[ false =~ false ]];then
#				echo -e "${ip}:\t 空间:\t${diskh}\t未预知的错误,手动解决\n\n\n"
#				echo -e "\n${ip}\t空间:\t${diskh}\t未预知的错误"\t'!!!'"\n" >>${log}
#			else
#func_xia
#			fi
#
#		fi
#	else
#		echo -e "\n${ip}\t down"
#		echo -e "\n${ip}\t down" >>${log}
	fi
		

done


#正常空闲
#echo -e "${ip}\n${state}\n${idle}\n${task}\n${maxtask}\n${disk}"


echo -e "----------------------rigidle\n"
echo -e "----------------------rigidle\n" >>${log}
cat ${rigidle}|while read c
do
	ip=`echo ${c}|awk '{print $1}'`
	state=`echo ${c}|awk '{print $2}'`
	idle=`echo ${c}|awk '{print $3}'`
	task=`echo ${c}|awk '{print $4}'`
	maxtask=`echo ${c}|awk '{print $5}'`
	disk=`echo ${c}|awk '{print $6}'`
	diskh=`echo ${b}|awk '{print $7}'`
	numidle=`echo $((${maxtask}-${task}))`
	func_xia
done

#错误的空闲
#echo -e "${ip}\n${state}\n${idle}\n${task}\n${maxtask}\n${disk}"


echo -e "----------------------erridle\n"
echo -e "----------------------erridle\n" >>${log}
cat ${erridle}|while read d
do
	ip=`echo ${d}|awk '{print $1}'`
	state=`echo ${d}|awk '{print $2}'`
	idle=`echo ${d}|awk '{print $3}'`
	task=`echo ${d}|awk '{print $4}'`
	maxtask=`echo ${d}|awk '{print $5}'`
	disk=`echo ${d}|awk '{print $6}'`
	diskh=`echo ${b}|awk '{print $7}'`
	numidle=`echo $((${maxtask}-${task}))`
	ping -c10 -w10 ${ip} >/dev/null

#		echo "###############################################################\n${ip}false\n###############################################################"
#		echo "###############################################################\n${ip}false\n###############################################################" >>${log}
	if [ $? -eq 0 ];then
		echo restart...
		(cd /mnt/lotus/tools/;/mnt/lotus/tools/restart-p1.sh "${ip}:3345")
		sleep 5
		connect=`egrep -v "(^#|^$)"  /mnt/lotus/hosts-all|grep "${ip}:3345"`
		if [ $? -eq 0 ];then
			echo connect...
			/mnt/lotus/tools/connect-p1p2.sh ${connect}
			sleep 10
			status=`/mnt/lotus/lotus/lotus-miner --repo=/mnt/lotus/.lotus  --miner-repo=/mnt/lotus/.lotusstorage workers list|sed "s#\x1B\[[0-9;]*[a-zA-Z]##g"|grep p1|grep ${i}|awk -F'[| /:]+' '{print $4}'`
			if [[ ${status} =~ false ]];then
			#if [[ false =~ false ]];then
				echo -e "${ip}:\t 空间:\t${diskh}\t未预知的错误,手动解决\n\n\n"
				echo -e "\n${ip}\t空间:\t${diskh}\t未预知的错误"\t'!!!'"\n" >>${log}
			else
func_xia
			fi

		fi
	else
		echo -e "\n${ip}\t down"
		echo -e "\n${ip}\t down" >>${log}
	fi
done

#echo -e  "补充------------------------------"
#echo -e "\n\n"
#cat /tmp/make_task.txt
#cat /tmp/task_ago.txt
#echo -e  "补充------------------------------" >>${log}
#echo -e "\n\n" >>${log}
#cat /tmp/make_task.txt >>${log}
#cat /tmp/task_ago.txt >>${log}
echo -en "\nwait"
for i in `seq 15`
do
echo -n "."
sleep 1.2
done
echo
echo

>/tmp/set.txt

for i in `awk '{print $1}' /tmp/make_task.txt`
do
agotask=`grep -E "${i}[^0-9]" /tmp/task_ago.txt |awk '{print $3}'`
nowtask=`/mnt/lotus/lotus/lotus-miner --repo=/mnt/lotus/.lotus  --miner-repo=/mnt/lotus/.lotusstorage workers list |sed "s#\x1B\[[0-9;]*[a-zA-Z]##g"|grep p1|awk -F'[| /:]+' '{print $5"\t" $(NF-4)}'|grep -E "${i}[^0-9]"|awk '{print $2}'`
make=`grep -E "${i}[^0-9]" /tmp/make_task.txt|awk '{print $3}'`
max=`grep -E "${i}[^0-9]" /tmp/task_ago.txt |awk '{print $5}'`
space=`grep -E "${i}[^0-9]" /tmp/workers.txt|awk '{print $NF}'`
fmake=`echo $(((${agotask}+${make}) - ${nowtask}))`
echo -e "IP: ${i}\t补齐前:  ${agotask}\t补齐:  ${make}\t补齐失败:  ${fmake} \t空间: ${space}\t当前任务:  ${nowtask}\t最大任务:  ${max}" >>/tmp/set.txt
done

echo -e "补齐"
cat /tmp/set.txt
cat /tmp/set.txt >>${log}

echo -e "正常状态"
grep -Ev "`awk   'BEGIN{ORS="|"}{print $1}' /tmp/make_task.txt|sed -r 's#(.*)(|)([^.*])#\1\n#g'`" /tmp/workers.txt
grep -Ev "`awk   'BEGIN{ORS="|"}{print $1}' /tmp/make_task.txt|sed -r 's#(.*)(|)([^.*])#\1\n#g'`" /tmp/workers.txt >>${log}

##############################################################################
#此处为跳过p1的if结尾
#else
#	echo -e "\n当前执行频率过高,稍后重试\n"
#	echo -e "\n当前执行频率过高,稍后重试\n" >>${log}
#fi
##############################################################################



#p2------------------------------------------------------------------------p2
#p2------------------------------------------------------------------------p2
#p2------------------------------------------------------------------------p2



#echo -e "\n\n\np2处理中\e[5m...\e[0m\n"
#echo -e "\n++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n" >>${log}


#/mnt/lotus/lotus/lotus-miner --repo=/mnt/lotus/.lotus  --miner-repo=/mnt/lotus/.lotusstorage workers list |sed "s#\x1B\[[0-9;]*[a-zA-Z]##g"|grep p2|grep false|grep idle|awk -F'[ |]+' '{print $5}' >/tmp/p2_false.txt

#for g in `cat /tmp/p2_false.txt`
#do
#	pp2=`echo ${g} |awk -F ':' '{print $1}'`
#	echo -e "\n${pp2} false 正在处理.\n"
#	echo -e "\n${pp2} false 正在处理.\n" >>${log}
#
#	(cd /mnt/lotus/tools/;/mnt/lotus/tools/restart-p2.sh ${g})
#	sleep 5
#	connectp2=`grep -v "(^#|^$)" /mnt/lotus/hosts-all|grep "${g}"`
#	if [ $? -eq 0 ]
#	then
#	/mnt/lotus/tools/connect-p1p2.sh ${connectp2}
#	fi
#done
#sleep 5
#mwl --wid=9997
echo -e "9997..."
/mnt/lotus/lotus/lotus-miner --repo=/mnt/lotus/.lotus  --miner-repo=/mnt/lotus/.lotusstorage workers list --wid="9997" >>/dev/null

#rm -rf /tmp/fddfasfasf_fdafdsf

#c2---------
#待续...
