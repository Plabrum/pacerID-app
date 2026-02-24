#!/bin/bash
# Sync trained model to ml/models/ for iOS integration
#
# Usage: ./scripts/sync_model.sh

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ML_DIR="$(dirname "$SCRIPT_DIR")"
MODEL_SRC="$ML_DIR/output/PacerIDClassifier.mlpackage"
MODEL_DEST="$ML_DIR/models/PacerIDClassifier.mlpackage"

echo "========================================"
echo "Syncing Model to iOS"
echo "========================================"
echo ""

if [ ! -e "$MODEL_SRC" ]; then
    echo "ERROR: Model file not found: $MODEL_SRC"
    echo "Run 'make export' first to generate the CoreML model (outputs PacerIDClassifier.mlpackage)"
    exit 1
fi

mkdir -p "$ML_DIR/models"
rm -rf "$MODEL_DEST"
cp -r "$MODEL_SRC" "$MODEL_DEST"

echo "✅ Model synced to $MODEL_DEST"
echo "Commit ml/models/PacerIDClassifier.mlpackage to update the app."
