#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

uid=$(id -u)


LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
START_TIME=$(date +$s)

mkdir -p $LOGS_FOLDER
echo "Script started executed at $(date)"

if [ $uid -ne 0 ]; then
    echo -e "ERROR:: Please run this as a $G ROOT $N User Privileges only"
    exit 1
fi

validate(){
    if [ $1 -ne 0 ]; then
    echo -e "$2 is $R FAILED $N"
    exit 1
else
    echo -e "$2 is $G SUCCESSFUL $N"
fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
validate $? "Adding mongo repo"

dnf install mongodb-org -y &>>$LOG_FILE
validate $? "Installing mongodb"

systemctl enable mongod &>>$LOG_FILE
validate $? "Enable MongoDB"

systemctl start mongod
validate $? "Starting.. MongoDB"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "Update mongodb IP address"

systemctl restart mongod
validate $? "Restarting mongodb service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"