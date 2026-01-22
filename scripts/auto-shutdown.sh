#!/bin/bash

# ==============================================================================
# Script Name: auto-shutdown.sh
# Description: Automates the shutdown of non-production EC2 instances to save costs.
#              Inspired by GeeksforGeeks cost optimization strategy.
#              Schedules: Stop at 10 PM, Start at 9 AM.
# Usage:       ./auto-shutdown.sh [start|stop]
# Requires:    AWS CLI configured with appropriate permissions.
# ==============================================================================

ACTION=$1
REGION="us-east-1"
filters="Name=tag:Environment,Values=Development,Staging"

if [ -z "$ACTION" ]; then
    echo "Usage: $0 [start|stop]"
    exit 1
fi

echo "Fetching instances with tags: $filters in region $REGION..."

# Get Instance IDs for Dev/Staging environments
INSTANCE_IDS=$(aws ec2 describe-instances \
    --filters "$filters" \
    --region $REGION \
    --query "Reservations[].Instances[].InstanceId" \
    --output text)

if [ -z "$INSTANCE_IDS" ]; then
    echo "No matching instances found."
    exit 0
fi

echo "Found instances: $INSTANCE_IDS"

if [ "$ACTION" == "stop" ]; then
    echo "Stopping instances..."
    aws ec2 stop-instances --instance-ids $INSTANCE_IDS --region $REGION
    echo "Instances stopped successfully."
elif [ "$ACTION" == "start" ]; then
    echo "Starting instances..."
    aws ec2 start-instances --instance-ids $INSTANCE_IDS --region $REGION
    echo "Instances started successfully."
else
    echo "Invalid action. Use 'start' or 'stop'."
    exit 1
fi

# ==============================================================================
# Cron Job Setup Instructions:
# 1. Edit crontab: crontab -e
# 2. Add the following lines:
#    # Stop at 10 PM (22:00) every day
#    0 22 * * * /path/to/auto-shutdown.sh stop >> /var/log/ec2-scheduler.log 2>&1
#
#    # Start at 9 AM (09:00) Mon-Fri
#    0 9 * * 1-5 /path/to/auto-shutdown.sh start >> /var/log/ec2-scheduler.log 2>&1
# ==============================================================================
