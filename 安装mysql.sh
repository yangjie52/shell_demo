#! /bin/bash
user=mysql
group=mysql

#添加系统资源限制
echo "mysql  soft  nproc  65535" >> /etc/security/limits.conf
echo "mysql  hard  nproc  65535" >> /etc/security/limits.conf
echo "mysql  soft  npfile  65535" >> /etc/security/limits.conf
echo "mysql  hard  nofile  65535" >> /etc/security/limits.conf
##创建用户
ifgroup=`grep ${group} /etc/group`
ifuser=`grep ${user} /etc/passwd`
if [ ! $ifgroup ];then
        groupadd mysql
else
        echo "存在"
fi
if [ ! $ifuser ];then
        useradd -g mysql mysql
else
        echo "存在"
fi

#下载安装包
read -p "请输入安装包网址:" url
read -p "请输入安装的目录:" pwd
read -p "请输入安装的mysql的版本（5或8):" version
read -p "请输入端口号：" port

passwd='1234'

filename=$(basename "$url")
wget -P ${pwd} ${url}
name=$(basename "$filename" .tar.gz)
tar -zxf  ${pwd}/${filename} -C ${pwd} 
mv ${pwd}/${name} ${pwd}/mysql
#创建数据目录，备份文件目录
mkdir -p ${pwd}/mysqldata/{${port}/{data,tmp,binlog},scripts}
mkdir -p ${pwd}/backup

#创建参数文件
touch ${pwd}/mysqldata/${port}/my.cnf

if [ ${num2} == 5 ]
then 
	cat var5.txt >> ${pwd}/mysqldata/${port}/my.cnf 
elif [ ${num2} == 8 ]
then 
	cat var8.txt >> ${pwd}/mysqldata/${port}/my.cnf
else
    echo "没有符合的条件"
fi
#修改参数文件的内容
sed -i 's#port=#port='${port}'#g' ${pwd}/mysqldata/${port}/my.cnf 
sed -i 's#socket=#socket='${pwd}'/mysqldata/'${port}'/tmp/mysql_'${port}'.sock#g' ${pwd}/mysqldata/${port}/my.cnf
sed -i 's#datadir=#datadir='${pwd}'/mysqldata/'${port}/'da33ta#g' ${pwd}/mysqldata/${port}/my.cnf 
sed -i 's#basedir=#basedir='${pwd}'/mysql#g' ${pwd}/mysqldata/${port}/my.cnf
sed -i 's#tmpdir=#tmpdir='${pwd}'/mysqldata/'${port}'/tmp#g'  ${pwd}/mysqldata/${port}/my.cnf

#创建备份文件
touch ${pwd}/backup/backup.sh
cat backup.sh >> ${pwd}/backup/backup.sh
#修改备份文件的内容
sed -i  's#DB_PASSWORD=#DB_PASSWORD='${passwd}'#g' ${pwd}/backup/backup.sh
sed -i  's#PORT=#PORT ='${port}'#g' ${pwd}/backup/backup.sh
sed -i  's#DB_SOCKET=#DB_SOCKET ='${pwd}'/mysqldata/'${port}'/tmp/mysql_'${port}'.sock#g' ${pwd}/backup/backup.sh
sed -i  's#BACKUP_DIR=#BACKUP_DIR='${pwd}'/backup#g' ${pwd}/backup/backup.sh
sed -i 's#DB_BASEDIR=#DB_BASEDIR='${pwd}'/mysql#g'  ${pwd}/backup/backup.sh

chown -R mysql:mysql ${pwd}

sudo -u mysql bash << EOF
echo "export PATH=${pwd}/mysql/bin:$PATH" >> /home/mysql/.bash_profile
#初始化数据库
${pwd}/mysql/bin/mysqld --defaults-file=${pwd}/mysqldata/${port}/my.cnf --basedir=${pwd}/mysql --datadir=${pwd}/mysqldata/${port}/data --initialize
#启动数据库
${pwd}/mysql/bin/mysqld_safe --defaults-file=${pwd}/mysqldata/${port}/my.cnf &

#创建备份
echo "20 14 * * *${pwd}/backup/backup.sh" >> mycron
# 安装更新后的crontab文件
crontab mycron
# 删除临时文件
rm mycron

EOF