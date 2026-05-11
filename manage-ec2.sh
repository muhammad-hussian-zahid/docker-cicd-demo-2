#!/bin/bash

# AWS EC2 management for Docker deployments
INSTANCE_ID="i-07155be449979bd7a"  # Replace with your instance ID
REGION="eu-north-1"  # Replace with your region

case "$1" in
    start)
        echo "Starting EC2 instance..."
        aws ec2 start-instances --instance-ids $INSTANCE_ID --region $REGION
        aws ec2 wait instance-running --instance-ids $INSTANCE_ID --region $REGION
        echo "Instance started successfully"
        ;;
    stop)
        echo "Stopping EC2 instance..."
        aws ec2 stop-instances --instance-ids $INSTANCE_ID --region $REGION
        aws ec2 wait instance-stopped --instance-ids $INSTANCE_ID --region $REGION
        echo "Instance stopped successfully"
        ;;
    status)
        aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].State.Name' --output text
        ;;
    ip)
        aws ec2 describe-instances --instance-ids $INSTANCE_ID --region $REGION --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
        ;;
    *)
        echo "Usage: $0 {start|stop|status|ip}"
        exit 1
        ;;
esac
