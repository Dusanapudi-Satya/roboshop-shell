#!/bin/bash
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Step 1: Check root privileges
ID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
LOG_FILE="/tmp/mongodb-$TIMESTAMP.log"

echo "Script started executing at $TIMESTAMP" &>> "$LOG_FILE"

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e " $2 .. $R Failed $N"
        exit 1
    else
        echo -e " $2 .. $G SUCCESS $N"
    fi
}

if [ "$ID" -ne 0 ]; then
    echo -e " $R Error: Please run with root access $N "
    exit 1
else
    echo "You are a root user, proceeding with configuration..."
fi

# Step 2: Configure repository
cp mongo.repo /etc/yum.repos.d/mongo.repo &>> "$LOG_FILE"
VALIDATE $? "Copying mongodb.repo"

# Step 3: Install MongoDB
dnf install mongodb-org -y &>> "$LOG_FILE"
VALIDATE $? "Installing MongoDB"

# Step 4: Enable and start service
systemctl enable mongod &>> "$LOG_FILE"
VALIDATE $? "Enabling MongoDB service"

systemctl start mongod &>> "$LOG_FILE"
VALIDATE $? "Starting MongoDB service"

# Step 5: Configure remote access
sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>> "$LOG_FILE"
VALIDATE $? "Configuring remote access (bindIp 0.0.0.0)"

# Step 6: Restart service and wait for socket initialization
systemctl restart mongod &>> "$LOG_FILE"
VALIDATE $? "Restarting MongoDB"

# Give the daemon 2 seconds to bind to port 27017
sleep 2

# Step 7: Check listening port using ss (built-in) instead of netstat
ss -lntp | grep -q 27017
VALIDATE $? "MongoDB service listening on port 27017"

echo -e "${G}MongoDB setup completed successfully.${N}"