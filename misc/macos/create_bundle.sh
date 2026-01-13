#!/bin/bash
# Script to create a macOS .app bundle for Krokiet
# This creates a distributable Krokiet.app package

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/target/release"
BUNDLE_NAME="Krokiet.app"
BUNDLE_DIR="$BUILD_DIR/$BUNDLE_NAME"

echo "Creating macOS bundle for Krokiet..."

# Check if the binary exists
if [ ! -f "$BUILD_DIR/krokiet" ]; then
    echo "Error: krokiet binary not found at $BUILD_DIR/krokiet"
    echo "Please build the project first with: cargo build --release -p krokiet"
    exit 1
fi

# Create bundle directory structure
echo "Creating bundle directory structure..."
rm -rf "$BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR/Contents/MacOS"
mkdir -p "$BUNDLE_DIR/Contents/Resources"

# Copy the binary
echo "Copying binary..."
cp "$BUILD_DIR/krokiet" "$BUNDLE_DIR/Contents/MacOS/krokiet"
chmod +x "$BUNDLE_DIR/Contents/MacOS/krokiet"

# Copy Info.plist
echo "Copying Info.plist..."
cp "$SCRIPT_DIR/Info.plist" "$BUNDLE_DIR/Contents/Info.plist"

# Create or copy icon
if [ -f "$SCRIPT_DIR/krokiet.icns" ]; then
    echo "Copying existing icon..."
    cp "$SCRIPT_DIR/krokiet.icns" "$BUNDLE_DIR/Contents/Resources/krokiet.icns"
else
    echo "Icon file not found. Creating icon from SVG..."
    bash "$SCRIPT_DIR/create_icon.sh"
    if [ -f "$SCRIPT_DIR/krokiet.icns" ]; then
        cp "$SCRIPT_DIR/krokiet.icns" "$BUNDLE_DIR/Contents/Resources/krokiet.icns"
    else
        echo "Warning: Could not create icon. Bundle will be created without an icon."
    fi
fi

# Optional: Sign the bundle (if you have a developer certificate)
# Uncomment the following lines if you want to sign the app
# echo "Signing the bundle..."
# codesign --force --deep --sign "Developer ID Application: Your Name" "$BUNDLE_DIR"

echo ""
echo "✅ Bundle created successfully!"
echo "Location: $BUNDLE_DIR"
echo ""
echo "You can now:"
echo "  1. Test it: open $BUNDLE_DIR"
echo "  2. Move it to Applications: mv \"$BUNDLE_DIR\" /Applications/"
echo "  3. Create a DMG for distribution (see create_dmg.sh)"
echo ""
