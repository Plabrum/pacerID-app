#!/usr/bin/env python3
"""
Main training script for pacemaker classifier.

Usage:
    python scripts/train.py --config configs/base.yaml
    python scripts/train.py --config configs/base.yaml --epochs 30 --batch-size 64
"""

import argparse
import sys
import yaml
import torch
import torch.nn as nn
from pathlib import Path

# Add ml/src to path so we can import our modules
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from data import create_data_loaders
from models import create_model
from training import create_trainer, setup_callbacks


def load_config(config_path: str) -> dict:
    """Load configuration from YAML file"""
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    return config


def override_config(config: dict, args: argparse.Namespace) -> dict:
    """Override config with command line arguments"""
    if args.epochs is not None:
        config['training']['epochs'] = args.epochs
    if args.batch_size is not None:
        config['data']['batch_size'] = args.batch_size
    if args.learning_rate is not None:
        config['training']['learning_rate'] = args.learning_rate
    if args.device is not None:
        config['training']['device'] = args.device
    return config


def main():
    parser = argparse.ArgumentParser(description="Train pacemaker classifier")
    parser.add_argument(
        "--config",
        type=str,
        default="configs/base.yaml",
        help="Path to config file"
    )
    parser.add_argument("--epochs", type=int, help="Number of epochs")
    parser.add_argument("--batch-size", type=int, help="Batch size")
    parser.add_argument("--learning-rate", type=float, help="Learning rate")
    parser.add_argument("--device", type=str, choices=["cuda", "cpu"], help="Device to use")

    args = parser.parse_args()

    # Load and override config
    print(f"Loading config from: {args.config}")
    config = load_config(args.config)
    config = override_config(config, args)

    # Set up paths from config (relative to ml/ directory)
    ml_dir = Path(__file__).parent.parent
    train_dir = ml_dir / config['data']['train_dir']
    test_dir = ml_dir / config['data']['test_dir']
    output_dir = ml_dir / config['output']['dir']

    # Verify directories exist
    if not train_dir.exists():
        print(f"\nERROR: Training directory does not exist: {train_dir}")
        print("Run 'make download-data' to download the dataset first.\n")
        exit(1)
    if not test_dir.exists():
        print(f"\nERROR: Test directory does not exist: {test_dir}")
        print("Run 'make download-data' to download the dataset first.\n")
        exit(1)

    # Print configuration
    print("\n" + "="*60)
    print("TRAINING CONFIGURATION")
    print("="*60)
    print(f"Train directory: {train_dir}")
    print(f"Test directory:  {test_dir}")
    print(f"Output directory: {output_dir}")
    print(f"Architecture:    {config['model']['architecture']}")
    print(f"Batch size:      {config['data']['batch_size']}")
    print(f"Epochs:          {config['training']['epochs']}")
    print(f"Learning rate:   {config['training']['learning_rate']}")
    print(f"Device:          {config['training']['device']}")
    print("="*60 + "\n")

    # Check device availability
    device = config['training']['device']
    if device == "cuda" and not torch.cuda.is_available():
        print("WARNING: CUDA requested but not available. Falling back to CPU.")
        device = "cpu"
        config['training']['device'] = device

    # Create data loaders
    print("Loading dataset...")
    train_loader, test_loader, num_classes, class_names = create_data_loaders(
        train_dir=str(train_dir),
        test_dir=str(test_dir),
        batch_size=config['data']['batch_size'],
        img_size=config['data']['img_size'],
        num_workers=config['data']['num_workers'],
    )

    # Create model
    print("\nCreating model...")
    model = create_model(
        architecture=config['model']['architecture'],
        num_classes=num_classes,
        pretrained=config['model']['pretrained'],
        device=device,
    )

    # Set up training
    print("\nSetting up training...")
    loss_fn = nn.CrossEntropyLoss()
    optimizer = torch.optim.Adam(
        (p for p in model.parameters() if p.requires_grad),
        lr=config['training']['learning_rate']
    )

    trainer, evaluator = create_trainer(model, optimizer, loss_fn, device)

    # Set up callbacks
    setup_callbacks(
        trainer=trainer,
        evaluator=evaluator,
        train_loader=train_loader,
        test_loader=test_loader,
        output_dir=str(output_dir),
        verbose=config['training']['verbose'],
    )

    # Store model and optimizer in engine state for checkpointing
    trainer.state.model = model
    trainer.state.optimizer = optimizer

    # Train!
    print("\nStarting training...\n")
    trainer.run(train_loader, max_epochs=config['training']['epochs'])

    # Save final model
    final_model_path = output_dir / f"{config['output']['model_name']}_final.pt"
    torch.save(model.state_dict(), final_model_path)
    print(f"\nFinal model saved to: {final_model_path}")

    print("\nTraining complete!")


if __name__ == "__main__":
    main()
