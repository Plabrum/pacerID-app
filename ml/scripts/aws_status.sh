#!/bin/bash
# Check status of EC2 training instance
#
# Usage: ./scripts/aws_status.sh

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ML_DIR="$(dirname "$SCRIPT_DIR")"
INSTANCE_INFO_FILE="$ML_DIR/.aws_instance"

# Check if instance info exists
if [ ! -f "$INSTANCE_INFO_FILE" ]; then
    echo "No active training instance found."
    echo ""
    echo "Run 'make aws-launch' to create an instance."
    exit 0
fi

# Load instance info
source "$INSTANCE_INFO_FILE"

echo "=========================================="
echo "AWS Training Instance Status"
echo "=========================================="
echo ""

# Get instance status
STATUS=$(aws ec2 describe-instances \
    --region $REGION \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].State.Name' \
    --output text 2>/dev/null || echo "not-found")

if [ "$STATUS" = "not-found" ]; then
    echo "ERROR: Instance not found (may have been terminated)"
    rm "$INSTANCE_INFO_FILE"
    exit 1
fi

# Get uptime
LAUNCH_TIME=$(aws ec2 describe-instances \
    --region $REGION \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].LaunchTime' \
    --output text)

echo "Instance ID:    $INSTANCE_ID"
echo "Status:         $STATUS"
echo "Public IP:      $PUBLIC_IP"
echo "Region:         $REGION"
echo "Instance Type:  g4dn.xlarge"
echo "Launch Time:    $LAUNCH_TIME"
echo ""

if [ "$STATUS" = "running" ]; then
    # Calculate cost estimate
    LAUNCH_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${LAUNCH_TIME%.*}" "+%s" 2>/dev/null || echo "0")
    NOW_EPOCH=$(date +%s)
    HOURS=$((($NOW_EPOCH - $LAUNCH_EPOCH) / 3600))
    COST=$(echo "$HOURS * 0.30" | bc)

    echo "Runtime:        ~$HOURS hours"
    echo "Est. Cost:      ~\$$COST"
    echo ""
    echo "=========================================="
    echo "Quick Commands"
    echo "=========================================="
    echo "Upload code:    make aws-upload"
    echo "SSH:            make aws-ssh"
    echo "Download:       make aws-download"
    echo "Terminate:      make aws-terminate"
else
    echo "=========================================="
    echo "Instance is not running (status: $STATUS)"
fi

echo ""
