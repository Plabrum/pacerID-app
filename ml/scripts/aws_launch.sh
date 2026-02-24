#!/bin/bash
# Launch EC2 spot instance for ML training
#
# Usage: ./scripts/aws_launch.sh

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ML_DIR="$(dirname "$SCRIPT_DIR")"

# Configuration
INSTANCE_TYPE="g4dn.xlarge"
REGION="${AWS_REGION:-us-east-1}"
KEY_NAME="${AWS_KEY_NAME:-}"
SECURITY_GROUP="${AWS_SECURITY_GROUP:-}"
SPOT_PRICE="0.30"  # Max price per hour (on-demand is ~$0.526)

echo "=========================================="
echo "PacerID ML Training - AWS Spot Instance"
echo "=========================================="
echo "Instance type: $INSTANCE_TYPE"
echo "Region:        $REGION"
echo "Max price:     \$$SPOT_PRICE/hour"
echo "=========================================="
echo ""

# Check AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "ERROR: AWS CLI not found. Install with:"
    echo "  brew install awscli"
    echo "  aws configure"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "ERROR: AWS credentials not configured."
    echo "Run: aws configure"
    exit 1
fi

echo "✓ AWS CLI configured"
echo ""

# Get the latest Deep Learning AMI
echo "Finding latest Deep Learning AMI..."
AMI_ID=$(aws ec2 describe-images \
    --region $REGION \
    --owners amazon \
    --filters "Name=name,Values=Deep Learning Base OSS Nvidia Driver GPU AMI (Ubuntu 22.04)*" \
              "Name=state,Values=available" \
    --query 'Images | sort_by(@, &CreationDate) | [-1].ImageId' \
    --output text)

if [ -z "$AMI_ID" ] || [ "$AMI_ID" = "None" ]; then
    echo "ERROR: Could not find Deep Learning AMI"
    exit 1
fi

echo "✓ Found AMI: $AMI_ID"
echo ""

# Check/create key pair
if [ -z "$KEY_NAME" ]; then
    KEY_NAME="pacerid-ml-key"
    echo "Checking for SSH key pair: $KEY_NAME"

    if ! aws ec2 describe-key-pairs --region $REGION --key-names $KEY_NAME &> /dev/null; then
        echo "  Creating key pair..."
        mkdir -p ~/.ssh
        aws ec2 create-key-pair \
            --region $REGION \
            --key-name $KEY_NAME \
            --query 'KeyMaterial' \
            --output text > ~/.ssh/$KEY_NAME.pem
        chmod 400 ~/.ssh/$KEY_NAME.pem
        echo "  ✓ Created key pair: ~/.ssh/$KEY_NAME.pem"
    else
        echo "  ✓ Key pair exists"
    fi
else
    echo "Using existing key pair: $KEY_NAME"
fi

echo ""

# Check/create security group
if [ -z "$SECURITY_GROUP" ]; then
    SECURITY_GROUP="pacerid-ml-sg"
    echo "Checking for security group: $SECURITY_GROUP"

    if ! aws ec2 describe-security-groups --region $REGION --group-names $SECURITY_GROUP &> /dev/null; then
        echo "  Creating security group..."

        # Get default VPC
        VPC_ID=$(aws ec2 describe-vpcs \
            --region $REGION \
            --filters "Name=isDefault,Values=true" \
            --query 'Vpcs[0].VpcId' \
            --output text)

        # Create security group
        aws ec2 create-security-group \
            --region $REGION \
            --group-name $SECURITY_GROUP \
            --description "Security group for PacerID ML training" \
            --vpc-id $VPC_ID > /dev/null

        # Allow SSH from anywhere (you may want to restrict this to your IP)
        aws ec2 authorize-security-group-ingress \
            --region $REGION \
            --group-name $SECURITY_GROUP \
            --protocol tcp \
            --port 22 \
            --cidr 0.0.0.0/0 > /dev/null

        echo "  ✓ Created security group"
    else
        echo "  ✓ Security group exists"
    fi
else
    echo "Using existing security group: $SECURITY_GROUP"
fi

echo ""

# Get security group ID
SG_ID=$(aws ec2 describe-security-groups \
    --region $REGION \
    --group-names $SECURITY_GROUP \
    --query 'SecurityGroups[0].GroupId' \
    --output text)
echo "✓ Security group ID: $SG_ID"

# Get subnet from default VPC
echo "Finding subnet in default VPC..."
DEFAULT_VPC_ID=$(aws ec2 describe-vpcs \
    --region $REGION \
    --filters "Name=isDefault,Values=true" \
    --query 'Vpcs[0].VpcId' \
    --output text)

