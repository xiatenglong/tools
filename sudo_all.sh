#!/bin/bash
cat >/tmp/hosts-all<<EOF
10.0.0.101
EOF
user=fil
pass=12345679

for i in `cat /tmp/hosts-all`
do
	expect <<EOF
	 spawn ssh-copy-id ${user}@${i}
	 expect {
	 ")?" { send "yes\r";exp_continue}
	 "password:" { send "${pass}\r"; exp_continue}
}
EOF

	expect <<EOF
      	 spawn ssh -tv  ${user}@${i}  sudo chmod +w /etc/sudoers
	 expect {
	 "for ${user}:" {send "${pass}\r"; exp_continue}
	 eof
}
EOF
	expect <<EOF
	spawn ssh -tv sudo  -S sed -i '$a fil ALL=(ALL) NOPASSWD: ALL' /etc/sudoers
	expect {
	"for ${user}:" {send "${pass}\r"; exp_continue}
	eof
}
EOF
done
