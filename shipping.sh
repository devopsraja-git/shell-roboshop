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
MYSQL_HOST=mysql.devraxtech.fun


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

dnf install maven -y &>>$LOG_FILE
validate $? "Installing Mavencode.."

id roboshop &>>$LOG_FILE
    if [ $? -ne 0 ]; then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
        validate $? "Adding user roboshop.."
    else
        echo "User roboshop already exists.. $Y SKIPPING.. $N"
    fi

mkdir -p /app 

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOG_FILE
validate $? "Downloading developer code.."
cd /app 
validate $? "Changing to app directory.."
rm -rf /app/* &>>$LOG_FILE
validate $? "Removing existing app code.."
unzip /tmp/shipping.zip &>>$LOG_FILE
validate $? "Unzipping app code.."


mvn clean package &>>$LOG_FILE
validate $? "Installing maven dependencies.."
mv target/shipping-1.0.jar shipping.jar 

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload &>>$LOG_FILE
validate $? "Reloading daemon services.."


systemctl enable shipping &>>$LOG_FILE
validate $? "Enabling shipping services.."
systemctl start shipping &>>$LOG_FILE
validate $? "Starting shipping services.."


dnf install mysql -y &>>$LOG_FILE
validate $? "Installing mySQL.."

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities' &>>$LOG_FILE
    if [ $? -ne 0 ]; then
        mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
        mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 
        mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql
    else
        echo -e "Shipping data is already loaded ... $Y SKIPPING $N"
    fi

systemctl restart shipping
validate $? "Installing redis.."