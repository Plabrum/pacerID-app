#!/bin/bash
# Setup script for EC2 GPU instance training
#
# Usage:
#   Run this script on a fresh EC2 instance (Amazon Linux 2 or Ubuntu)
#   ./setup_ec2.sh

set -e

echo "=========================================="
echo "PacerID ML Training - EC2 Setup"
echo "=========================================="

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS"
    exit 1
fi

echo "Detected OS: $OS"

# Install system dependencies
echo ""
echo "Installing system dependencies..."
if [ "$OS" = "ubuntu" ]; then
    sudo apt-get update
    sudo apt-get install -y wget git
elif [ "$OS" = "amzn" ]; then
    sudo yum update -y
    sudo yum install -y wget git
fi

# Install Miniconda if not already installed
if ! command -v conda &> /dev/null; then
    echo ""
    echo "Installing Miniconda..."
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
    bash miniconda.sh -b -p $HOME/miniconda
    rm miniconda.sh

    # Initialize conda
    eval "$($HOME/miniconda/bin/conda shell.bash hook)"
    conda init bash

    echo "Miniconda installed. Please restart your shell or run:"
    echo "  source ~/.bashrc"
else
    echo "Conda already installed"
fi

# Create conda environment
echo ""
echo "Creating conda environment..."
eval "$($HOME/miniconda/bin/conda shell.bash hook)" || true

if [ -f "environment.yml" ]; then
    conda env create -f environment.yml
    echo ""
    echo "Environment created! Activate it with:"
    echo "  conda activate pacerid-ml"
else
    echo "ERROR: environment.yml not found. Make sure you're in the ml/ directory."
    exit 1
fi

echo ""
echo "=========================================="
echo "Setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Activate environment:  conda activate pacerid-ml"
echo "  2. Verify CUDA:           python -c 'import torch; print(torch.cuda.is_available())'"
echo "  3. Start training:        python scripts/train.py --config configs/base.yaml"
echo ""
