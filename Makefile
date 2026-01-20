.PHONY: help install generate open build clean lint format test install-ml train evaluate export sync-model

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
	@echo "  make install-ml    - Create conda environment"
	@echo "  make train         - Train ML model"
	@echo "  make evaluate      - Evaluate model on test set"
	@echo "  make export        - Export model to CoreML"
	@echo "  make sync-model    - Sync model to iOS (provide VERSION=vX.Y.Z)"
	@echo ""
	@echo "First time setup:"
	@echo "  1. make install"
	@echo "  2. cd ios && pre-commit install"
	@echo "  3. make install-ml"
	@echo "  4. make open"

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

train:
	@echo "Training model..."
	@conda run -n pacerid-ml python ml/scripts/train_model.py --config ml/configs/base.yaml

evaluate:
	@echo "Evaluating model..."
	@conda run -n pacerid-ml python ml/scripts/evaluate_model.py

export:
	@echo "Exporting model to CoreML..."
	@conda run -n pacerid-ml python ml/scripts/export_to_coreml.py

sync-model:
	@if [ -z "$(VERSION)" ]; then \
		echo "Error: VERSION not specified"; \
		echo "Usage: make sync-model VERSION=v1.0.0"; \
		exit 1; \
	fi
	@./ml/scripts/sync_model.sh $(VERSION)
