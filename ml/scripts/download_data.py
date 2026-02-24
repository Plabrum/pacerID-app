#!/usr/bin/env python3
"""
Download pacemaker training data from Kaggle.

This script downloads the dataset specified in the config file and
organizes it into the expected directory structure.

Usage:
    python scripts/download_data.py --config configs/base.yaml

Requirements:
    - Kaggle API credentials set up (~/.kaggle/kaggle.json)
    - Or: KAGGLE_USERNAME and KAGGLE_KEY environment variables
"""

import argparse
import yaml
import shutil
import kagglehub
from pathlib import Path


def load_config(config_path: str) -> dict:
    """Load configuration from YAML file"""
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    return config


def download_and_setup(config: dict, ml_dir: Path):
    """
    Download Kaggle dataset and set up directory structure.

    Args:
        config: Configuration dictionary
        ml_dir: Path to ml/ directory
    """
    kaggle_dataset = config['data']['kaggle_dataset']
    raw_dir = ml_dir / config['data']['raw_dir']
    train_dir = ml_dir / config['data']['train_dir']
    test_dir = ml_dir / config['data']['test_dir']

    print("="*60)
    print("DATASET DOWNLOAD & SETUP")
    print("="*60)
    print(f"Kaggle dataset: {kaggle_dataset}")
    print(f"Raw directory:  {raw_dir}")
    print(f"Train directory: {train_dir}")
    print(f"Test directory:  {test_dir}")
    print("="*60 + "\n")

    # Download from Kaggle
    print(f"Downloading dataset from Kaggle: {kaggle_dataset}")
    print("(This may take a few minutes...)\n")

    try:
        download_path = kagglehub.dataset_download(kaggle_dataset)
        print(f"\nDataset downloaded to: {download_path}\n")
    except Exception as e:
        print(f"\nERROR: Failed to download dataset from Kaggle.")
        print(f"Error: {e}\n")
        print("Make sure you have Kaggle API credentials set up:")
        print("  1. Go to https://www.kaggle.com/account")
        print("  2. Create API token (downloads kaggle.json)")
        print("  3. Move to ~/.kaggle/kaggle.json")
        print("  4. Run: chmod 600 ~/.kaggle/kaggle.json\n")
        print("Or set environment variables:")
        print("  export KAGGLE_USERNAME=<your-username>")
        print("  export KAGGLE_KEY=<your-api-key>")
        return False

    # Create raw directory and copy downloaded data
    print("Setting up raw dataset directory...")
    raw_dir.mkdir(parents=True, exist_ok=True)

    download_path = Path(download_path)

    # The Kaggle download contains Train/ and Test/ subdirectories
    # Copy them to our raw directory
    if (download_path / "Train").exists():
        print(f"  Copying Train data...")
        if (raw_dir / "Train").exists():
            shutil.rmtree(raw_dir / "Train")
        shutil.copytree(download_path / "Train", raw_dir / "Train")

    if (download_path / "Test").exists():
        print(f"  Copying Test data...")
        if (raw_dir / "Test").exists():
            shutil.rmtree(raw_dir / "Test")
        shutil.copytree(download_path / "Test", raw_dir / "Test")

    # Create processed directories (symlink or copy from raw)
    print("\nSetting up processed dataset directories...")
    train_dir.parent.mkdir(parents=True, exist_ok=True)
    test_dir.parent.mkdir(parents=True, exist_ok=True)

    # Use symlinks to avoid duplicating data
    if train_dir.exists():
        train_dir.unlink() if train_dir.is_symlink() else shutil.rmtree(train_dir)
    if test_dir.exists():
        test_dir.unlink() if test_dir.is_symlink() else shutil.rmtree(test_dir)

    train_dir.symlink_to(raw_dir / "Train")
    test_dir.symlink_to(raw_dir / "Test")

    print(f"  Train -> {raw_dir / 'Train'}")
    print(f"  Test  -> {raw_dir / 'Test'}")

    # Count files
    train_count = len(list((raw_dir / "Train").rglob("*.*")))
    test_count = len(list((raw_dir / "Test").rglob("*.*")))
    num_classes = len(list((raw_dir / "Train").iterdir()))

    print("\n" + "="*60)
    print("DATASET READY!")
    print("="*60)
    print(f"Training samples:  {train_count}")
    print(f"Test samples:      {test_count}")
    print(f"Number of classes: {num_classes}")
    print("="*60 + "\n")
    print("Next steps:")
    print("  1. Review dataset: ls -la datasets/processed/Train")
    print("  2. Start training: make train")
    print("  3. Or customize:   python scripts/train.py --config configs/base.yaml --epochs 30")

    return True


def main():
    parser = argparse.ArgumentParser(description="Download pacemaker training data")
    parser.add_argument(
        "--config",
        type=str,
        default="configs/base.yaml",
        help="Path to config file"
    )
    args = parser.parse_args()

    # Load config
    config = load_config(args.config)

    # Get ml/ directory (parent of scripts/)
    ml_dir = Path(__file__).parent.parent

    # Download and set up data
    success = download_and_setup(config, ml_dir)

    if not success:
        exit(1)


if __name__ == "__main__":
    main()
