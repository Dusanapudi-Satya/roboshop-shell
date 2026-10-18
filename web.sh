#!/bin/bash
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
# step 1: check if the web has root access to install packages
ID=$(id -u)
echo "script name: $0"
TIMESTAMP=$( date +%F-%H-%M-%S)
LOG_FILE="/tmp/$0-$TIMESTAMP.log"
WEB_HOST=satyadaws.online
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
    echo " you are a root User , proceed to configure"
    # exit 0 , means success
fi
dnf module disable nginx -y
VALIDATE $? "Disabling current version of nginx"

dnf module enable nginx:1.24 -y
VALIDATE $? " Enabling nginx:1.24 "

dnf install nginx -y
VALIDATE $? " Installing nginx "

systemctl enable nginx 
VALIDATE $? "Enabling nginx"

systemctl start nginx 
VALIDATE $? "Starting nginx"

rm -rf /usr/share/nginx/html/* 
VALIDATE $? " Removing the default website "

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip
VALIDATE $? "Downloaded web application"

cd /usr/share/nginx/html 
VALIDATE $? "Moving to nginx/html directory"

unzip /tmp/frontend.zip
VALIDATE $? "Unzipping web "

cp /home/ec2-user/roboshop-shell/nginx.conf /etc/systemd/system/nginx.conf 
VALIDATE $? "Copied Roboshop reverse proxy config file"

systemctl restart nginx 
VALIDATE $? "Restarted nginx"






