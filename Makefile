.PHONY: generate open build clean install help

# Default target
help:
	@echo "PacerID - Available Commands:"
	@echo ""
	@echo "  make install   - Install required tools (xcodegen, swiftlint, swiftformat)"
	@echo "  make generate  - Generate Xcode project from project.yml"
	@echo "  make open      - Generate and open project in Xcode"
	@echo "  make build     - Build the project for iOS Simulator"
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

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf DerivedData/
	@xcodebuild -scheme PacerID clean 2>/dev/null || true
	@echo "✅ Clean complete"
