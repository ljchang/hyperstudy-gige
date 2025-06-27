#!/bin/bash

echo "Testing Aravis streaming..."

# First, check if we can get a single frame
echo "Attempting to capture a single frame..."
arv-tool-0.8 -n "MRC Systems GmbH-GVRD-MRC MR-CAM-HR-MR_CAM_HR_0020" acquisition -f 1

# Check stream parameters
echo -e "\nChecking stream parameters..."
arv-tool-0.8 -n "MRC Systems GmbH-GVRD-MRC MR-CAM-HR-MR_CAM_HR_0020" control GevSCPSPacketSize GevSCPD

# Try with different packet sizes
echo -e "\nTrying with smaller packet size..."
arv-tool-0.8 -n "MRC Systems GmbH-GVRD-MRC MR-CAM-HR-MR_CAM_HR_0020" control GevSCPSPacketSize=1400

# Test again
echo -e "\nAttempting to capture after adjustment..."
arv-tool-0.8 -n "MRC Systems GmbH-GVRD-MRC MR-CAM-HR-MR_CAM_HR_0020" acquisition -f 1