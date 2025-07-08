#!/bin/bash

# distribute.sh - Simple wrapper for complete distribution build
# This script runs the entire distribution pipeline with proper signing and notarization

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo -e "${BLUE}🚀 GigE Virtual Camera Distribution Builder${NC}"
echo "=========================================="
echo ""
echo "This script will:"
echo "1. Build the app with Release configuration"
echo "2. Sign with Developer ID certificates"
echo "3. Fix entitlements for distribution"
echo "4. Notarize the app"
echo "5. Create a DMG"
echo "6. Notarize the DMG"
echo "7. Prepare for distribution"
echo ""
echo -e "${GREEN}Press Enter to continue or Ctrl+C to cancel...${NC}"
read

# Run the release distribution script
"$SCRIPT_DIR/release_distribution.sh"

echo ""
echo -e "${GREEN}✅ Distribution build complete!${NC}"
echo ""
echo "Your notarized DMG is ready at:"
echo "  build/distribution/GigEVirtualCamera.dmg"
echo ""
echo "This DMG can be distributed to users and will install without any Gatekeeper warnings."
echo ""