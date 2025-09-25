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


dnf module disable nodejs -y
validate $? "Disable default nodejs version.."
dnf module enable nodejs:20 -y
validate $? "Enabling nodejs v20 version.."

dnf install nodejs -y
validate $? "Installing nodejs v20.."

id roboshop
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        validate $? "Creating user roboshop"
        echo -e "Adding User roboshop $G SUCCESS $N"
    else
        echo -e "User roboshop already existing... $Y SKIPPING $N"
    fi

mkdir -P /app 
validate $? "Creating user directory.."


curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
validate $? "Downloading application code.."

cd /app 
validate $? "Changing to app directory.."

rm -rf /app/*
validate $? "Removing existing catalogue application code.."


unzip /tmp/user.zip
validate $? "Unzipping the app code.."


npm install 
validate $? "Installing code dependencies.."

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service

systemctl daemon-reload
validate $? "Reloading system daemon.."
systemctl enable user 
validate $? "Enabling user services.."
systemctl start user
validate $? "Starting user services.."

