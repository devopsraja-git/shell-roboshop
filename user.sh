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
START_TIME=$(date +%S)


mkdir -p $LOGS_FOLDER
echo "Script started executed at $(date)"

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


dnf module disable nodejs -y &>>$LOG_FILE
validate $? "Disable default nodejs version.."
dnf module enable nodejs:20 -y &>>$LOG_FILE
validate $? "Enabling nodejs v20 version.."

dnf install nodejs -y &>>$LOG_FILE
validate $? "Installing nodejs v20.."

id roboshop &>>$LOG_FILE
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        validate $? "Creating user roboshop"
        echo -e "Adding User roboshop $G SUCCESS $N"
    else
        echo -e "User roboshop already existing... $Y SKIPPING $N"
    fi

mkdir -p /app 
validate $? "Creating user directory.."


curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
validate $? "Downloading application code.."

cd /app 
validate $? "Changing to app directory.."

rm -rf /app/* &>>$LOG_FILE
validate $? "Removing existing catalogue application code.."


unzip /tmp/user.zip &>>$LOG_FILE
validate $? "Unzipping the app code.."


npm install &>>$LOG_FILE
validate $? "Installing code dependencies.."

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service

systemctl daemon-reload &>>$LOG_FILE
validate $? "Reloading system daemon.."
systemctl enable user &>>$LOG_FILE
validate $? "Enabling user services.."
systemctl start user &>>$LOG_FILE
validate $? "Starting user services.."

END_TIME=$(date +%S)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"

