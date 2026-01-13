#!/bin/bash
# Script to convert SVG icon to macOS .icns format
# Requires: rsvg-convert (from librsvg) and iconutil (built into macOS)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SVG_ICON="$PROJECT_ROOT/data/icons/com.github.qarmin.czkawka.svg"
ICONSET_DIR="$SCRIPT_DIR/krokiet.iconset"

echo "Creating macOS icon from SVG..."

# Check if rsvg-convert is available
if ! command -v rsvg-convert &> /dev/null; then
    echo "Error: rsvg-convert is not installed."
    echo "Please install it with: brew install librsvg"
    exit 1
fi

# Create iconset directory
mkdir -p "$ICONSET_DIR"

# Generate PNG files at various sizes for the iconset
declare -a sizes=(16 32 128 256 512)

for size in "${sizes[@]}"; do
    echo "Generating ${size}x${size} icon..."
    rsvg-convert -w $size -h $size "$SVG_ICON" > "$ICONSET_DIR/icon_${size}x${size}.png"
    
    # Also create @2x versions (double resolution)
    double_size=$((size * 2))
    echo "Generating ${size}x${size}@2x icon..."
    rsvg-convert -w $double_size -h $double_size "$SVG_ICON" > "$ICONSET_DIR/icon_${size}x${size}@2x.png"
done

# Convert iconset to icns
echo "Converting iconset to .icns..."
iconutil -c icns "$ICONSET_DIR" -o "$SCRIPT_DIR/krokiet.icns"

# Clean up iconset directory
rm -rf "$ICONSET_DIR"

echo "Icon created successfully: $SCRIPT_DIR/krokiet.icns"
