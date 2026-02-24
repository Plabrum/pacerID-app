#!/bin/bash
# Download training outputs from EC2 instance
#
# Usage: ./scripts/aws_download.sh

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
echo "Download Training Outputs from AWS"
echo "=========================================="
echo "Instance:    $PUBLIC_IP"
echo "Downloading: output/ directory"
echo "=========================================="
echo ""

# Download output directory
echo "Downloading files..."
mkdir -p "$ML_DIR/output"

rsync -avz --progress \
    --exclude 'checkpoint_epoch_*.pt' \
    -e "ssh -i ~/.ssh/$KEY_NAME.pem -o StrictHostKeyChecking=no" \
    ubuntu@$PUBLIC_IP:~/workspace/ml/output/ \
    "$ML_DIR/output/"

echo ""
echo "✓ Download complete"
echo ""
echo "Files downloaded to: $ML_DIR/output/"
echo ""
echo "Next steps:"
echo "  1. Export to CoreML:  make export"
echo "  2. Sync to iOS:       make sync-model VERSION=v1.0.0"
echo "  3. Terminate instance: make aws-terminate"
