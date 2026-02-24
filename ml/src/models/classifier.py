"""Pacemaker classifier model architectures"""

import torch
import torch.nn as nn
from torchvision import models
from typing import Literal


def create_model(
    architecture: Literal["densenet121", "resnet50", "mobilenet_v3_small"] = "densenet121",
    num_classes: int = 45,
    pretrained: bool = True,
    device: str = "cuda",
) -> nn.Module:
    """
    Create a pacemaker classifier model with transfer learning.

    Loads a pre-trained model from torchvision and replaces the final
    classification layer to match the number of pacemaker classes.

    Args:
        architecture: Model architecture to use
        num_classes: Number of output classes (pacemaker models)
        pretrained: Whether to use ImageNet pre-trained weights
        device: Device to move model to ('cuda' or 'cpu')

    Returns:
        PyTorch model ready for training
    """
    print(f"Creating {architecture} model with {num_classes} classes...")

    if architecture == "densenet121":
        model = models.densenet121(pretrained=pretrained)
        # Replace final classifier layer
        num_features = model.classifier.in_features
        model.classifier = nn.Linear(num_features, num_classes)

    elif architecture == "resnet50":
        model = models.resnet50(pretrained=pretrained)
        # Replace final fc layer
        num_features = model.fc.in_features
        model.fc = nn.Linear(num_features, num_classes)

    elif architecture == "mobilenet_v3_small":
        model = models.mobilenet_v3_small(pretrained=pretrained)
        # Replace final classifier layer
        num_features = model.classifier[3].in_features
        model.classifier[3] = nn.Linear(num_features, num_classes)

    else:
        raise ValueError(f"Unsupported architecture: {architecture}")

    # Move to device
    model = model.to(device)

    if pretrained:
        print(f"  Loaded pre-trained ImageNet weights")
    print(f"  Replaced final layer: {num_features} -> {num_classes} classes")
    print(f"  Model moved to: {device}")

    return model


def count_parameters(model: nn.Module) -> dict:
    """
    Count total and trainable parameters in a model.

    Args:
        model: PyTorch model

    Returns:
        Dictionary with parameter counts
    """
    total_params = sum(p.numel() for p in model.parameters())
    trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)

    return {
        "total": total_params,
        "trainable": trainable_params,
        "frozen": total_params - trainable_params,
    }
