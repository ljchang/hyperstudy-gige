# Workaround for Python Segmentation Fault

The Python Aravis bindings are causing segmentation faults in the Anaconda environment. Here are the current workarounds:

## Option 1: Use arv-viewer-0.8 (Recommended for now)

The Aravis GUI viewer works perfectly:
```bash
arv-viewer-0.8
```

Features:
- Live view
- Snapshot capture
- Camera controls
- Frame rate display

## Option 2: Use GStreamer Pipeline

If you have GStreamer installed with the Aravis plugin:
```bash
# View camera
gst-launch-1.0 aravissrc ! videoconvert ! autovideosink

# Record to file
gst-launch-1.0 aravissrc ! videoconvert ! x264enc ! mp4mux ! filesink location=output.mp4
```

## Option 3: Different Python Environment

The segfault appears to be specific to Anaconda. Try:

1. Create a virtual environment with system Python:
```bash
/usr/bin/python3 -m venv gige_env
source gige_env/bin/activate
pip install opencv-python numpy
pip install PyGObject
```

2. Install Harvesters with a GenTL producer:
```bash
pip install harvesters
# Then use with a GenTL producer CTI file
```

## Option 4: Alternative Camera SDKs

Consider camera-specific SDKs that might work better:

1. **Vimba Python** (if compatible with your camera)
2. **pypylon** (primarily for Basler, but sometimes works with others)
3. **IDS Peak** (for IDS cameras)

## Option 5: Use Camera's Native Tools

Check if MRC Systems provides their own software for your camera model. Many manufacturers provide their own SDKs and viewers.

## Root Cause

The segmentation fault is likely due to:
- Incompatibility between Anaconda's Python and system libraries
- GTK/GLib version conflicts
- Memory management issues in the Python GObject bindings

## For LiveKit Streaming

While we work on the Python issues, you could:
1. Use `arv-viewer-0.8` for local viewing
2. Set up a GStreamer pipeline to stream to an RTMP server
3. Bridge RTMP to WebRTC using LiveKit or similar