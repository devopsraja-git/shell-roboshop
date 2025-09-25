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


dnf module disable nginx -y &>>$LOG_FILE
validate $? "nginx disabled"
dnf module enable nginx:1.24 -y &>>$LOG_FILE
validate $? "nginx enabled"
dnf install nginx -y &>>$LOG_FILE
validate $? "Installing nginx.."


systemctl enable nginx &>>$LOG_FILE
validate $? "Enabling Nginx.."
systemctl start nginx &>>$LOG_FILE
validate $? "Starting Nginx.."

rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
validate $? "Removing common code.."

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE
validate $? "Downloading developer code.."

cd /usr/share/nginx/html 
validate $? "Changing to static directory.."
unzip /tmp/frontend.zip &>>$LOG_FILE
validate $? "Unzipping static app code.."


cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
validate $? "Copying developer configuration.."

systemctl restart nginx &>>$LOG_FILE
validate $? "Restarting Nginx.."

END_TIME=$(date +%S)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"