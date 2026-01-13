#!/bin/bash
# Simplified script to create a distributable DMG file for Krokiet
# This version doesn't require mounting/unmounting and is more reliable

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/target/release"
BUNDLE_NAME="Krokiet.app"
BUNDLE_DIR="$BUILD_DIR/$BUNDLE_NAME"
DMG_NAME="Krokiet-10.0.0-macOS.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
VOLUME_NAME="Krokiet"

echo "Creating DMG for Krokiet (simple method)..."

# Check if the bundle exists
if [ ! -d "$BUNDLE_DIR" ]; then
    echo "Error: Bundle not found at $BUNDLE_DIR"
    echo "Please run create_bundle.sh first"
    exit 1
fi

# Remove any existing DMG files
rm -f "$DMG_PATH"

# Create a temporary directory for DMG contents
TMP_DIR="$BUILD_DIR/dmg_tmp"
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

# Copy the bundle to the temporary directory
echo "Copying bundle to temporary directory..."
cp -R "$BUNDLE_DIR" "$TMP_DIR/"

# Create a symbolic link to Applications folder
echo "Creating Applications symlink..."
ln -s /Applications "$TMP_DIR/Applications"

# Create DMG directly without mounting (simpler and more reliable)
echo "Creating compressed DMG..."
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$TMP_DIR" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$DMG_PATH"

# Clean up
echo "Cleaning up temporary files..."
rm -rf "$TMP_DIR"

echo ""
echo "✅ DMG created successfully!"
echo "Location: $DMG_PATH"
echo "Size: $(du -h "$DMG_PATH" | awk '{print $1}')"
echo ""
echo "You can now distribute this DMG file to users."
echo ""
