#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
# step 1: check if the user has root access to install packages
ID=$(id -u)
echo "script name: $0"
TIMESTAMP=$( date +%F-%H-%M-%S)
LOG_FILE="/tmp/$0-$TIMESTAMP.log"

echo "script started executing at $TIMESTAMP" &>> $LOG_FILE
VALIDATE(){
    if [ $1 -ne 0 ]
    then 
        echo -e " $2 .. $R Failed $N"
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

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOG_FILE
VALIDATE $? "Creating Roboshop User"

mkdir /app &>> $LOG_FILE
VALIDATE $? "Creating app directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? "Downloading catalogue application "
cd /app 
unzip /tmp/catalogue.zip
VALIDATE $? "Unzipping catalogue application "


cd /app 
npm install 

VALIDATE $? "Installing dependencies"

# use absolute path , because catalogue.service exists there
cp C:/Users/satya/devops/repos/roboshop-shell/catalogue.service /etc/systemd/system/catalogue.service















sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>> $LOG_FILE
VALIDATE $? "Remote access to mongodb "

# Restart the service to make the changes effected
systemctl restart mongod &>> $LOG_FILE
VALIDATE $? " restarting mongodb "

