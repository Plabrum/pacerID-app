# AWS GPU Training Guide

Complete guide for training pacemaker classifier on AWS EC2 spot instances.

## Prerequisites

1. **AWS CLI installed**:
   ```bash
   brew install awscli
   ```

2. **AWS credentials configured**:
   ```bash
   aws configure
   # Enter your AWS Access Key ID, Secret Access Key, and default region
   ```

3. **Kaggle API credentials** (for downloading dataset on instance):
   - Get your API token from https://www.kaggle.com/account
   - You'll need `KAGGLE_USERNAME` and `KAGGLE_KEY`

## Quick Start

### Complete Training Workflow

```bash
# 1. Launch spot instance
make aws-launch

# 2. Upload code
make aws-upload

# 3. SSH into instance
make aws-ssh

# 4. On instance: Setup environment
cd workspace/ml
./scripts/setup_ec2.sh
source ~/.bashrc
conda activate pacerid-ml

# 5. On instance: Set Kaggle credentials
export KAGGLE_USERNAME=<your-username>
export KAGGLE_KEY=<your-api-key>

# 6. On instance: Download data and train
python scripts/download_data.py --config configs/base.yaml
python scripts/train.py --config configs/base.yaml

# 7. Back on local: Download results
make aws-download

# 8. Export and sync to iOS
make export
make sync-model VERSION=v1.0.0

# 9. Terminate instance
make aws-terminate
```

## Detailed Commands

### `make aws-launch`
Launches a g4dn.xlarge spot instance with Deep Learning AMI.

**What it does**:
- Finds the latest Deep Learning AMI (Ubuntu 22.04 with NVIDIA drivers)
- Creates SSH key pair if needed (saved to `~/.ssh/pacerid-ml-key.pem`)
- Creates security group allowing SSH access
- Requests spot instance at max price $0.30/hour (on-demand is ~$0.526/hour)
- Saves instance info to `ml/.aws_instance`

**Output**: Instance IP and connection instructions

### `make aws-status`
Check instance status, runtime, and estimated cost.

### `make aws-upload`
Upload ML code to instance (excludes datasets and outputs for faster transfer).

### `make aws-ssh`
SSH into the running instance.

### `make aws-download`
Download trained models and checkpoints from instance to local `ml/output/`.

### `make aws-terminate`
Terminate the instance and stop billing.

**Important**: Always terminate when done to avoid charges!

## Instance Details

### Instance Type: g4dn.xlarge
- **GPU**: NVIDIA T4 (16GB)
- **vCPUs**: 4
- **RAM**: 16GB
- **Storage**: 100GB SSD
- **Cost**: ~$0.30/hour (spot) vs $0.526/hour (on-demand)

### Deep Learning AMI
Pre-installed:
- Ubuntu 22.04
- NVIDIA drivers and CUDA
- Python 3.10
- Conda

You only need to install your specific dependencies via `setup_ec2.sh`.

## Cost Estimates

Training time depends on dataset size and epochs:

| Dataset Size | Epochs | Estimated Time | Cost (Spot) |
|--------------|--------|----------------|-------------|
| 5K images    | 20     | ~30-45 min     | ~$0.15-0.23 |
| 10K images   | 20     | ~1-1.5 hours   | ~$0.30-0.45 |
| 20K images   | 20     | ~2-3 hours     | ~$0.60-0.90 |

**Monitor costs**: Use `make aws-status` to check runtime and estimated cost.

## Tips & Best Practices

### 1. Use Spot Instances
- 60-70% cheaper than on-demand
- May be interrupted (rare for g4dn.xlarge)
- Set max price to avoid surprises

### 2. Monitor Training Progress
Use tmux or screen so training continues if SSH disconnects:

```bash
# On instance
tmux new -s training
cd workspace/ml
conda activate pacerid-ml
python scripts/train.py --config configs/base.yaml

# Detach: Ctrl+B, then D
# Reattach later: tmux attach -t training
```

### 3. Save Checkpoints Frequently
Training saves checkpoints every epoch to `output/checkpoint_epoch_*.pt`.

If interrupted, you can resume:
```python
# TODO: Add resume training functionality
```

### 4. Download Results Regularly
Download checkpoints during training to avoid data loss:
```bash
# On local machine
make aws-download
```

### 5. Set Up Cost Alerts
In AWS Console:
1. Go to AWS Billing Dashboard
2. Set up budget alerts
3. Get notified if spending exceeds threshold

## Troubleshooting

### Spot Request Fails
```
ERROR: Spot request failed with status: capacity-not-available
```

**Solutions**:
1. Try different region: `export AWS_REGION=us-west-2`
2. Try different instance type (edit `aws_launch.sh`)
3. Use on-demand instead of spot

### SSH Connection Refused
Wait 1-2 minutes after launch for instance to fully initialize.

### CUDA Out of Memory
Reduce batch size in `ml/configs/base.yaml`:
```yaml
data:
  batch_size: 16  # Reduce from 32
```

### Training Slow
- Check GPU is being used: `nvidia-smi` on instance
- Increase `num_workers` in config if dataset is on fast storage

### Can't Find Instance
```bash
make aws-status  # Check if instance still exists
```

If lost, find manually:
```bash
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=pacerid-ml-training" \
    --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PublicIpAddress]' \
    --output table
```

## Security Considerations

### SSH Key
- Automatically created and saved to `~/.ssh/pacerid-ml-key.pem`
- Permissions set to 400 (read-only for owner)
- Don't commit to git

### Security Group
- Default: Allows SSH (port 22) from anywhere (0.0.0.0/0)
- **Recommended**: Restrict to your IP:
  ```bash
  MY_IP=$(curl -s https://checkip.amazonaws.com)
  aws ec2 authorize-security-group-ingress \
      --group-name pacerid-ml-sg \
      --protocol tcp \
      --port 22 \
      --cidr $MY_IP/32
  ```

### Kaggle Credentials
- Set as environment variables (not in code)
- Don't save to `.bashrc` on instance
- Use AWS Secrets Manager for production

## Advanced Usage

### Using On-Demand Instead of Spot
Edit `ml/scripts/aws_launch.sh` and replace spot request with:
```bash
aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type g4dn.xlarge \
    --key-name $KEY_NAME \
    --security-groups $SECURITY_GROUP
```

### Different Instance Types
Edit `INSTANCE_TYPE` in `aws_launch.sh`:
- `g4dn.2xlarge`: More RAM, faster training
- `p3.2xlarge`: V100 GPU, much faster (but $3/hour)
- `g5.xlarge`: A10G GPU, newer generation

### Multiple Training Runs
Launch multiple instances with different configs:
```bash
# Instance 1: DenseNet
make aws-launch
# Edit config, upload, train

# Instance 2: ResNet (launch separately)
make aws-launch
# Edit config, upload, train
```

Track separately by renaming `.aws_instance` file.

## Cleanup

Always terminate instances when done:

```bash
# Check status
make aws-status

# Terminate
make aws-terminate
```

Verify termination in AWS Console:
https://console.aws.amazon.com/ec2/v2/home#Instances

## Next Steps

After downloading trained model:
1. `make export` - Convert to CoreML
2. `make sync-model VERSION=v1.0.0` - Publish to iOS
3. `make build` - Build iOS app with new model
