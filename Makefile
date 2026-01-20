.PHONY: generate open build clean install help lint format test warnings

# Default target
help:
	@echo "PacerID - Available Commands:"
	@echo ""
	@echo "  make install   - Install required tools (xcodegen, swiftlint, swiftformat)"
	@echo "  make generate  - Generate Xcode project from project.yml"
	@echo "  make open      - Generate and open project in Xcode"
	@echo "  make build     - Build the project for iOS Simulator"
	@echo "  make test      - Run tests"
	@echo "  make warnings  - Check for compiler warnings"
	@echo "  make lint      - Run SwiftLint"
	@echo "  make format    - Run SwiftFormat"
	@echo "  make clean     - Clean build artifacts"
	@echo ""
	@echo "First time setup:"
	@echo "  1. make install"
	@echo "  2. pre-commit install"
	@echo "  3. make open"
	@echo ""

# Install required tools
install:
	@echo "Installing required tools..."
	@which xcodegen > /dev/null || (echo "  Installing XcodeGen..." && brew install xcodegen)
	@which swiftlint > /dev/null || (echo "  Installing SwiftLint..." && brew install swiftlint)
	@which swiftformat > /dev/null || (echo "  Installing SwiftFormat..." && brew install swiftformat)
	@echo "✅ All tools installed"
	@echo ""
	@echo "Next: run 'pre-commit install' to set up git hooks"

# Generate Xcode project
generate:
	@echo "Generating Xcode project..."
	@xcodegen generate
	@echo "✅ Project generated at PacerID.xcodeproj"

# Generate and open in Xcode
open: generate
	@echo "Opening project in Xcode..."
	@open PacerID.xcodeproj

# Build for iOS Simulator
build: generate
	@echo "Building for iOS Simulator..."
	@xcodebuild -scheme PacerID \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-sdk iphonesimulator \
		build

# Run tests
test: generate
	@echo "Running tests..."
	@xcodebuild test -scheme PacerID \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-sdk iphonesimulator

# Check for compiler warnings
warnings: generate
	@echo "Checking for compiler warnings..."
	@xcodebuild -scheme PacerID \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-sdk iphonesimulator \
		build 2>&1 | grep "\.swift.*warning" && exit 1 || echo "✅ No Swift warnings found"

# Run SwiftLint
lint:
	@echo "Running SwiftLint..."
	@swiftlint lint --config .swiftlint.yml

# Run SwiftFormat
format:
	@echo "Running SwiftFormat..."
	@swiftformat --config .swiftformat .

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf DerivedData/
	@xcodebuild -scheme PacerID clean 2>/dev/null || true
	@echo "✅ Clean complete"
