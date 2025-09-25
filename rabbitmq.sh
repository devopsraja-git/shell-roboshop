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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
dnf install rabbitmq-server -y &>>$LOG_FILE
validate $? "Installing rabbitmq.."


systemctl enable rabbitmq-server &>>$LOG_FILE
validate $? "Enabling rabbitmq services.."
systemctl start rabbitmq-server &>>$LOG_FILE
validate $? "Starting rabbitmq services.."


rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
validate $? "Adding user roboshop.."
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>$LOG_FILE
validate $? "Setting up permissions.."

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME Seconds $N"

