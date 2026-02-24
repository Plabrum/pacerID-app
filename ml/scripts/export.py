#!/usr/bin/env python3
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "torch>=2.0.0",
#   "torchvision>=0.15.0",
#   "coremltools>=7.0",
#   "pyyaml>=6.0",
# ]
# ///
"""
Export trained PyTorch model to CoreML format for iOS integration.

Usage:
    python scripts/export.py --model output/PacemakerClassifier_final.pt --config configs/base.yaml
    python scripts/export.py --checkpoint output/checkpoint_latest.pt --architecture densenet121
"""

import argparse
import sys
import yaml
import torch
import coremltools as ct
from pathlib import Path

# Add ml/src to path
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

from models import create_model


def export_to_coreml(
    model: torch.nn.Module,
    output_path: str,
    class_labels: list = None,
):
    """
    Export PyTorch model to CoreML format.

    Args:
        model: Trained PyTorch model
        output_path: Path to save .mlmodel file
        class_labels: List of class labels (optional)
    """
    print("\nExporting to CoreML...")

    # Set model to evaluation mode
    model.eval()

    # Create example input (batch_size=1, channels=3, height=224, width=224)
    example_input = torch.rand(1, 3, 224, 224)

    # Trace the model
    print("  Tracing model with example input...")
    traced_model = torch.jit.trace(model, example_input)

    # Convert to CoreML
    print("  Converting to CoreML format...")
    mlmodel = ct.convert(
        traced_model,
        inputs=[ct.ImageType(name="image", shape=(1, 3, 224, 224))],
        classifier_config=ct.ClassifierConfig(class_labels) if class_labels else None,
    )

    # Add metadata
    mlmodel.author = "PacerID ML Pipeline"
    mlmodel.short_description = "Pacemaker image classifier"
    mlmodel.license = "Proprietary"

    # Save
    mlmodel.save(output_path)
    print(f"\nCoreML model saved to: {output_path}")
    print(f"  Model size: {Path(output_path).stat().st_size / (1024*1024):.2f} MB")


def main():
    parser = argparse.ArgumentParser(description="Export model to CoreML")
    parser.add_argument(
        "--model",
        type=str,
        help="Path to trained model file (.pt)"
    )
    parser.add_argument(
        "--checkpoint",
        type=str,
        help="Path to checkpoint file (alternative to --model)"
    )
    parser.add_argument(
        "--config",
        type=str,
        default="configs/base.yaml",
        help="Path to config file (for model architecture)"
    )
    parser.add_argument(
        "--architecture",
        type=str,
        help="Model architecture (overrides config)"
    )
    parser.add_argument(
        "--num-classes",
        type=int,
        default=45,
        help="Number of output classes"
    )
    parser.add_argument(
        "--output",
        type=str,
        help="Output path for .mlmodel file"
    )

    args = parser.parse_args()

    if not args.model and not args.checkpoint:
        parser.error("Either --model or --checkpoint is required")

    # Load config for architecture if not specified
    if args.config and Path(args.config).exists():
        with open(args.config, 'r') as f:
            config = yaml.safe_load(f)
        architecture = args.architecture or config['model']['architecture']
    else:
        if not args.architecture:
            parser.error("--architecture is required when config file is not available")
        architecture = args.architecture

    # Determine output path
    ml_dir = Path(__file__).parent.parent
    if args.output:
        output_path = args.output
    else:
        output_path = ml_dir / "output" / "PacemakerClassifier.mlpackage"

    print("="*60)
    print("EXPORT CONFIGURATION")
    print("="*60)
    print(f"Architecture: {architecture}")
    print(f"Num classes:  {args.num_classes}")
    print(f"Output path:  {output_path}")
    print("="*60)

    # Create model architecture
    print("\nCreating model architecture...")
    model = create_model(
        architecture=architecture,
        num_classes=args.num_classes,
        pretrained=False,
        device="cpu",  # Export on CPU
    )

    # Load weights
    if args.checkpoint:
        print(f"Loading checkpoint: {args.checkpoint}")
        checkpoint = torch.load(args.checkpoint, map_location="cpu")
        model.load_state_dict(checkpoint['model_state_dict'])
    else:
        print(f"Loading model: {args.model}")
        model.load_state_dict(torch.load(args.model, map_location="cpu"))

    # Export
    export_to_coreml(model, str(output_path))

    print("\nExport complete!")
    print(f"\nNext steps:")
    print(f"  1. Test the model: python scripts/test_model.py --model {output_path}")
    print(f"  2. Sync to iOS: make sync-model VERSION=v1.0.0")


if __name__ == "__main__":
    main()
