.PHONY: help install generate open build clean lint format test install-ml download-data train export sync-model aws-launch aws-status aws-upload aws-ssh aws-download aws-terminate

# Default target
help:
	@echo "PacerID - iOS App + ML Training"
	@echo ""
	@echo "iOS Commands:"
	@echo "  make install   - Install iOS tools (xcodegen, swiftlint, swiftformat)"
	@echo "  make generate  - Generate Xcode project from project.yml"
	@echo "  make open      - Generate and open project in Xcode"
	@echo "  make build     - Build iOS app for Simulator"
	@echo "  make test      - Run iOS tests"
	@echo "  make lint      - Run SwiftLint"
	@echo "  make format    - Run SwiftFormat"
	@echo "  make clean     - Clean build artifacts"
	@echo ""
	@echo "ML Commands:"
	@echo "  make install-ml              - Create conda environment"
	@echo "  make download-data           - Download training data from Kaggle"
	@echo "  make train                   - Train model (requires conda activate pacerid-ml)"
	@echo "  make export                  - Export trained model to CoreML"
	@echo "  make sync-model              - Copy exported model to ml/models/ for iOS"
	@echo ""
	@echo "AWS GPU Training (see ml/AWS_TRAINING.md for details):"
	@echo "  make aws-launch              - Launch EC2 on-demand instance (~\$$0.53/hr)"
	@echo "  make aws-status              - Check instance status and cost"
	@echo "  make aws-upload              - Upload code to instance"
	@echo "  make aws-ssh                 - SSH into instance"
	@echo "  make aws-download            - Download training outputs"
	@echo "  make aws-terminate           - Terminate instance (IMPORTANT!)"
	@echo ""
	@echo "First time setup (iOS):"
	@echo "  1. make install"
	@echo "  2. cd ios && pre-commit install"
	@echo "  3. make open"
	@echo ""
	@echo "First time setup (ML):"
	@echo "  1. make install-ml"
	@echo "  2. conda activate pacerid-ml"
	@echo "  3. Setup Kaggle API credentials (see ml/README.md)"
	@echo "  4. make download-data"
	@echo "  5. make train"

# ============================================================
# iOS Commands
# ============================================================

install:
	@echo "Installing iOS tools..."
	@which xcodegen > /dev/null || (echo "  Installing XcodeGen..." && brew install xcodegen)
	@which swiftlint > /dev/null || (echo "  Installing SwiftLint..." && brew install swiftlint)
	@which swiftformat > /dev/null || (echo "  Installing SwiftFormat..." && brew install swiftformat)
	@echo "✅ iOS tools installed"

generate:
	@echo "Generating Xcode project..."
	@cd ios && xcodegen generate
	@echo "✅ Project generated at ios/PacerID.xcodeproj"

open: generate
	@echo "Opening project in Xcode..."
	@open ios/PacerID.xcodeproj

build: generate
	@echo "Building for iOS Simulator..."
	@cd ios && xcodebuild -scheme PacerID \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-sdk iphonesimulator \
		build

test: generate
	@echo "Running iOS tests..."
	@cd ios && xcodebuild test -scheme PacerID \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-sdk iphonesimulator

lint:
	@echo "Running SwiftLint..."
	@cd ios && swiftlint

format:
	@echo "Running SwiftFormat..."
	@cd ios && swiftformat .

clean:
	@echo "Cleaning build artifacts..."
	@cd ios && rm -rf DerivedData build
	@rm -rf ios/PacerID.xcodeproj
	@echo "✅ Clean complete"

# ============================================================
# ML Commands
# ============================================================

install-ml:
	@echo "Creating conda environment..."
	@cd ml && conda env create -f environment.yml
	@echo "✅ Conda environment created"
	@echo "Activate with: conda activate pacerid-ml"

download-data:
	@echo "Downloading training data from Kaggle..."
	@cd ml && python scripts/download_data.py --config configs/base.yaml

train:
	@echo "Training pacemaker classifier..."
	@cd ml && python scripts/train.py --config configs/base.yaml

export:
	@echo "Exporting model to CoreML..."
	@cd ml && uv run scripts/export.py --checkpoint output/checkpoint_latest.pt --config configs/base.yaml

sync-model:
	@echo "Syncing model to iOS..."
	@cd ml && bash ./scripts/sync_model.sh
	@echo "✅ Model synced. Run 'make build' to rebuild iOS app with new model"

# ============================================================
# AWS GPU Training Commands
# ============================================================

aws-launch:
	@echo "Launching AWS EC2 spot instance..."
	@cd ml && ./scripts/aws_launch.sh

aws-status:
	@cd ml && ./scripts/aws_status.sh

aws-upload:
	@echo "Uploading code to AWS instance..."
	@cd ml && ./scripts/aws_upload.sh

aws-ssh:
	@cd ml && ./scripts/aws_ssh.sh

aws-download:
	@echo "Downloading training outputs from AWS..."
	@cd ml && ./scripts/aws_download.sh

aws-terminate:
	@cd ml && ./scripts/aws_terminate.sh
