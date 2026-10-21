#!/bin/bash
SCRIPT_DIR=$(cd -- "$(dirname -- "$0")" && pwd)
SCRIPT_NAME=$(basename "$0")
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Step 1: Check root privileges
ID=$(id -u)
echo "script name: $SCRIPT_NAME"
TIMESTAMP=$(date +%F-%H-%M-%S)
LOG_FILE="/tmp/${SCRIPT_NAME}-${TIMESTAMP}.log"

echo "script started executing at $TIMESTAMP" &>> "$LOG_FILE"

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 .. $R Failed $N"
        exit 1
    else
        echo -e "$2 .. $G SUCCESS $N"
    fi
}

if [ $ID -ne 0 ]; then
    echo -e "$R Error: Please run with root access $N"
    exit 1
else
    echo "you are a root user, proceed to configure"
fi

dnf install golang -y &>>"$LOG_FILE"
VALIDATE $? "Installing golang"

go version &>>"$LOG_FILE"

id roboshop &>/dev/null
if [ $? -ne 0 ]; then
    useradd roboshop &>>"$LOG_FILE"
    VALIDATE $? "Creating Roboshop User"
else
    echo -e "Roboshop user already exists .. $Y Skipping $N"
fi

mkdir -p /app &>>"$LOG_FILE"
VALIDATE $? "Creating app directory"

curl -L -o /tmp/dispatch.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/dispatch-v4.zip &>>"$LOG_FILE"
VALIDATE $? "Downloading dispatch application"

cd /app &>>"$LOG_FILE"
VALIDATE $? "Moving to app directory"

unzip -o /tmp/dispatch.zip &>>"$LOG_FILE"
VALIDATE $? "Unzipping dispatch app"

# If go.mod does not exist in the archive, initialize it
if [ ! -f /app/go.mod ]; then
    go mod init dispatch &>>"$LOG_FILE"
fi

go get &>>"$LOG_FILE"
go build -o dispatch . &>>"$LOG_FILE"
VALIDATE $? "Building dispatch binary"

cp "${SCRIPT_DIR}/dispatch.service" /etc/systemd/system/dispatch.service &>>"$LOG_FILE"
VALIDATE $? "Copying dispatch service file"

systemctl daemon-reload &>>"$LOG_FILE"
VALIDATE $? "daemon-reload"

systemctl enable dispatch &>>"$LOG_FILE"
VALIDATE $? "Enabling dispatch"

systemctl start dispatch &>>"$LOG_FILE"
VALIDATE $? "Starting dispatch"

systemctl status dispatch &>>"$LOG_FILE"
VALIDATE $? "Dispatch status is"

journalctl -u dispatch -n 20 &>>"$LOG_FILE"
VALIDATE $? "Recent logs are:"
echo -e "${G} Dispatch setup completed successfully.${N}"
