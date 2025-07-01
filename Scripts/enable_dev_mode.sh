#!/bin/bash

echo "=== Enabling System Extension Developer Mode ==="
echo
echo "This will enable developer mode for system extensions,"
echo "which allows loading extensions without full notarization."
echo
echo "You will need to enter your password."
echo

# Enable developer mode
sudo systemextensionsctl developer on

echo
echo "Developer mode status:"
systemextensionsctl developer

echo
echo "Now try:"
echo "1. Restart the GigE Virtual Camera app"
echo "2. Click 'Install Extension'"
echo "3. The extension should load without requiring notarization"