SUBNET_ID=$(aws ec2 describe-subnets \
    --region $REGION \
    --filters "Name=vpc-id,Values=$DEFAULT_VPC_ID" \
    --query 'Subnets[0].SubnetId' \
    --output text)

if [ -z "$SUBNET_ID" ] || [ "$SUBNET_ID" = "None" ]; then
    echo "ERROR: No subnets found in default VPC $DEFAULT_VPC_ID"
    echo "Create a default subnet with:"
    echo "  aws ec2 create-default-subnet --availability-zone ${REGION}a"
    exit 1
fi
echo "✓ Using subnet: $SUBNET_ID"
echo ""

# Create user data script for instance initialization
USER_DATA=$(cat <<'EOF'
#!/bin/bash
# Initialize instance
echo "Starting PacerID ML training instance setup..."

# Update system
export DEBIAN_FRONTEND=noninteractive
apt-get update

# Install git if not present
apt-get install -y git

# Create workspace
mkdir -p /home/ubuntu/workspace
chown -R ubuntu:ubuntu /home/ubuntu/workspace

echo "Instance initialization complete"
EOF
)

# Launch on-demand instance
echo "Launching on-demand instance..."
echo "(This may take 1-2 minutes...)"
echo ""

INSTANCE_ID=$(aws ec2 run-instances \
    --region $REGION \
    --image-id "$AMI_ID" \
    --instance-type "$INSTANCE_TYPE" \
    --key-name "$KEY_NAME" \
    --security-group-ids "$SG_ID" \
    --subnet-id "$SUBNET_ID" \
    --user-data "$(echo "$USER_DATA" | base64)" \
    --block-device-mappings '[{"DeviceName":"/dev/sda1","Ebs":{"VolumeSize":100,"VolumeType":"gp3","DeleteOnTermination":true}}]' \
    --count 1 \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "  Instance ID: $INSTANCE_ID"

# Tag the instance
aws ec2 create-tags \
    --region $REGION \
    --resources $INSTANCE_ID \
    --tags Key=Name,Value="pacerid-ml-training" Key=Project,Value="PacerID"

# Wait for instance to be running
echo "  Waiting for instance to be running..."
aws ec2 wait instance-running --region $REGION --instance-ids $INSTANCE_ID

# Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --region $REGION \
    --instance-ids $INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "✓ Instance running: $PUBLIC_IP"
echo ""

# Save instance info
INSTANCE_INFO_FILE="$ML_DIR/.aws_instance"
cat > "$INSTANCE_INFO_FILE" <<EOL
INSTANCE_ID=$INSTANCE_ID
REGION=$REGION
PUBLIC_IP=$PUBLIC_IP
KEY_NAME=$KEY_NAME
SPOT_REQUEST_ID=$SPOT_REQUEST_ID
EOL

echo "=========================================="
echo "Instance Ready!"
echo "=========================================="
echo "Instance ID:  $INSTANCE_ID"
echo "Public IP:    $PUBLIC_IP"
echo "Region:       $REGION"
echo "Key:          ~/.ssh/$KEY_NAME.pem"
echo "=========================================="
echo ""
echo "Waiting for SSH to be ready (this may take 1-2 minutes)..."

# Wait for SSH to be ready
for i in {1..30}; do
    if ssh -i ~/.ssh/$KEY_NAME.pem \
           -o StrictHostKeyChecking=no \
           -o ConnectTimeout=5 \
           ubuntu@$PUBLIC_IP "echo 'SSH ready'" &> /dev/null; then
        echo "✓ SSH ready"
        break
    fi
    echo -n "."
    sleep 10
done

echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "1. Upload code to instance:"
echo "   make aws-upload"
echo ""
echo "2. SSH into instance:"
echo "   make aws-ssh"
echo ""
echo "3. On instance, run training:"
echo "   cd workspace/ml"
echo "   ./scripts/setup_ec2.sh"
echo "   source ~/.bashrc"
echo "   conda activate pacerid-ml"
echo "   python scripts/download_data.py --config configs/base.yaml"
echo "   python scripts/train.py --config configs/base.yaml"
echo ""
echo "4. Download results:"
echo "   make aws-download"
echo ""
echo "5. Terminate instance when done:"
echo "   make aws-terminate"
echo ""
echo "=========================================="
echo "Estimated cost: ~\$0.526/hour (on-demand)"
echo "=========================================="
