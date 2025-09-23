#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-043a4d7e2b43cb151"

for instance in $@
do
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --count 1 --instance-type t3.micro --security-group-ids sg-043a4d7e2b43cb151 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=Test}]" --query 'Instances[0].InstanceId' --output text)

    #GET PRIVAE IP

    if [ $instance != frontend ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    fi

    echo "$instance: $IP"
done