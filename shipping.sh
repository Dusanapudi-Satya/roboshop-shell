#!/bin/bash

# Exit on unexpected pipe failures if needed
set -o pipefail

SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
SCRIPT_NAME=$(basename "$0")
TIMESTAMP=$(date +%F-%H-%M-%S)
LOG_FILE="/tmp/${SCRIPT_NAME}-${TIMESTAMP}.log"

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATE() {
    if [ $1 -ne 0 ]; then 
        echo -e "$2 ... $R FAILED $N (Check $LOG_FILE for details)"
        exit 1
    else 
        echo -e "$2 ... $G SUCCESS $N"
    fi    
}

# Step 1: Check root privileges
ID=$(id -u)
if [ $ID -ne 0 ]; then 
    echo -e "$R Error: Please run with root access. $N"
    exit 1
else 
    echo "Running as root user, starting configuration..."
fi

echo "Script started executing at $TIMESTAMP" &>> "$LOG_FILE"

# Step 2: Install Maven
dnf install maven -y &>> "$LOG_FILE"
VALIDATE $? "Installing Maven"

# Step 3: Create roboshop user if not present
id roboshop &>> "$LOG_FILE"
if [ $? -ne 0 ]; then
    useradd roboshop &>> "$LOG_FILE"
    VALIDATE $? "Creating roboshop user"
else
    echo -e "roboshop user already exists ... $Y SKIPPING $N"
fi

# Step 4: Setup application directory
mkdir -p /app &>> "$LOG_FILE"
VALIDATE $? "Creating /app directory"

# Step 5: Download and extract application artifact
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> "$LOG_FILE"
VALIDATE $? "Downloading shipping artifact"

rm -rf /app/* &>> "$LOG_FILE"
unzip -o /tmp/shipping.zip -d /app &>> "$LOG_FILE"
VALIDATE $? "Extracting shipping artifact"

# Step 6: Build application package
cd /app || exit 1
mvn clean package &>> "$LOG_FILE"
VALIDATE $? "Compiling and packaging Maven dependencies"

mv target/shipping-1.0.jar shipping.jar &>> "$LOG_FILE"
VALIDATE $? "Renaming jar to shipping.jar"

# Step 7: Configure systemd service
cp "${SCRIPT_DIR}/shipping.service" /etc/systemd/system/shipping.service &>> "$LOG_FILE"
VALIDATE $? "Copying systemd service file"

systemctl daemon-reload &>> "$LOG_FILE"
VALIDATE $? "Reloading systemd daemon"

systemctl enable shipping &>> "$LOG_FILE"
VALIDATE $? "Enabling shipping service"

systemctl start shipping &>> "$LOG_FILE"
VALIDATE $? "Starting shipping service"

# Step 8: Database setup and schema load
dnf install mysql -y &>> "$LOG_FILE"
VALIDATE $? "Installing MySQL client"

mysql -h mysql.satyadaws.online -uroot -pRoboShop@1 < /app/db/schema.sql &>> "$LOG_FILE"
VALIDATE $? "Loading database schema"

systemctl restart shipping &>> "$LOG_FILE"
VALIDATE $? "Restarting shipping service"
netstat -lntp | grep 8080 &>> $LOG_FILE
VALIDATE $? "Shipping service listening on port 8080"
echo -e "${G} Shipping setup completed successfully.${N}"
