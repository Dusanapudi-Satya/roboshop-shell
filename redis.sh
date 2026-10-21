#!/bin/bash
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
# step 1: check if the user has root access to install packages
ID=$(id -u)
echo "script name: $0"
TIMESTAMP=$( date +%F-%H-%M-%S)
LOG_FILE="/tmp/$0-$TIMESTAMP.log"
#instead of writing VALIDATE function everywhere we can use exec
#if any error occurs or echo statement everything(&) will go into LOG_FILE
# Log will not appear in terminal, usecases are: when we schedule scripts
# which are running in background , in that case we can use it since user will not execute the #scripts
#exec &>$LOG_FILE
REDIS_HOST=redis.satyadaws.online
echo "script started executing at $TIMESTAMP"
VALIDATE(){
    if [ $1 -ne 0 ]
    then 
        echo -e " $2 .. $R Failed $N"
        exit 1
    else
        echo -e " $2 .. $G SUCCESS $N"
    fi    

}
if [ $ID -ne 0 ];
then 
    echo -e " $R Error: Please run with root access $N "
    exit 1 # you can give non zero
else
    echo " you are a root user , proceed to configure"
    # exit 0 , means success
fi

dnf module disable redis -y 
VALIDATE $? "Disabling redis"

dnf module enable redis:7 -y 
VALIDATE $? "Enabling redis version 7"

dnf install redis -y  
VALIDATE $? "Installing redis"

#sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf 
sed -i 's/^bind 127.0.0.1/bind 0.0.0.0/' /etc/redis/redis.conf &>>"$LOG_FILE"
VALIDATE $? "allowing remote connection "

sed -i 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf &>>"$LOG_FILE"
#sed -i 's/yes/no/g' /etc/redis/redis.conf 
VALIDATE $? "Disabling protected mode"

systemctl enable redis 
VALIDATE $? "Enabling redis"

systemctl restart redis 
VALIDATE $? "restarting redis"

netstat -lntp | grep 6379 &>> $LOG_FILE
VALIDATE $? "Redis service listening on port 6379"

echo -e "${G}Redis setup completed successfully.${N}"
