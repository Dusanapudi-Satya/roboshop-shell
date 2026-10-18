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
MONGODB_HOST=mongodb.satyadaws.online
echo "script started executing at $TIMESTAMP" &>> $LOG_FILE
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
dnf module disable redis -y &>> $LOG_FILE
VALIDATE $? "Disabling redis"

dnf module enable redis:7 -y &>> $LOG_FILE
VALIDATE $? "Enabling redis version 7"

dnf install redis -y &>> $LOG_FILE
VALIDATE $? "Installing redis"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/redis/redis.conf &>> $LOG_FILE
VALIDATE $? "Remote access to mongodb"

sed -i 's/yes/no/g' /etc/redis/redis.conf &>> $LOG_FILE
VALIDATE $? "Disabling protected mode"

systemctl enable redis &>> $LOG_FILE
VALIDATE $? "Enabling redis"

systemctl start redis &>> $LOG_FILE
VALIDATE $? "Starting redis"


