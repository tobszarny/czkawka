# Quick Start Guide - macOS Bundle Creation

## TL;DR

```bash
# One-command build, bundle, and package:
./misc/macos/build_and_package.sh --dmg
```

## Prerequisites

Install required tools (one-time setup):

```bash
brew install librsvg
```

## Individual Steps

If you prefer to run steps individually:

### 1. Build the Binary
```bash
cargo build --release -p krokiet
```

### 2. Create the App Bundle
```bash
./misc/macos/create_bundle.sh
```

### 3. Create DMG for Distribution
```bash
./misc/macos/create_dmg_simple.sh  # Recommended (simpler, faster)
# OR
./misc/macos/create_dmg.sh         # Advanced (allows customization)
```

## Output Files

- **App Bundle**: `target/release/Krokiet.app`
- **DMG Image**: `target/release/Krokiet-10.0.0-macOS.dmg`

## Testing

```bash
# Test the app bundle
open target/release/Krokiet.app

# Install to Applications
mv target/release/Krokiet.app /Applications/
```

## Command Options

The `build_and_package.sh` script supports these options:

- `--dmg` - Also create a DMG disk image
- `--clean` - Clean build (removes previous build artifacts)
- `--skip-tests` - Skip running tests before building
- `--help` - Show help message

## Examples

```bash
# Build everything from scratch with DMG
./misc/macos/build_and_package.sh --clean --dmg

# Quick rebuild without tests
./misc/macos/build_and_package.sh --skip-tests

# Just create the bundle (if binary already exists)
./misc/macos/create_bundle.sh
```

## Troubleshooting

### "rsvg-convert is not installed"
```bash
brew install librsvg
```

### "krokiet binary not found"
```bash
cargo build --release -p krokiet
```

### App doesn't open
macOS Gatekeeper may block unsigned apps. Right-click → Open, or sign the app.

## Distribution Checklist

Before releasing:
- [ ] Update version in `Info.plist`
- [ ] Update version in `create_dmg.sh` (DMG_NAME)
- [ ] Test on clean macOS system
- [ ] Sign the application (optional but recommended)
- [ ] Notarize the DMG (for distribution)

## File Locations

- **Scripts**: `misc/macos/`
- **Icon source**: `data/icons/com.github.qarmin.czkawka.svg`
- **Bundle metadata**: `misc/macos/Info.plist`
- **Detailed docs**: `misc/macos/README.md`

## Need Help?

See the [full README](README.md) for detailed documentation.
