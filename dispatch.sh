#!/bin/bash
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
SCRIPT_NAME=$(basename "$0")
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
# step 1: check if the user has root access to install packages
ID=$(id -u)
echo "script name: $0"
TIMESTAMP=$( date +%F-%H-%M-%S)
LOG_FILE="/tmp/$0-$TIMESTAMP.log"
USER_HOST=user.satyadaws.online
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
dnf install golang -y
VALIDATE $? "Installing golang"

go version

#useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
id roboshop
if [ $? -ne 0 ]
then
    useradd roboshop
    VALIDATE $? "Creating Roboshop User"
else
    echo -e "Roboshop user already exists .. $Y Skipping $N"
fi


mkdir /app
VALIDATE $? "Creating application dir"

curl -L -o /tmp/dispatch.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/dispatch-v4.zip
VALIDATE $? "Downloading dispatch application"

cd /app
VALIDATE $? "Moving to app directory"

unzip /tmp/dispatch.zip
VALIDATE $? "Unzipping dispatch app"

cd /app
VALIDATE $? "Moving to app directory"


go build -o dispatch .
VALIDATE $? "Installing dependencies"

systemctl daemon-reload
VALIDATE $? "daemon-reload"

systemctl enable dispatch
VALIDATE $? "Enabling dispatch"

systemctl start dispatch
VALIDATE $? "Starting dispatch"

systemctl status dispatch
VALIDATE $? "Dispatch status is"

journalctl -u dispatch -f
VALIDATE $? "Recent logs are:"
