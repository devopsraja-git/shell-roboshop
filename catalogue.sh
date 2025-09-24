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
MONGODB_HOST=mongodb.devraxtech.fun

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
    echo -e "$2 $G SUCCESSFUL $N"
fi
}


dnf module disable nodejs -y &>>$LOG_FILE
validate $? "nodejs disabled"

dnf module enable nodejs:20 -y &>>$LOG_FILE
validate $? "Enabled nodejs 20v"

dnf install nodejs -y &>>$LOG_FILE
validate $? "Installing nodejs.."

id roboshop
    if [ $? != 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        validate $? "User roboshop created"
    else
        echo -e "User roboshop already exists...$Y SKIPPING.. $N"
    fi

mkdir -p /app
validate $? "Creating app directory.."

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE
validate $? "Downloading catalogue application.."
cd /app 
validate $? "Changing to app directory.."
rm -rf /app/*
validate $? "Remove existing catalogue application code.."
unzip /tmp/catalogue.zip &>>$LOG_FILE
validate $? "Unzipping/Extracting the app code.."


npm install &>>$LOG_FILE
validate $? "Installing dependencies.."

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
validate $? "Copying catalogue services.."

systemctl daemon-reload &>>$LOG_FILE

systemctl enable catalogue &>>$LOG_FILE
validate $? "Enabling Catalogue service.."
systemctl start catalogue
validate $? "Starting Catalogue service.."

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Creating mongo repo"

dnf install mongodb-mongosh -y &>>$LOG_FILE
validate $? "Installing mongodb client.."

mongosh --host $MONGODB_HOST < /app/db/master-data.js &>>$LOG_FILE
validate $? "Loading mongodb data ..."