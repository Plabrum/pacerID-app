#!/bin/bash
# Terminate EC2 training instance
#
# Usage: ./scripts/aws_terminate.sh

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ML_DIR="$(dirname "$SCRIPT_DIR")"
INSTANCE_INFO_FILE="$ML_DIR/.aws_instance"

echo "=========================================="
echo "Terminate AWS Training Instance"
echo "=========================================="
echo ""

# Check if instance info exists
if [ ! -f "$INSTANCE_INFO_FILE" ]; then
    echo "ERROR: No instance info found at $INSTANCE_INFO_FILE"
    echo "No instance to terminate or instance was already terminated."
    exit 1
fi

# Load instance info
source "$INSTANCE_INFO_FILE"

echo "Instance ID: $INSTANCE_ID"
echo "Region:      $REGION"
echo ""

# Confirm termination
read -p "Are you sure you want to terminate this instance? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Termination cancelled"
    exit 0
fi

echo ""
echo "Terminating instance..."

# Cancel spot request if it exists
if [ -n "$SPOT_REQUEST_ID" ]; then
    echo "  Cancelling spot request: $SPOT_REQUEST_ID"
    aws ec2 cancel-spot-instance-requests \
        --region $REGION \
        --spot-instance-request-ids $SPOT_REQUEST_ID &> /dev/null || true
fi

# Terminate instance
echo "  Terminating instance: $INSTANCE_ID"
aws ec2 terminate-instances \
    --region $REGION \
    --instance-ids $INSTANCE_ID > /dev/null

echo "  Waiting for instance to terminate..."
aws ec2 wait instance-terminated --region $REGION --instance-ids $INSTANCE_ID

echo ""
echo "✓ Instance terminated successfully"

# Remove instance info file
rm "$INSTANCE_INFO_FILE"

echo ""
echo "=========================================="
echo "Instance Terminated"
echo "=========================================="
echo "The instance has been terminated and will no longer incur charges."
echo ""
