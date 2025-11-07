.PHONY: generate open build clean install install-tools install-hooks format lint check lsp help

# Default target
help:
	@echo "PacemakerID - Available Commands:"
	@echo ""
	@echo "  Project Setup:"
	@echo "    make install        - Install XcodeGen via Homebrew"
	@echo "    make install-tools  - Install all development tools (xcodegen, swiftlint, swiftformat, xcode-build-server)"
	@echo "    make install-hooks  - Install git pre-commit hooks"
	@echo "    make generate       - Generate Xcode project from project.yml"
	@echo "    make open           - Generate and open project in Xcode"
	@echo ""
	@echo "  Development:"
	@echo "    make format         - Format all Swift files with SwiftFormat"
	@echo "    make lint           - Lint all Swift files with SwiftLint"
	@echo "    make check          - Run format + lint (pre-commit checks)"
	@echo "    make build          - Build the project for iOS Simulator"
	@echo "    make clean          - Clean build artifacts"
	@echo "    make lsp            - Generate LSP config for neovim (xcode-build-server)"
	@echo ""
	@echo "  make help             - Show this help message"
	@echo ""

# Install xcodegen if not already installed
install:
	@which xcodegen > /dev/null || (echo "Installing XcodeGen..." && brew install xcodegen)
	@echo "✅ XcodeGen is installed"

# Generate Xcode project
generate:
	@echo "Generating Xcode project..."
	@xcodegen generate
	@echo "✅ Project generated at PacemakerID.xcodeproj"

# Generate and open in Xcode
open: generate
	@echo "Opening project in Xcode..."
	@open PacemakerID.xcodeproj

# Generate LSP config for neovim (xcode-build-server)
lsp: generate
	@echo "Generating LSP configuration for neovim..."
	@which xcode-build-server > /dev/null || (echo "❌ xcode-build-server not installed. Install from: https://github.com/SolaWing/xcode-build-server" && exit 1)
	@xcode-build-server config -scheme PacemakerID -project PacemakerID.xcodeproj
	@echo "✅ LSP config generated at .buildServer.json"

# Build for iOS Simulator
build: generate
	@echo "Building for iOS Simulator..."
	@xcodebuild -scheme PacemakerID \
		-destination 'platform=iOS Simulator,name=iPhone 17' \
		-sdk iphonesimulator \
		build

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf build/
	@rm -rf DerivedData/
	@xcodebuild -scheme PacemakerID clean 2>/dev/null || true
	@echo "✅ Clean complete"

# Install all development tools
install-tools:
	@echo "Installing development tools..."
	@which xcodegen > /dev/null || (echo "  Installing XcodeGen..." && brew install xcodegen)
	@which swiftlint > /dev/null || (echo "  Installing SwiftLint..." && brew install swiftlint)
	@which swiftformat > /dev/null || (echo "  Installing SwiftFormat..." && brew install swiftformat)
	@which xcode-build-server > /dev/null || (echo "  Installing xcode-build-server..." && brew install xcode-build-server)
	@echo "✅ All tools installed"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Run 'make install-hooks' to install git hooks"
	@echo "  2. Run 'make lsp' to generate LSP config for neovim"

# Install git hooks
install-hooks:
	@echo "Installing git hooks..."
	@./scripts/install-hooks.sh

# Format all Swift files
format:
	@echo "Formatting Swift files..."
	@which swiftformat > /dev/null || (echo "❌ SwiftFormat not installed. Run: make install-tools" && exit 1)
	@swiftformat PacemakerID --config .swiftformat
	@echo "✅ Format complete"

# Lint all Swift files
lint:
	@echo "Linting Swift files..."
	@which swiftlint > /dev/null || (echo "❌ SwiftLint not installed. Run: make install-tools" && exit 1)
	@swiftlint lint --config .swiftlint.yml

# Run all checks (format + lint)
check: format lint
	@echo "✅ All checks passed"
