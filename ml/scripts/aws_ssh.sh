#!/bin/bash
# SSH into EC2 training instance
#
# Usage: ./scripts/aws_ssh.sh

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ML_DIR="$(dirname "$SCRIPT_DIR")"
INSTANCE_INFO_FILE="$ML_DIR/.aws_instance"

# Check if instance info exists
if [ ! -f "$INSTANCE_INFO_FILE" ]; then
    echo "ERROR: No instance info found."
    echo "Run 'make aws-launch' first to create an instance."
    exit 1
fi

# Load instance info
source "$INSTANCE_INFO_FILE"

echo "Connecting to $PUBLIC_IP..."
echo ""

ssh -i ~/.ssh/$KEY_NAME.pem \
    -o StrictHostKeyChecking=no \
    ubuntu@$PUBLIC_IP
