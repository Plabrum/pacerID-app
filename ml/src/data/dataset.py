"""Dataset loading and preprocessing for pacemaker images"""

import torch
import torchvision
from torchvision import transforms
from pathlib import Path
from typing import Tuple


def get_transforms(
    img_size: int = 224,
    mean: Tuple[float, float, float] = (0.485, 0.456, 0.406),
    std: Tuple[float, float, float] = (0.229, 0.224, 0.225),
    augment: bool = True,
) -> transforms.Compose:
    """
    Get image transforms for training or testing.

    Uses ImageNet normalization for transfer learning compatibility.
    Training transforms include data augmentation to improve generalization.

    Args:
        img_size: Target image size (square)
        mean: Normalization mean per channel (ImageNet default)
        std: Normalization std per channel (ImageNet default)
        augment: Whether to apply data augmentation (for training)

    Returns:
        Composed transforms
    """
    if augment:
        # Training transforms with data augmentation
        return transforms.Compose([
            transforms.RandomResizedCrop(img_size, scale=(0.9, 1.0), ratio=(1.0, 1.0)),
            transforms.RandomAffine(
                degrees=5,
                translate=(0.05, 0.05),
                scale=(0.95, 1.05),
                shear=5
            ),
            transforms.ColorJitter(0.3, 0.3, 0.3),
            transforms.ToTensor(),
            transforms.Normalize(mean=mean, std=std),
        ])
    else:
        # Test transforms without augmentation
        return transforms.Compose([
            transforms.Resize(img_size),
            transforms.ToTensor(),
            transforms.Normalize(mean=mean, std=std),
        ])


def create_data_loaders(
    train_dir: str,
    test_dir: str,
    batch_size: int = 32,
    img_size: int = 224,
    num_workers: int = 0,
) -> Tuple[torch.utils.data.DataLoader, torch.utils.data.DataLoader, int, list]:
    """
    Create training and testing data loaders from image directories.

    Expects directory structure:
        train_dir/
            class1/
                img1.jpg
                img2.jpg
            class2/
                img1.jpg
        test_dir/
            class1/
                img1.jpg
            class2/
                img1.jpg

    Args:
        train_dir: Path to training images directory
        test_dir: Path to testing images directory
        batch_size: Batch size for training
        img_size: Target image size
        num_workers: Number of data loading workers (0 for main thread)

    Returns:
        Tuple of (train_loader, test_loader, num_classes, class_names)
    """
    train_dir = Path(train_dir)
    test_dir = Path(test_dir)

    if not train_dir.exists():
        raise ValueError(f"Training directory does not exist: {train_dir}")
    if not test_dir.exists():
        raise ValueError(f"Testing directory does not exist: {test_dir}")

    # Create transforms
    train_transforms = get_transforms(img_size=img_size, augment=True)
    test_transforms = get_transforms(img_size=img_size, augment=False)

    # Load datasets
    train_data = torchvision.datasets.ImageFolder(train_dir, transform=train_transforms)
    test_data = torchvision.datasets.ImageFolder(test_dir, transform=test_transforms)

    # Create data loaders
    train_loader = torch.utils.data.DataLoader(
        train_data,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers,
    )

    test_loader = torch.utils.data.DataLoader(
        test_data,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
    )

    num_classes = len(train_data.classes)
    class_names = train_data.classes

    print(f"Loaded dataset:")
    print(f"  Training samples: {len(train_data)}")
    print(f"  Testing samples: {len(test_data)}")
    print(f"  Number of classes: {num_classes}")
    print(f"  Batch size: {batch_size}")

    return train_loader, test_loader, num_classes, class_names
