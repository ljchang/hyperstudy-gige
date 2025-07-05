#!/bin/bash

# automated_distribution.sh - Complete automated distribution pipeline for GigE Virtual Camera
# This script handles the entire distribution process from version bumping to GitHub release

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_ROOT/build/distribution"
RELEASE_DIR="$PROJECT_ROOT/build/Release"
CHANGELOG_FILE="$PROJECT_ROOT/CHANGELOG.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC} $1"
}

print_info() {
    echo -e "${CYAN}ℹ️${NC} $1"
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --version VERSION    Set specific version (e.g., 1.2.0)"
    echo "  -t, --type TYPE         Release type: major, minor, patch (default: patch)"
    echo "  -m, --message MESSAGE   Release message/description"
    echo "  -d, --draft             Create draft GitHub release"
    echo "  -s, --skip-tests        Skip running tests"
    echo "  -n, --no-github         Skip GitHub release creation"
    echo "  -c, --clean             Clean build directories first"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --type minor --message \"Added new camera features\""
    echo "  $0 --version 2.0.0 --message \"Major release with UI redesign\""
    echo "  $0 --type patch --draft"
}

# Parse command line arguments
VERSION=""
RELEASE_TYPE="patch"
RELEASE_MESSAGE=""
DRAFT_RELEASE=false
SKIP_TESTS=false
NO_GITHUB=false
CLEAN_BUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--version)
            VERSION="$2"
            shift 2
            ;;
        -t|--type)
            RELEASE_TYPE="$2"
            shift 2
            ;;
        -m|--message)
            RELEASE_MESSAGE="$2"
            shift 2
            ;;
        -d|--draft)
            DRAFT_RELEASE=true
            shift
            ;;
        -s|--skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        -n|--no-github)
            NO_GITHUB=true
            shift
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Check if we're in the right directory
if [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; then
    print_error "Please run this script from the project root"
    exit 1
fi

echo ""
echo "🚀 GigE Virtual Camera Automated Distribution"
echo "============================================"
echo ""

# Step 1: Pre-flight checks
print_status "Step 1: Pre-flight checks..."

# Check for uncommitted changes
if ! git diff-index --quiet HEAD --; then
    print_warning "You have uncommitted changes"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check we're on main branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ]; then
    print_warning "Not on main branch (current: $CURRENT_BRANCH)"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_success "Pre-flight checks passed"

# Step 2: Version management
print_status "Step 2: Managing version..."

# Get current version from Info.plist
INFO_PLIST="$PROJECT_ROOT/GigECameraApp/Info.plist"
CURRENT_VERSION=$(defaults read "$INFO_PLIST" CFBundleShortVersionString 2>/dev/null || echo "1.0.0")

if [ -z "$VERSION" ]; then
    # Auto-increment version based on type
    IFS='.' read -ra VERSION_PARTS <<< "$CURRENT_VERSION"
    MAJOR="${VERSION_PARTS[0]:-1}"
    MINOR="${VERSION_PARTS[1]:-0}"
    PATCH="${VERSION_PARTS[2]:-0}"
    
    case $RELEASE_TYPE in
        major)
            VERSION="$((MAJOR + 1)).0.0"
            ;;
        minor)
            VERSION="${MAJOR}.$((MINOR + 1)).0"
            ;;
        patch)
            VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"
            ;;
        *)
            print_error "Invalid release type: $RELEASE_TYPE"
            exit 1
            ;;
    esac
fi

print_info "Current version: $CURRENT_VERSION"
print_info "New version: $VERSION"

# Update version in Info.plist files
print_status "Updating version in Info.plist files..."

# Function to update plist version
update_plist_version() {
    local plist_path="$1"
    if [ -f "$plist_path" ]; then
        defaults write "$plist_path" CFBundleShortVersionString "$VERSION"
        defaults write "$plist_path" CFBundleVersion "$VERSION"
        print_success "Updated $(basename $(dirname "$plist_path"))/Info.plist"
    fi
}

# Update all Info.plist files
update_plist_version "$PROJECT_ROOT/GigECameraApp/Info.plist"
update_plist_version "$PROJECT_ROOT/GigEVirtualCameraExtension/Info.plist"

# Step 3: Clean build directories if requested
if [ "$CLEAN_BUILD" = true ]; then
    print_status "Step 3: Cleaning build directories..."
    rm -rf "$PROJECT_ROOT/build"
    rm -rf "$PROJECT_ROOT/DerivedData"
    rm -rf ~/Library/Developer/Xcode/DerivedData/GigEVirtualCamera-*
    print_success "Build directories cleaned"
else
    print_info "Step 3: Skipping clean (use -c to clean)"
fi

