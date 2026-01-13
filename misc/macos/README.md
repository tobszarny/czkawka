# macOS Bundle Creation for Krokiet

This directory contains scripts and resources for creating a distributable macOS application bundle (.app) and disk image (.dmg) for Krokiet.

## Prerequisites

1. **Rust and Cargo** - For building the Krokiet binary
2. **librsvg** - For converting SVG icon to PNG (install with: `brew install librsvg`)
3. **Xcode Command Line Tools** - For `iconutil` and other macOS development tools (usually pre-installed)

## Quick Start

To create a complete macOS bundle with DMG:

```bash
# 1. Build the release binary
cd /Users/tomasz/RustroverProjects/czkawka
cargo build --release -p krokiet

# 2. Create the .app bundle
./misc/macos/create_bundle.sh

# 3. (Optional) Create a distributable DMG
./misc/macos/create_dmg.sh
```

## Files in This Directory

- **Info.plist** - macOS application metadata (bundle identifier, version, capabilities, etc.)
- **create_icon.sh** - Converts the SVG icon to .icns format for macOS
- **create_bundle.sh** - Creates the complete Krokiet.app bundle structure
- **create_dmg.sh** - Creates a distributable DMG disk image
- **README.md** - This file

## Detailed Steps

### 1. Building the Binary

First, ensure you have a release build of Krokiet:

```bash
cargo build --release -p krokiet
```

This will create the binary at `target/release/krokiet`.

### 2. Creating the Icon

The `create_icon.sh` script converts the SVG icon to the .icns format required by macOS:

```bash
./misc/macos/create_icon.sh
```

This script:
- Takes the SVG icon from `data/icons/com.github.qarmin.czkawka.svg`
- Generates PNG files at multiple resolutions (16x16, 32x32, 128x128, 256x256, 512x512)
- Creates @2x retina versions for each size
- Uses macOS's `iconutil` to convert to .icns format
- Outputs `krokiet.icns` in this directory

**Note:** This step is automatically run by `create_bundle.sh` if the icon doesn't exist.

### 3. Creating the App Bundle

The `create_bundle.sh` script creates a complete macOS application bundle:

```bash
./misc/macos/create_bundle.sh
```

This creates `target/release/Krokiet.app` with the following structure:

```
Krokiet.app/
├── Contents/
│   ├── Info.plist          # Application metadata
│   ├── MacOS/
│   │   └── krokiet         # The executable binary
│   └── Resources/
│       └── krokiet.icns    # Application icon
```

After creation, you can:
- Test it: `open target/release/Krokiet.app`
- Install it: `mv target/release/Krokiet.app /Applications/`

### 4. Creating a DMG for Distribution

There are two scripts available for creating DMG disk images:

#### Recommended: Simple Method (create_dmg_simple.sh)

```bash
./misc/macos/create_dmg_simple.sh
```

This is the default method used by `build_and_package.sh`. It creates a compressed DMG directly without mounting/unmounting steps, making it more reliable and faster.

#### Advanced Method (create_dmg.sh)

```bash
./misc/macos/create_dmg.sh
```

This method mounts the DMG temporarily, allowing for customization (custom backgrounds, icon positions, etc.) before finalizing. Use this if you need to customize the DMG appearance.

Both scripts create `target/release/Krokiet-10.0.0-macOS.dmg` with:
- The Krokiet.app bundle
- A symbolic link to the Applications folder for easy drag-and-drop installation
- Compressed format (UDZO) for smaller file size (~18MB vs 52MB uncompressed)

Users can then:
1. Download the DMG
2. Double-click to mount it
3. Drag Krokiet.app to the Applications folder
4. Eject the DMG

## Code Signing (Optional)

For distribution outside the App Store, you should sign your application with a Developer ID certificate:

1. Get a Developer ID certificate from Apple
2. Uncomment the signing lines in `create_bundle.sh`:
   ```bash
   codesign --force --deep --sign "Developer ID Application: Your Name" "$BUNDLE_DIR"
   ```
3. For the DMG, you may also want to sign and notarize it:
   ```bash
   codesign --force --sign "Developer ID Application: Your Name" "Krokiet-10.0.0-macOS.dmg"
   xcrun notarytool submit "Krokiet-10.0.0-macOS.dmg" --wait
   xcrun stapler staple "Krokiet-10.0.0-macOS.dmg"
   ```

## Updating Version Numbers

When releasing a new version:

1. Update `CFBundleShortVersionString` and `CFBundleVersion` in `Info.plist`
2. Update `DMG_NAME` in `create_dmg.sh` to match the new version
3. Update the version in `krokiet/Cargo.toml` if needed

## Troubleshooting

### "krokiet binary not found"
Make sure you've built the release binary first:
```bash
cargo build --release -p krokiet
```

### "rsvg-convert is not installed"
Install librsvg:
```bash
brew install librsvg
```

### "Operation not permitted" when opening the app
macOS Gatekeeper may block unsigned applications. Right-click the app and select "Open" to bypass this for testing, or properly sign the application for distribution.

### App doesn't show the correct icon
Make sure the icon was created successfully and is present at:
```
target/release/Krokiet.app/Contents/Resources/krokiet.icns
```

## Testing the Bundle

After creating the bundle, test it thoroughly:

```bash
# Open the app
open target/release/Krokiet.app

# Check if it launches correctly
# Verify the icon appears in Dock and Finder
# Test basic functionality
```

## Distribution Checklist

Before distributing the DMG:

- [ ] Test the .app bundle on a clean macOS system
- [ ] Verify the icon displays correctly
- [ ] Check that the app launches without errors
- [ ] Test on different macOS versions (if possible)
- [ ] Sign the application (for non-Gatekeeper warnings)
- [ ] Notarize the DMG (for distribution outside the App Store)
- [ ] Test the DMG installation process
- [ ] Update release notes and changelog

## License

The bundling scripts are part of the Czkawka project and follow the same GPL-3.0-only license as Krokiet.
