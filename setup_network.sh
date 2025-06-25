#!/bin/bash
# Setup network for GigE camera access

echo "Setting up network for GigE camera..."
echo "This script will add a secondary IP address to access the camera at 169.254.90.244"
echo ""
echo "You'll need to enter your password for sudo access."
echo ""

# Add alias IP to en0
echo "Adding IP 169.254.1.1 to interface en0..."
sudo ifconfig en0 alias 169.254.1.1 netmask 255.255.0.0

# Verify it was added
echo ""
echo "Checking network configuration..."
ifconfig en0 | grep 169.254

# Test connectivity
echo ""
echo "Testing connection to camera at 169.254.90.244..."
ping -c 2 -t 2 169.254.90.244

# Check with arv-tool
echo ""
echo "Checking for GigE cameras..."
arv-tool-0.8

echo ""
echo "Done! If the camera was detected, you can now run:"
echo "  python view_camera_ip.py"
echo "or"
echo "  python src/gige_viewer.py --aravis"