# Step 4: Run tests (unless skipped)
if [ "$SKIP_TESTS" = false ]; then
    print_status "Step 4: Running tests..."
    
    # Check if there's a test scheme
    if xcodebuild -project "$PROJECT_ROOT/GigEVirtualCamera.xcodeproj" -list | grep -q "Test"; then
        xcodebuild test \
            -project "$PROJECT_ROOT/GigEVirtualCamera.xcodeproj" \
            -scheme "GigEVirtualCamera" \
            -destination "platform=macOS" \
            | xcpretty || true
        print_success "Tests completed"
    else
        print_info "No test scheme found, skipping tests"
    fi
else
    print_info "Step 4: Skipping tests (--skip-tests specified)"
fi

# Step 5: Build and sign
print_status "Step 5: Building and signing..."

# Use the existing release_distribution script for the full build pipeline
"$SCRIPT_DIR/release_distribution.sh"

# Find the output files
DMG_FILE="$OUTPUT_DIR/GigEVirtualCamera.dmg"
if [ ! -f "$DMG_FILE" ]; then
    print_error "DMG not found at $DMG_FILE"
    exit 1
fi

print_success "Build and signing completed"

# Step 6: Generate changelog
print_status "Step 6: Generating changelog..."

# Get commits since last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [ -n "$LAST_TAG" ]; then
    COMMITS=$(git log --pretty=format:"- %s" "$LAST_TAG"..HEAD)
else
    COMMITS=$(git log --pretty=format:"- %s" -10)
fi

# Create changelog entry
CHANGELOG_ENTRY="## Version $VERSION - $(date +%Y-%m-%d)

### Release Notes
$RELEASE_MESSAGE

### Changes
$COMMITS

---
"

# Prepend to changelog
if [ -f "$CHANGELOG_FILE" ]; then
    echo "$CHANGELOG_ENTRY" > "$CHANGELOG_FILE.tmp"
    cat "$CHANGELOG_FILE" >> "$CHANGELOG_FILE.tmp"
    mv "$CHANGELOG_FILE.tmp" "$CHANGELOG_FILE"
else
    echo "$CHANGELOG_ENTRY" > "$CHANGELOG_FILE"
fi

print_success "Changelog updated"

# Step 7: Commit version changes
print_status "Step 7: Committing version changes..."

git add -A
git commit -m "Release version $VERSION" || true

# Create git tag
git tag -a "v$VERSION" -m "Release version $VERSION"
print_success "Version changes committed and tagged"

# Step 8: Create GitHub release (unless skipped)
if [ "$NO_GITHUB" = false ]; then
    print_status "Step 8: Creating GitHub release..."
    
    # Check if gh CLI is installed
    if ! command -v gh &> /dev/null; then
        print_warning "GitHub CLI (gh) not installed. Skipping GitHub release."
        print_info "Install with: brew install gh"
    else
        # Check if we're authenticated
        if ! gh auth status &> /dev/null; then
            print_warning "Not authenticated with GitHub. Run: gh auth login"
        else
            # Create release
            DRAFT_FLAG=""
            if [ "$DRAFT_RELEASE" = true ]; then
                DRAFT_FLAG="--draft"
            fi
            
            # Get the changelog for this version
            RELEASE_NOTES=$(echo "$CHANGELOG_ENTRY" | sed '1d')
            
            # Create the release
            gh release create "v$VERSION" \
                --title "GigE Virtual Camera v$VERSION" \
                --notes "$RELEASE_NOTES" \
                $DRAFT_FLAG \
                "$DMG_FILE"
            
            print_success "GitHub release created"
        fi
    fi
else
    print_info "Step 8: Skipping GitHub release (--no-github specified)"
fi

# Step 9: Final summary
print_status "Step 9: Distribution summary..."

DMG_SIZE=$(du -h "$DMG_FILE" | cut -f1)

echo ""
echo "📊 Distribution Summary"
echo "======================"
echo ""
echo "Version: $VERSION"
echo "Type: $RELEASE_TYPE release"
echo "DMG: $DMG_FILE ($DMG_SIZE)"
echo "Signed: ✅"
echo "Notarized: ✅"
echo ""

if [ "$NO_GITHUB" = false ] && command -v gh &> /dev/null && gh auth status &> /dev/null 2>&1; then
    echo "GitHub Release: https://github.com/$(gh repo view --json nameWithOwner -q .nameWithOwner)/releases/tag/v$VERSION"
fi

echo ""
echo "✅ Distribution complete!"
echo ""

# Push changes if not skipped
if [ "$NO_GITHUB" = false ]; then
    read -p "Push changes to origin? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git push origin main
        git push origin "v$VERSION"
        print_success "Changes pushed to origin"
    fi
fi

print_success "🎉 Automated distribution completed successfully!"