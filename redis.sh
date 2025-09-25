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

dnf module disable redis -y &>>$LOG_FILE
validate $? "Disabling redis.."

dnf module enable redis:7 -y &>>$LOG_FILE
validate $? "Enabling redis version 7.."

dnf install redis -y &>>$LOG_FILE
validate $? "Installing redis.."

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf
validate $? "Updating global IP  and Protect mode for redis.."

systemctl enable redis &>>$LOG_FILE
validate $? "Enabling redis service.."
systemctl start redis 
validate $? "Starting redis service.."

END_TIME=$(date +%S)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"
