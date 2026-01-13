#!/bin/bash
# Convenience script to build, bundle, and optionally create a DMG for Krokiet on macOS
# This is the all-in-one script for the complete release process

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Krokiet macOS Build and Package Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Parse command line arguments
CREATE_DMG=false
CLEAN_BUILD=false
SKIP_TESTS=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --dmg)
            CREATE_DMG=true
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --dmg          Also create a DMG disk image for distribution"
            echo "  --clean        Clean build (removes target directory first)"
            echo "  --skip-tests   Skip running tests before building"
            echo "  --help         Show this help message"
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

cd "$PROJECT_ROOT"

# Clean build if requested
if [ "$CLEAN_BUILD" = true ]; then
    echo -e "${YELLOW}Cleaning previous build...${NC}"
    cargo clean -p krokiet
    echo ""
fi

# Run tests unless skipped
if [ "$SKIP_TESTS" = false ]; then
    echo -e "${BLUE}Running tests...${NC}"
    cargo test -p krokiet --release
    echo -e "${GREEN}✓ Tests passed${NC}"
    echo ""
fi

# Build the release binary
echo -e "${BLUE}Building Krokiet release binary...${NC}"
cargo build --release -p krokiet
echo -e "${GREEN}✓ Binary built successfully${NC}"
echo ""

# Create the icon
echo -e "${BLUE}Creating application icon...${NC}"
"$SCRIPT_DIR/create_icon.sh"
echo -e "${GREEN}✓ Icon created${NC}"
echo ""

# Create the app bundle
echo -e "${BLUE}Creating macOS application bundle...${NC}"
"$SCRIPT_DIR/create_bundle.sh"
echo -e "${GREEN}✓ Bundle created${NC}"
echo ""

# Create DMG if requested
if [ "$CREATE_DMG" = true ]; then
    echo -e "${BLUE}Creating DMG disk image...${NC}"
    # Use the simple method by default (more reliable)
    "$SCRIPT_DIR/create_dmg_simple.sh"
    echo -e "${GREEN}✓ DMG created${NC}"
    echo ""
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build and packaging complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Bundle location: $PROJECT_ROOT/target/release/Krokiet.app"

if [ "$CREATE_DMG" = true ]; then
    DMG_PATH="$PROJECT_ROOT/target/release/Krokiet-10.0.0-macOS.dmg"
    echo "DMG location: $DMG_PATH"
    echo "DMG size: $(du -h "$DMG_PATH" | awk '{print $1}')"
fi

echo ""
echo "Next steps:"
echo "  • Test the app: open target/release/Krokiet.app"
echo "  • Install locally: mv target/release/Krokiet.app /Applications/"
if [ "$CREATE_DMG" = false ]; then
    echo "  • Create DMG: ./misc/macos/create_dmg.sh"
fi
echo ""
