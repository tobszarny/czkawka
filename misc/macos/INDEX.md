# macOS Bundle Files - Index

This directory contains everything needed to create professional macOS application bundles for Krokiet.

## 📋 Quick Navigation

| File | Purpose | When to Use |
|------|---------|-------------|
| **QUICK_START.md** | Quick reference guide | Start here for TL;DR |
| **README.md** | Comprehensive documentation | Detailed instructions |
| **SUMMARY.md** | Implementation overview | See what was built |
| **INDEX.md** | This file | Navigation and overview |

## 🚀 Getting Started

### First Time Setup
```bash
# Install dependencies
brew install librsvg
```

### Create Bundle
```bash
# One command to build everything
./misc/macos/build_and_package.sh --dmg
```

## 📁 Files Overview

### Configuration
- **Info.plist** - App bundle metadata (version, identifier, capabilities)
- **.gitignore** - Excludes generated files from version control

### Scripts
- **build_and_package.sh** ⭐ - All-in-one build script (recommended)
- **create_icon.sh** - Convert SVG to .icns icon format
- **create_bundle.sh** - Create .app bundle structure
- **create_dmg_simple.sh** ⭐ - Create DMG disk image (simple, recommended)
- **create_dmg.sh** - Create DMG with customization support (advanced)

### Documentation
- **QUICK_START.md** - Quick reference (recommended starting point)
- **README.md** - Complete documentation
- **SUMMARY.md** - Implementation details and results
- **DMG_FIX.md** - Details about DMG creation issue and fix
- **INDEX.md** - This navigation file

### Templates
- **github-actions-example.yml** - CI/CD workflow template for GitHub Actions

### Generated Files (not in git)
- **krokiet.icns** - Generated icon (123 KB)
- **krokiet.iconset/** - Temporary directory during icon creation

## 🎯 Common Tasks

### Build and Test Locally
```bash
./misc/macos/build_and_package.sh
open target/release/Krokiet.app
```

### Create Distribution Package
```bash
./misc/macos/build_and_package.sh --dmg
# Output: target/release/Krokiet-10.0.0-macOS.dmg
```

### Clean Build from Scratch
```bash
./misc/macos/build_and_package.sh --clean --dmg
```

### Update Icon Only
```bash
./misc/macos/create_icon.sh
./misc/macos/create_bundle.sh
```

## 📦 Output Locations

After running the scripts:
- **App Bundle**: `target/release/Krokiet.app`
- **DMG Image**: `target/release/Krokiet-10.0.0-macOS.dmg`
- **Icon File**: `misc/macos/krokiet.icns`

## 🔧 Script Options

The main `build_and_package.sh` script supports:
- `--dmg` - Also create DMG for distribution
- `--clean` - Clean build (remove previous artifacts)
- `--skip-tests` - Skip running tests before building
- `--help` - Show all options

## 📚 Documentation Map

**Just want to build?** → QUICK_START.md  
**Need details?** → README.md  
**Want to understand what was done?** → SUMMARY.md  
**Setting up CI/CD?** → github-actions-example.yml  
**Lost?** → You're reading INDEX.md (this file)

## ⚡ Quick Commands Reference

```bash
# Build everything with DMG
./misc/macos/build_and_package.sh --dmg

# Test the app
open target/release/Krokiet.app

# Install to Applications
mv target/release/Krokiet.app /Applications/

# Verify bundle info
mdls target/release/Krokiet.app

# Check binary architecture
file target/release/Krokiet.app/Contents/MacOS/krokiet
```

## 🐛 Troubleshooting Quick Fixes

**"rsvg-convert not found"**
```bash
brew install librsvg
```

**"krokiet binary not found"**
```bash
cargo build --release -p krokiet
```

**"Can't open app" (Gatekeeper)**
```bash
# Right-click → Open (first time only)
# Or remove quarantine:
xattr -cr target/release/Krokiet.app
```

## 🔄 Updating for New Version

When releasing a new version:

1. Update version in `Info.plist` (CFBundleShortVersionString and CFBundleVersion)
2. Update DMG filename in `create_dmg.sh` (DMG_NAME variable)
3. Update version in `krokiet/Cargo.toml`
4. Run `./misc/macos/build_and_package.sh --dmg`

## 🎓 Next Steps

1. **Test locally**: Run `./misc/macos/build_and_package.sh` and test the app
2. **Create DMG**: Add `--dmg` flag for distribution package
3. **Sign the app**: See README.md for code signing instructions
4. **Automate**: Use github-actions-example.yml for CI/CD
5. **Distribute**: Upload DMG to GitHub releases or website

## 📞 Support

- **Detailed docs**: See README.md in this directory
- **Project issues**: https://github.com/qarmin/czkawka/issues
- **Build problems**: Check README.md troubleshooting section

## 📄 License

GPL-3.0-only (same as Krokiet)

---

**Ready to build?** Start with: `./misc/macos/build_and_package.sh --dmg`
