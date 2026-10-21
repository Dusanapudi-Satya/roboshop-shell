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
 
 # Step 7: Configure systemd service
cp "${SCRIPT_DIR}/rabbitmq.repo" /etc/yum.repos.d/rabbitmq.repo &>> "$LOG_FILE"
VALIDATE $? "Copying systemd service file"
curl -s https://packagecloud.io/install/repositories/rabbitmq/erlang/script.rpm.sh | bash &>> $LOG_FILE
VALIDATE $? "Downloading erlang script"

curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash &>> $LOG_FILE
VALIDATE $? "Downloading rabbitmq script"

dnf install rabbitmq-server -y &>> $LOG_FILE
VALIDATE $? "Installing rabbitmq server"

systemctl enable rabbitmq-server &>> $LOG_FILE
VALIDATE $? "Enabling rabbitmq server"

systemctl start rabbitmq-server &>> $LOG_FILE
VALIDATE $? "Starting rabbitmq server"
#check whether the RabbitMQ user exists before attempting to create it
sudo rabbitmqctl list_users | grep -w roboshop >/dev/null 2>&1
if [ $? -ne 0 ]; then
    rabbitmqctl add_user roboshop roboshop123
    else
        echo -e "$Y RabbitMQ user already exists $N"
fi

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOG_FILE
VALIDATE $? "Setting permissions"
echo -e "${G} Rabbitmq setup completed successfully.${N}"
