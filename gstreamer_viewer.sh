#!/bin/bash
# GStreamer viewer for GigE camera

echo "GStreamer GigE Camera Viewer"
echo "============================"

# Set environment to use Homebrew's libraries
export DYLD_LIBRARY_PATH=/opt/homebrew/lib:$DYLD_LIBRARY_PATH
export GST_PLUGIN_PATH=/opt/homebrew/lib/gstreamer-1.0
export PATH=/opt/homebrew/bin:$PATH

# Unset Anaconda paths that might interfere
unset PYTHONPATH
unset CONDA_PREFIX

echo "Testing GStreamer with test source first..."
/opt/homebrew/bin/gst-launch-1.0 videotestsrc num-buffers=100 ! autovideosink

echo ""
echo "Now trying with Aravis camera..."
echo "Press Ctrl+C to stop"

# Try to launch with Aravis source
/opt/homebrew/bin/gst-launch-1.0 aravissrc ! videoconvert ! autovideosink

# If that fails, show alternative
if [ $? -ne 0 ]; then
    echo ""
    echo "Failed to use aravissrc. Alternatives:"
    echo "1. Use arv-viewer-0.8 (which works)"
    echo "2. Try with specific camera name:"
    echo "   gst-launch-1.0 aravissrc camera-name='MRC Systems GmbH-GVRD-MRC MR-CAM-HR-MR_CAM_HR_0020' ! videoconvert ! autovideosink"
fi