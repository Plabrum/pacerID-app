"""Training callbacks for logging and checkpointing"""

import time
import datetime
import numpy as np
from collections import deque
from pathlib import Path
from ignite.engine import Events


def setup_callbacks(
    trainer,
    evaluator,
    train_loader,
    test_loader,
    output_dir: str,
    verbose: bool = True,
):
    """
    Set up training callbacks for logging and checkpointing.

    Args:
        trainer: Ignite trainer engine
        evaluator: Ignite evaluator engine
        train_loader: Training data loader
        test_loader: Testing data loader
        output_dir: Directory to save checkpoints
        verbose: Whether to print detailed progress
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    @trainer.on(Events.STARTED)
    def initialize_custom_vars(engine):
        """Initialize custom tracking variables"""
        engine.iteration_timings = deque(maxlen=100)
        engine.iteration_loss = deque(maxlen=100)

    @trainer.on(Events.ITERATION_COMPLETED)
    def log_training_loss(engine):
        """Log training progress each iteration"""
        engine.iteration_timings.append(time.time())
        engine.iteration_loss.append(engine.state.output)

        if verbose:
            seconds_per_iteration = (
                np.mean(np.gradient(engine.iteration_timings))
                if len(engine.iteration_timings) > 1
                else 0
            )
            eta = seconds_per_iteration * (
                len(train_loader) - (engine.state.iteration % len(train_loader))
            )

            print(
                f"\rEPOCH: {engine.state.epoch:03d} | "
                f"BATCH: {engine.state.iteration % len(train_loader):03d} "
                f"of {len(train_loader):03d} | "
                f"LOSS: {engine.state.output:.3f} "
                f"({np.mean(engine.iteration_loss):.3f}) | "
                f"({seconds_per_iteration:.2f} s/it; "
                f"ETA {str(datetime.timedelta(seconds=int(eta)))})",
                end=''
            )

    @trainer.on(Events.EPOCH_COMPLETED)
    def log_training_results(engine):
        """Evaluate on training set after each epoch"""
        evaluator.run(train_loader)
        metrics = evaluator.state.metrics
        acc = metrics['accuracy']
        loss = metrics['loss']

        print(f"\nEnd of epoch {engine.state.epoch:03d}")
        print(f"TRAINING   Accuracy: {acc:.3f} | Loss: {loss:.3f}")

    @trainer.on(Events.EPOCH_COMPLETED)
    def log_validation_results(engine):
        """Evaluate on test set after each epoch"""
        evaluator.run(test_loader)
        metrics = evaluator.state.metrics
        acc = metrics['accuracy']
        loss = metrics['loss']

        print(f"TESTING    Accuracy: {acc:.3f} | Loss: {loss:.3f}\n")

    @trainer.on(Events.EPOCH_COMPLETED)
    def save_checkpoint(engine):
        """Save checkpoint every epoch"""
        from .trainer import save_checkpoint as save_ckpt

        checkpoint_path = output_dir / f"checkpoint_epoch_{engine.state.epoch:03d}.pt"
        save_ckpt(
            engine.state.model if hasattr(engine.state, 'model') else trainer.state_dict(),
            engine.state.optimizer if hasattr(engine.state, 'optimizer') else None,
            engine.state.epoch,
            str(checkpoint_path)
        )

        # Also save as "latest"
        latest_path = output_dir / "checkpoint_latest.pt"
        save_ckpt(
            engine.state.model if hasattr(engine.state, 'model') else trainer.state_dict(),
            engine.state.optimizer if hasattr(engine.state, 'optimizer') else None,
            engine.state.epoch,
            str(latest_path)
        )

    print(f"Callbacks configured. Checkpoints will be saved to: {output_dir}")
