#!/bin/bash
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
        echo -e "$2 ... $R FAILED $N (See $LOG_FILE)"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

# Step 1: Check root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo -e "$R Error: Please run with root access $N"
    exit 1
fi
echo "Running as root user, proceeding with configuration..."
echo "Script started executing at $TIMESTAMP" &>> "$LOG_FILE"

# Step 2: Configure Node.js 20
dnf module disable nodejs -y &>> "$LOG_FILE"
VALIDATE $? "Disabling default Node.js module"

dnf module enable nodejs:20 -y &>> "$LOG_FILE"
VALIDATE $? "Enabling Node.js 20 module"

dnf install nodejs -y &>> "$LOG_FILE"
VALIDATE $? "Installing Node.js"

# Step 3: Create roboshop user if not present
id roboshop &>> "$LOG_FILE"
if [ $? -ne 0 ]; then
    useradd roboshop &>> "$LOG_FILE"
    VALIDATE $? "Creating roboshop user"
else
    echo -e "Roboshop user already exists ... $Y SKIPPING $N"
fi

# Step 4: Setup application directory & extract code
mkdir -p /app &>> "$LOG_FILE"
VALIDATE $? "Creating /app directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>> "$LOG_FILE"
VALIDATE $? "Downloading cart artifact"

rm -rf /app/* &>> "$LOG_FILE"
unzip -o /tmp/cart.zip -d /app &>> "$LOG_FILE"
VALIDATE $? "Extracting cart artifact"

# Step 5: Install dependencies
cd /app || exit 1
npm install &>> "$LOG_FILE"
VALIDATE $? "Installing npm dependencies"

# Step 6: Fix permissions
chown -R roboshop:roboshop /app &>> "$LOG_FILE"
VALIDATE $? "Setting roboshop ownership on /app"

# Step 7: Copy service file and manage systemd
if [ ! -f "${SCRIPT_DIR}/cart.service" ]; then
    echo -e "${R}Error: cart.service not found in ${SCRIPT_DIR}${N}"
    exit 1
fi

cp "${SCRIPT_DIR}/cart.service" /etc/systemd/system/cart.service &>> "$LOG_FILE"
VALIDATE $? "Copying cart.service to /etc/systemd/system/"

systemctl daemon-reload &>> "$LOG_FILE"
VALIDATE $? "Reloading systemd daemon"

systemctl enable cart &>> "$LOG_FILE"
VALIDATE $? "Enabling cart service"

systemctl start cart &>> "$LOG_FILE"
VALIDATE $? "Starting cart service"

# Step 8: Verify port 8080 binding
echo -n "Waiting for Cart service to listen on port 8080..."
CONNECTED=0
for i in {1..15}; do
    if netstat -lntp 2>/dev/null | grep -q ":8080 "; then
        CONNECTED=1
        break
    fi
    sleep 1
    echo -n "."
done
echo ""

if [ $CONNECTED -eq 1 ]; then
    echo -e "Cart service listening on port 8080 ... $G SUCCESS $N"
    echo -e "${G}Cart setup completed successfully.${N}"
else
    echo -e "Cart service failed to bind to port 8080 ... $R FAILED $N"
    echo "Check 'journalctl -u cart -xe' or $LOG_FILE for details."
    exit 1
fi