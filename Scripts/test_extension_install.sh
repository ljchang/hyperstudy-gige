#!/bin/bash

echo "=== Testing Extension Installation ==="
echo
echo "1. First, run this command in Terminal to reset system extensions:"
echo "   sudo systemextensionsctl reset"
echo
echo "2. Then run the app to test extension installation:"
echo

# Run the app
open /Applications/GigEVirtualCamera.app

echo
echo "3. Check the app's extension installation status"
echo
echo "4. If still failing, check Console.app for new errors:"
echo "   - Open Console.app"
echo "   - Filter by 'GigEVirtualCamera' or 'sysextd'"
echo "   - Look for validation errors"
echo

# Also run a final validation check
echo "5. Running validation check..."
echo
./Scripts/final_validation_check.sh