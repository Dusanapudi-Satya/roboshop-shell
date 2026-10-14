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
    echo " you are a root user , proceed to install"
    # exit 0 , means success
fi
cp mongo.repo /etc/yum.repos.d/mongo.repo &>> $LOG_FILE
VALIDATE $? "Copied mongodb.repo is"

dnf install mongodb-org -y &>> $LOG_FILE
VALIDATE $? "Installing mongodb is"

systemctl enable mongod &>> $LOG_FILE
VALIDATE $? "Enabling mongodb is"

systemctl start mongod &>> $LOG_FILE
VALIDATE $? "Starting mongodb is"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>> $LOG_FILE
VALIDATE $? "Remote access to mongodb "

# Restart the service to make the changes effected
systemctl restart mongod &>> $LOG_FILE
VALIDATE $? " restarting mongodb "

