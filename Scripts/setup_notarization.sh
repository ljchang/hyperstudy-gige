#!/bin/bash

# setup_notarization.sh - Interactive setup for notarization credentials

set -e

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}     Notarization Credentials Setup${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if already configured
if security find-generic-password -s "com.apple.gke.notary.tool" -a "GigE-Notarization" &> /dev/null; then
    echo -e "${YELLOW}⚠️  Credentials already exist for profile 'GigE-Notarization'${NC}"
    echo ""
    echo "Do you want to update them? (y/n)"
    read -r update_response
    if [[ "$update_response" != "y" ]]; then
        echo "Setup cancelled."
        exit 0
    fi
fi

echo "This script will help you set up notarization credentials."
echo ""
echo "You'll need:"
echo "1. Your Apple ID (email) associated with your developer account"
echo "2. An app-specific password (NOT your Apple ID password)"
echo ""
echo -e "${YELLOW}To create an app-specific password:${NC}"
echo "1. Go to https://appleid.apple.com/account/manage"
echo "2. Sign in with your Apple ID"
echo "3. Under 'Security', find 'App-Specific Passwords'"
echo "4. Click 'Generate Password...'"
echo "5. Enter a label like 'GigE Camera Notarization'"
echo "6. Copy the generated password"
echo ""
echo "Press Enter when you have your app-specific password ready..."
read -r

# Get Apple ID
echo ""
echo "Enter your Apple ID (email):"
read -r APPLE_ID

# Validate email format
if ! [[ "$APPLE_ID" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo -e "${YELLOW}Warning: This doesn't look like a valid email address${NC}"
    echo "Continue anyway? (y/n)"
    read -r continue_response
    if [[ "$continue_response" != "y" ]]; then
        exit 1
    fi
fi

# Get app-specific password
echo ""
echo "Enter your app-specific password:"
echo "(It will be hidden as you type)"
read -rs APP_PASSWORD

# Confirm team ID
echo ""
echo ""
echo "Your Team ID is: S368GH6KF7"
echo "Is this correct? (y/n)"
read -r team_response

if [[ "$team_response" != "y" ]]; then
    echo "Enter your Team ID:"
    read -r TEAM_ID
else
    TEAM_ID="${APPLE_TEAM_ID:-S368GH6KF7}"
fi

# Store credentials
echo ""
echo -e "${BLUE}Storing credentials...${NC}"

if xcrun notarytool store-credentials "GigE-Notarization" \
    --apple-id "$APPLE_ID" \
    --team-id "$TEAM_ID" \
    --password "$APP_PASSWORD" 2>&1; then
    
    echo ""
    echo -e "${GREEN}✅ Success! Credentials stored in keychain${NC}"
    echo ""
    echo "You can now run the notarization script:"
    echo "  ./Scripts/notarize.sh"
    echo ""
    
    # Test the credentials
    echo "Would you like to test the credentials? (y/n)"
    read -r test_response
    
    if [[ "$test_response" == "y" ]]; then
        echo ""
        echo "Testing credentials..."
        if xcrun notarytool history --keychain-profile "GigE-Notarization" 2>&1 | head -5; then
            echo ""
            echo -e "${GREEN}✅ Credentials are working!${NC}"
        else
            echo ""
            echo -e "${YELLOW}⚠️  Couldn't verify credentials. They may still work for submission.${NC}"
        fi
    fi
else
    echo ""
    echo -e "${YELLOW}Failed to store credentials. Please check your Apple ID and password.${NC}"
    echo "Make sure you're using an app-specific password, not your Apple ID password."
    exit 1
fi