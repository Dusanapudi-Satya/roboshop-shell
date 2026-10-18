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
dnf module disable nodejs -y &>> $LOG_FILE
VALIDATE $? "Disabling current Nodejs"

dnf module enable nodejs:20 -y &>> $LOG_FILE
VALIDATE $? "Enabling  Nodejs 20 version"

dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? " Installing nodejs "

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
mkdir -p /app &>> $LOG_FILE
VALIDATE $? "Creating app directory"

curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip 
VALIDATE $? "Downloading cart application "
cd /app 
unzip -o /tmp/cart.zip
VALIDATE $? "Unzipping cart application "

cd /app 
npm install 

VALIDATE $? "Installing dependencies"

# use absolute path , because cart.service exists there
cp /home/ec2-user/roboshop-shell/cart.service /etc/systemd/system/cart.service &>> $LOG_FILE
#cp cart.service /etc/systemd/system/cart.service &>> $LOG_FILE

VALIDATE $? "Copying cart service file"

systemctl daemon-reload &>> $LOG_FILE

VALIDATE $? "cart daemon reload"

systemctl enable cart &>> $LOG_FILE
VALIDATE $? " enabling cart "

systemctl start cart &>> $LOG_FILE
VALIDATE $? "starting cart"


