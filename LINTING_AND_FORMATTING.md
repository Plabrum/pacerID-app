# Linting and Formatting Guide

PacemakerID uses automated linting and formatting with **minimal configuration** - we trust the defaults!

## Philosophy

We use **mostly default settings** from SwiftLint and SwiftFormat. These tools have sensible defaults created by the Swift community. Less configuration means:
- Less to learn and remember
- Fewer arguments about style
- Easier onboarding for new developers
- Well-tested, community-approved conventions

## Tools

- **SwiftLint**: Catches common mistakes and enforces Swift conventions
- **SwiftFormat**: Automatically formats code consistently
- **Pre-commit Hook**: Runs checks automatically before commits

## Quick Setup

```bash
# 1. Install tools
make install-tools

# 2. Install git hooks
make install-hooks

# Done! That's it.
```

## Daily Usage

### Automatic (Recommended)

Just commit normally - the pre-commit hook handles everything:

```bash
git add .
git commit -m "Add feature"
# Hook automatically formats and lints
```

### Manual

```bash
# Format all Swift files
make format

# Lint all Swift files
make lint

# Both at once
make check
```

## Configuration

### SwiftLint (`.swiftlint.yml`)

**27 lines total** - mostly defaults!

```yaml
# Only disable the annoying ones
disabled_rules:
  - line_length     # Let SwiftFormat handle this
  - todo            # TODOs are fine
  - trailing_comma  # Personal preference

# Allow common short names (i, id, x, y)
identifier_name:
  excluded: [i, id, x, y, z]
```

**That's it!** Everything else uses SwiftLint's excellent defaults.

### SwiftFormat (`.swiftformat`)

**19 lines total** - mostly defaults!

```
--indent 4
--maxwidth 120
--self init-only
--stripunusedargs always
```

**That's it!** Everything else uses SwiftFormat's sensible defaults.

## What Gets Checked?

### SwiftLint (Default Rules)

Common issues caught by defaults:
- ✅ Force unwrapping (`!`)
- ✅ Unused variables
- ✅ Complex functions (too many lines)
- ✅ Deeply nested code
- ✅ Inconsistent naming
- ✅ Missing documentation in public APIs
- ✅ And ~60 other rules

[See all default rules](https://github.com/realm/SwiftLint/blob/main/Source/SwiftLintBuiltInRules/Rules/RuleConfigurations)

### SwiftFormat (Default Rules)

Automatic formatting:
- ✅ Consistent indentation
- ✅ Proper spacing
- ✅ Import sorting
- ✅ Brace placement
- ✅ Line wrapping
- ✅ And ~50 other formatting rules

[See all rules](https://github.com/nicklockwood/SwiftFormat/blob/main/Rules.md)

## Integration

### 1. Pre-commit Hook

Runs automatically on `git commit`:
1. Formats staged Swift files
2. Lints staged Swift files
3. Blocks commit if errors found

### 2. Xcode Build

SwiftLint runs during Xcode builds:
- Warnings appear inline
- Click to jump to issues
- Doesn't block compilation

### 3. Manual Commands

Run anytime via `make`:
- `make format` - Format files
- `make lint` - Lint files
- `make check` - Both

## Customization

### Want Different Rules?

Edit the config files, but **keep it minimal**:

```yaml
# .swiftlint.yml
disabled_rules:
  - your_rule_here
```

```
# .swiftformat
--your-option value
```

Then discuss with the team before committing changes!

### Bypass Hook (Emergencies Only)

```bash
git commit --no-verify
```

## Common Questions

**Q: Why so few rules?**
A: Defaults are battle-tested by thousands of projects. Less config = less maintenance.

**Q: Can I customize more?**
A: Yes, but ask: is this rule worth the added complexity? Defaults are usually fine.

**Q: What if I disagree with a default?**
A: Try it for a week. Most defaults exist for good reasons.

**Q: How do I learn what rules are active?**
A: Run `swiftlint rules` to see all active rules and their descriptions.

**Q: Does this slow down commits?**
A: Formatting takes ~0.01s per file. Linting takes ~0.1s per file. Barely noticeable.

## Troubleshooting

### Tools Not Installed

```bash
make install-tools
```

### Hook Not Running

```bash
make install-hooks
```

### Linting Errors

Fix them or disable the specific rule if it's not helpful:

```yaml
# .swiftlint.yml
disabled_rules:
  - specific_rule_name
```

## Resources

- **SwiftLint**: https://github.com/realm/SwiftLint
- **SwiftFormat**: https://github.com/nicklockwood/SwiftFormat
- **Swift API Guidelines**: https://swift.org/documentation/api-design-guidelines/

## Summary

**Keep it simple:**
- ✅ Install tools: `make install-tools`
- ✅ Install hooks: `make install-hooks`
- ✅ Commit normally
- ✅ Trust the defaults

That's it! The tools handle the rest.
