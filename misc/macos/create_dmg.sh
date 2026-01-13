#!/bin/bash
# Script to create a distributable DMG file for Krokiet
# This creates a disk image that users can download and install from

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$PROJECT_ROOT/target/release"
BUNDLE_NAME="Krokiet.app"
BUNDLE_DIR="$BUILD_DIR/$BUNDLE_NAME"
DMG_NAME="Krokiet-10.0.0-macOS.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
VOLUME_NAME="Krokiet"
TMP_DMG="$BUILD_DIR/tmp.dmg"

echo "Creating DMG for Krokiet..."

# Check if the bundle exists
if [ ! -d "$BUNDLE_DIR" ]; then
    echo "Error: Bundle not found at $BUNDLE_DIR"
    echo "Please run create_bundle.sh first"
    exit 1
fi

# Remove any existing DMG files
rm -f "$DMG_PATH" "$TMP_DMG"

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

# Calculate size needed for DMG (in MB, with some overhead)
SIZE=$(du -sm "$TMP_DIR" | awk '{print $1}')
SIZE=$((SIZE + 50))  # Add 50MB overhead

echo "Creating DMG with size: ${SIZE}MB..."

# Create DMG
hdiutil create -srcfolder "$TMP_DIR" \
    -volname "$VOLUME_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size ${SIZE}m \
    "$TMP_DMG"

# Mount the DMG
echo "Mounting DMG for customization..."
MOUNT_OUTPUT=$(hdiutil attach -readwrite -noverify -noautoopen "$TMP_DMG" 2>&1)
MOUNT_DIR=$(echo "$MOUNT_OUTPUT" | grep -E '/Volumes/' | sed 's/^.*\(\/Volumes\/.*\)$/\1/')

# Fallback: if parsing failed, try to find the volume by name
if [ -z "$MOUNT_DIR" ]; then
    MOUNT_DIR="/Volumes/$VOLUME_NAME"
fi

# Verify the mount point exists
if [ ! -d "$MOUNT_DIR" ]; then
    echo "Error: Failed to mount DMG"
    echo "Mount output: $MOUNT_OUTPUT"
    rm -f "$TMP_DMG"
    rm -rf "$TMP_DIR"
    exit 1
fi

echo "Mounted at: $MOUNT_DIR"

# Set background and icon positions (optional, requires AppleScript)
# You can customize the DMG appearance here using AppleScript
# For now, we'll keep it simple

# Give the DMG time to sync
sleep 2

# Unmount the DMG
echo "Unmounting DMG..."
if ! hdiutil detach "$MOUNT_DIR" 2>/dev/null; then
    # Try force unmount if regular unmount fails
    echo "Regular unmount failed, trying force unmount..."
    hdiutil detach "$MOUNT_DIR" -force || {
        echo "Warning: Failed to unmount DMG. Continuing anyway..."
    }
fi

# Convert to read-only compressed DMG
echo "Converting to compressed DMG..."
hdiutil convert "$TMP_DMG" -format UDZO -o "$DMG_PATH"

# Clean up
echo "Cleaning up temporary files..."
rm -f "$TMP_DMG"
rm -rf "$TMP_DIR"

echo ""
echo "✅ DMG created successfully!"
echo "Location: $DMG_PATH"
echo "Size: $(du -h "$DMG_PATH" | awk '{print $1}')"
echo ""
echo "You can now distribute this DMG file to users."
echo ""
