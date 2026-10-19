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
dnf install maven -y
VALIDATE $? "Installing maven"
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOG_FILE
VALIDATE $? "Adding application user"
  
 # -p : if directory exists it will not create otherwise it will create
# -p, --parents no error if existing, make parent directories as needed
mkdir -p /app &>> $LOG_FILE
VALIDATE $? "Creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> $LOG_FILE
VALIDATE $? "Downloading shipping application"

cd /app 
VALIDATE $? "Moving to app directory "

unzip -o /tmp/shipping.zip &>> $LOG_FILE
VALIDATE $? "Unzipping shipping"

cd /app 
VALIDATE $? " Moving to app directory "

mvn clean package &>> $LOG_FILE
VALIDATE $? " Installing dependencies "

mv target/shipping-1.0.jar shipping.jar &>> $LOG_FILE
VALIDATE $? " Renaming jar file "

cp /home/ec2-user/roboshop-shell/shipping.service /etc/systemd/system/shipping.service &>> $LOG_FILE
VALIDATE $? "copying shipping service file"

systemctl daemon-reload
VALIDATE $? "daemon-reload"

systemctl enable shipping
VALIDATE $? "Enabling shipping"

systemctl start shipping  
VALIDATE $? "Starting shipping"

dnf install mysql -y 
VALIDATE $? "Installing mysql client"

mysql -h mysql.satyadaws.online -uroot -pRoboShop@1 < /app/db/schema.sql &>> $LOG_FILE
VALIDATE $? "Loading shipping data"

systemctl restart shipping
VALIDATE $? "Restarting shipping"
