#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

uid=$(id -u)


LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
START_TIME=$(date +%s)


mkdir -p $LOGS_FOLDER
echo "Script started executed at $START_TIME"

if [ $uid -ne 0 ]; then
    echo -e "ERROR:: Please run this as a $G ROOT $N User Privileges only"
    exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
    echo -e "$2 $R FAILED $N"
    exit 1
else
    echo -e "$2 $G SUCCESS $N"
fi
}

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
validate $? "Installing python3.."

id roboshop &>>$LOG_FILE
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        validate $? "Adding user roboshop.."
    else
        echo -e "user roboshop already exists. $Y SKIPPING.. $N"
    fi

mkdir /app 
validate $? "Creating application directory.."

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>>$LOG_FILE
validate $? "Downloading developer payment code.."

cd /app 
validate $? "Changing to app dir..."
rm -rf /app/* &>>$LOG_FILE
validate $? "Removing existing code.."
unzip /tmp/payment.zip &>>$LOG_FILE
validate $? "Unzipping payment app code.."

pip3 install -r requirements.txt &>>$LOG_FILE
validate $? "Installing python dependencies.."

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service

systemctl daemon-reload &>>$LOG_FILE
validate $? "Reloading daemon services.."

systemctl enable payment &>>$LOG_FILE
validate $? "Enabling payment services.."
systemctl start payment &>>$LOG_FILE
validate $? "Starting payment services.."