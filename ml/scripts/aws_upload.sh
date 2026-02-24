#!/bin/bash
# Upload ML code to EC2 instance
#
# Usage: ./scripts/aws_upload.sh

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

echo "=========================================="
echo "Upload ML Code to AWS Instance"
echo "=========================================="
echo "Instance:     $PUBLIC_IP"
echo "Destination:  ubuntu@$PUBLIC_IP:~/workspace/ml/ (includes datasets)"
echo "=========================================="
echo ""

# Upload ml/ directory, excluding outputs
echo "Uploading files..."
rsync -avz --progress \
    --exclude 'output/' \
    --exclude '__pycache__/' \
    --exclude '*.pyc' \
    --exclude '.aws_instance' \
    --exclude 'notebooks/' \
    -e "ssh -i ~/.ssh/$KEY_NAME.pem -o StrictHostKeyChecking=no" \
    "$ML_DIR/" \
    ubuntu@$PUBLIC_IP:~/workspace/ml/

echo ""
echo "✓ Upload complete"
echo ""
echo "Next step: SSH into instance and start training"
echo "  make aws-ssh"
