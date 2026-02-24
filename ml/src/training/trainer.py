"""Training setup using PyTorch Ignite"""

import torch
from ignite.engine import create_supervised_trainer, create_supervised_evaluator
from ignite.metrics import Accuracy, Loss, Precision


def create_trainer(
    model: torch.nn.Module,
    optimizer: torch.optim.Optimizer,
    loss_fn: torch.nn.Module,
    device: str = "cuda",
):
    """
    Create PyTorch Ignite trainer and evaluator.

    Args:
        model: The neural network model
        optimizer: Optimizer for training
        loss_fn: Loss function (e.g., CrossEntropyLoss)
        device: Device to run on ('cuda' or 'cpu')

    Returns:
        Tuple of (trainer, evaluator)
    """
    trainer = create_supervised_trainer(
        model,
        optimizer,
        loss_fn,
        device=device
    )

    evaluator = create_supervised_evaluator(
        model,
        metrics={
            'accuracy': Accuracy(),
            'loss': Loss(loss_fn),
            'precision': Precision(),
        },
        device=device
    )

    return trainer, evaluator


def save_checkpoint(model: torch.nn.Module, optimizer: torch.optim.Optimizer, epoch: int, path: str):
    """
    Save model checkpoint.

    Args:
        model: The model to save
        optimizer: The optimizer state to save
        epoch: Current epoch number
        path: Path to save checkpoint
    """
    torch.save({
        'epoch': epoch,
        'model_state_dict': model.state_dict(),
        'optimizer_state_dict': optimizer.state_dict(),
    }, path)
    print(f"Checkpoint saved to {path}")


def load_checkpoint(model: torch.nn.Module, optimizer: torch.optim.Optimizer, path: str) -> int:
    """
    Load model checkpoint.

    Args:
        model: The model to load weights into
        optimizer: The optimizer to load state into
        path: Path to checkpoint file

    Returns:
        Epoch number from checkpoint
    """
    checkpoint = torch.load(path)
    model.load_state_dict(checkpoint['model_state_dict'])
    optimizer.load_state_dict(checkpoint['optimizer_state_dict'])
    epoch = checkpoint['epoch']
    print(f"Checkpoint loaded from {path} (epoch {epoch})")
    return epoch
