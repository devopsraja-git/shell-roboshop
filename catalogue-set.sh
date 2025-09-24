#!/bin/bash

set -euo pipefail

trap 'echo "There is an error in $LINENO, Command is: $BASH_COMMAND"' ERR

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

uid=$(id -u)


LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
MONGODB_HOST=mongodb.devraxtech.fun

mkdir -p $LOGS_FOLDER
echo "Script started executed at $(date)"

if [ $uid -ne 0 ]; then
    echo -e "ERROR:: Please run this as a $G ROOT $N User Privileges only"
    exit 1
fi


dnf module disable nodejs -y &>>$LOG_FILE

dnf module enable nodejs:20 -y &>>$LOG_FILE

dnf install nodejs -y &>>$LOG_FILE

id roboshop &>>$LOG_FILE
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    else
        echo -e "User roboshop already exists...$Y SKIPPING.. $N"
    fi

mkdir -p /app

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE

cd /app 

rm -rf /app/*

unzip /tmp/catalogue.zip &>>$LOG_FILE

npm install &>>$LOG_FILE

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service

systemctl daemon-reload &>>$LOG_FILE

systemctl enable catalogue &>>$LOG_FILE

systemctl start catalogue

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo

dnf install mongodb-mongosh -y &>>$LOG_FILE

INDEX=$(mongosh mongodb.devraxtech.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
    if [ $INDEX -le 0 ]; then
        mongosh --host $MONGODB_HOST < /app/db/master-data.js &>>$LOG_FILE
        validate $? "Loading mongodb data ..."
    else
        echo -e "Catalogue products already loaded...$Y SKIPPING... $N"
    fi

systemctl restart catalogue
