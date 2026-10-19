#!/bin/bash
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
SCRIPT_NAME=$(basename "$0")

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

ID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
LOG_FILE="/tmp/${SCRIPT_NAME}-${TIMESTAMP}.log"
MONGODB_HOST="mongodb.satyadaws.online"

echo "script started executing at $TIMESTAMP" &>> "$LOG_FILE"

VALIDATE(){
    if [ $1 -ne 0 ]; then 
        echo -e " $2 .. $R Failed $N"
        exit 1
    else
        echo -e " $2 .. $G SUCCESS $N"
    fi    
}

# Step 1: Check root privileges
if [ $ID -ne 0 ]; then 
    echo -e " $R Error: Please run with root access $N "
    exit 1
else
    echo " you are a root user , proceed to configure"
fi

# Step 2: Install Node.js 20
dnf module disable nodejs -y &>> "$LOG_FILE"
VALIDATE $? "Disabling current Nodejs"

dnf module enable nodejs:20 -y &>> "$LOG_FILE"
VALIDATE $? "Enabling Nodejs 20 version"

dnf install nodejs -y &>> "$LOG_FILE"
VALIDATE $? "Installing nodejs"

# Step 3: Create roboshop user if not exists
if ! id roboshop &>/dev/null; then
    useradd roboshop &>> "$LOG_FILE"
    VALIDATE $? "Creating Roboshop User"
else
    echo -e "Roboshop user already exists .. $Y Skipping $N"
fi

# Step 4: Setup application code
mkdir -p /app &>> "$LOG_FILE"
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> "$LOG_FILE"
VALIDATE $? "Downloading catalogue application"

cd /app || exit 1
unzip -o /tmp/catalogue.zip &>> "$LOG_FILE"
VALIDATE $? "Unzipping catalogue application"

npm install &>> "$LOG_FILE"
VALIDATE $? "Installing dependencies"

# Grant permissions to roboshop user
chown -R roboshop:roboshop /app &>> "$LOG_FILE"
VALIDATE $? "Setting permissions for /app"
# Copy the service file to systemd directory
cp "/home/ec2-user/roboshop-shell/catalogue.service" /etc/systemd/system/catalogue.service &>> "$LOG_FILE"
VALIDATE $? "Copying catalogue service file"

systemctl daemon-reload &>> "$LOG_FILE"
VALIDATE $? "catalogue daemon reload"

systemctl enable catalogue &>> "$LOG_FILE"
VALIDATE $? "enabling catalogue"

systemctl restart catalogue &>> "$LOG_FILE"
VALIDATE $? "starting catalogue"

# Step 5: Install MongoDB Client and load schema
cp "$SCRIPT_DIR/mongo.repo" /etc/yum.repos.d/mongo.repo &>> "$LOG_FILE"
VALIDATE $? "copying mongo repo file"

dnf install mongodb-mongosh -y &>> "$LOG_FILE"
VALIDATE $? "installing mongodb-client"

mongosh --host "$MONGODB_HOST" </app/db/master-data.js &>> "$LOG_FILE"
VALIDATE $? "Loading catalogue data into mongodb"

echo -e "${G}Catalogue setup completed successfully.${N}"