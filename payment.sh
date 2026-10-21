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
dnf install python3 gcc python3-devel -y &>> $LOG_FILE
VALIDATE $? "Installing python "

# useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOG_FILE
id roboshop
if [ $? -ne 0]
then
    useradd roboshop
    VALIDATE $? "Creating Roboshop User"
else
    echo -e "Roboshop user already exists .. $Y Skipping $N"
fi

 # -p : if directory exists it will not create otherwise it will create
# -p, --parents no error if existing, make parent directories as needed
mkdir -p /app &>> $LOG_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>> $LOG_FILE
VALIDATE $? "Downloading payment app "
 
cd /app
VALIDATE $? "Moving to app directory"

unzip -o /tmp/payment.zip &>> $LOG_FILE
VALIDATE $? "Unzipping payment"

cd /app 
VALIDATE $? "Moving to app directory"

pip3 install -r requirements.txt &>> $LOG_FILE
VALIDATE $? "Installing dependencies"

cp /home/ec2-user/roboshop-shell/payment.service /etc/systemd/system/payment.service &>> $LOG_FILE
VALIDATE $? "Copying payment service file"

systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "daemon-reload"

systemctl enable payment &>> $LOG_FILE
VALIDATE $? "Enabling payment"

systemctl start payment &>> $LOG_FILE
VALIDATE $? "Starting payment"

echo -e "${G} Payment setup completed successfully.${N}"



