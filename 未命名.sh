#自动巡检mysql


mysql_user=“root”
mysql_passwd=“1234”


#对进程信息进行处理
ps  -ef |grep mysql > my.txt
cat my.txt | sed 's/ /\n/g' |  grep '\-\-'|sed '$!N; /^\(.*\)\n\1$/!P; D'|sed 's/--//g'  > my1.txt

basedir=cat my1.txt |grep '^basedir' | cut -d '=' -f 2
socket=cat my1.txt |grep '^socket' | cut -d '=' -f 2
passwd=1234

#1. 检查mysql主从同步情况

${basedir}/bin/mysql -uroot -p ${passwd} -S ${socket} -e "show slave status\G"

