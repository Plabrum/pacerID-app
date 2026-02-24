# PacerID ML Training Pipeline

Clean, modular training pipeline for pacemaker image classification using PyTorch and transfer learning.

## Quick Start

### AWS GPU Training (Recommended)

For fast, cost-effective training on GPU:

```bash
make aws-launch          # Launch spot instance (~$0.30/hour)
make aws-upload          # Upload code
make aws-ssh             # SSH in, then follow setup prompts
# ... train on instance ...
make aws-download        # Download results
make aws-terminate       # Stop instance
```

**See [AWS_TRAINING.md](AWS_TRAINING.md) for complete guide.**

### Local Training

```bash
# From repo root

# 1. First time setup
make install-ml
conda activate pacerid-ml

# 2. Download training data (one time)
make download-data

# 3. Train model
make train

# 4. Export and sync to iOS
make export
make sync-model VERSION=v1.0.0
```


## Project Structure

```
ml/
├── src/                    # Python package
│   ├── data/              # Dataset loading
│   │   └── dataset.py     # Data loaders with augmentation
│   ├── models/            # Model architectures
│   │   └── classifier.py  # Transfer learning models
│   └── training/          # Training utilities
│       ├── trainer.py     # Ignite trainer setup
│       └── callbacks.py   # Logging and checkpointing
├── scripts/
│   ├── train.py           # Main training script
│   ├── export.py          # Export to CoreML
│   └── setup_ec2.sh       # EC2 environment setup
├── configs/
│   └── base.yaml          # Training configuration
├── datasets/              # Training data (not in git)
│   ├── processed/
│   │   ├── Train/        # Training images (organized by class)
│   │   └── Test/         # Test images (organized by class)
│   └── raw/              # Original datasets
├── models/                # Versioned CoreML models (in git)
│   ├── current/          # Symlink to active version
│   └── versions/         # Version history (v1.0.0, v1.1.0, etc.)
├── output/                # Training outputs (not in git)
│   ├── checkpoint_*.pt   # Training checkpoints
│   └── PacemakerClassifier.mlmodel  # Exported CoreML model
├── notebooks/             # Experimental notebooks
├── environment.yml        # Conda environment
└── README.md             # This file
```

## Dataset Format

The `download-data` script automatically downloads and sets up the dataset from Kaggle.

Final directory structure:

```
datasets/
├── raw/                    # Downloaded from Kaggle
│   ├── Train/
│   │   ├── boston_scientific_accolade/
│   │   │   ├── img1.jpg
│   │   │   └── img2.jpg
│   │   └── ... (45 classes)
│   └── Test/
│       └── ... (same structure)
└── processed/              # Symlinks to raw/ (for potential future preprocessing)
    ├── Train -> ../raw/Train
    └── Test -> ../raw/Test
```

### Using Custom Datasets

To use your own dataset instead of Kaggle:

1. Edit `configs/base.yaml` and update the paths
2. Place your images in the appropriate directory structure
3. Skip the `download-data` step

### Kaggle API Setup

The download script requires Kaggle API credentials:

1. Go to https://www.kaggle.com/account
2. Click "Create New API Token" (downloads `kaggle.json`)
3. Move to `~/.kaggle/kaggle.json`
4. Run `chmod 600 ~/.kaggle/kaggle.json`

Or set environment variables:
```bash
export KAGGLE_USERNAME=<your-username>
export KAGGLE_KEY=<your-api-key>
```

## Configuration

All paths and settings are defined in `configs/base.yaml`:

```yaml
data:
  # Data source
  kaggle_dataset: "jamesphoward/pacemakers"

  # Local paths (relative to ml/ directory)
  raw_dir: "datasets/raw"
  train_dir: "datasets/processed/Train"
  test_dir: "datasets/processed/Test"

  # Data loading settings
  batch_size: 32
  img_size: 224

model:
  architecture: "densenet121"  # densenet121, resnet50, mobilenet_v3_small
  pretrained: true

training:
  epochs: 20
  learning_rate: 0.001
  device: "cuda"
```

The config is the **single source of truth** for all paths - the download script, training script, and export script all read from it.

Or override via command line:

```bash
python scripts/train.py --config configs/base.yaml \
    --epochs 30 \
    --batch-size 64 \
    --learning-rate 0.0001
```

## Training Workflow

1. **Setup Environment** (one time): `make install-ml && conda activate pacerid-ml`
2. **Download Data** (one time): `make download-data`
3. **Train**: `make train` or `python scripts/train.py --config configs/base.yaml`
4. **Export**: `make export` or `python scripts/export.py --checkpoint output/checkpoint_latest.pt`
5. **Sync to iOS**: `make sync-model VERSION=v1.0.0`
6. **Build iOS**: `make build` (from repo root)

## Model Architectures

Supported pre-trained models (ImageNet weights):

- **DenseNet121** (default): Good balance of accuracy and size (~30MB)
- **ResNet50**: Classic architecture, proven reliability (~100MB)
- **MobileNetV3-Small**: Smallest, fastest inference (~5MB)

## Tips for EC2 Training

- **Instance Types**:
  - `g4dn.xlarge`: $0.526/hr, good for most training runs
  - `p3.2xlarge`: $3.06/hr, faster for large datasets

- **Use Spot Instances**: Save up to 70% for non-critical training

- **Setup Time**: ~5 minutes for environment setup on first run

- **Data Transfer**: Consider uploading datasets to S3 first, then download on instance to save time

## Troubleshooting

**CUDA out of memory**: Lower batch size in config
```bash
python scripts/train.py --batch-size 16
```

**Dataset not found**: Check paths in config are relative to `ml/` directory

**Model export fails**: Ensure PyTorch model is in eval mode and on CPU

## Next Steps

- Add experiment tracking (wandb, mlflow)
- Add validation split for proper hyperparameter tuning
- Add learning rate scheduling
- Add early stopping
- Support for multi-GPU training
