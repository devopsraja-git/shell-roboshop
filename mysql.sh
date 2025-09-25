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

dnf install mysql-server -y &>>$LOG_FILE
validate $? "Installing mysql server.."

systemctl enable mysqld &>>$LOG_FILE
validate $? "Enable mysql service.."
systemctl start mysqld  &>>$LOG_FILE
validate $? "Start mysql service.."

mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOG_FILE
validate $? "Setting up Root password"

END_TIME=$(date +%S)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME seconds $N"
