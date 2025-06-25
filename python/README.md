# Python Implementation for GigE Camera

This directory contains Python-based approaches for working with GigE cameras.

## Current Status

- ⚠️ **Segmentation fault issues** with PyGObject/Aravis in Anaconda environment
- ✅ **Harvesters library** works with simulator
- ❌ **OpenCV** doesn't have Aravis support in current installation

## Directory Structure

```
python/
├── src/                      # Source code
│   ├── gige_camera.py       # Harvesters-based camera interface
│   ├── gige_camera_aravis.py # Aravis-based camera interface (segfaults)
│   ├── gige_viewer.py       # Camera viewer with recording
│   └── gige_livekit_streamer.py # LiveKit WebRTC streamer
├── config/                   # Configuration files
│   └── livekit_example.yaml
├── examples/                 # Example scripts
│   ├── basic_viewer.py
│   ├── livekit_streamer.py
│   └── list_cameras.py
├── recordings/              # Output directory
└── requirements.txt         # Python dependencies
```

## Known Issues

1. **Anaconda Conflict**: PyGObject segfaults due to library conflicts
2. **No GenTL Producer**: Need a free GenTL producer for Harvesters
3. **OpenCV**: Current build lacks Aravis support

## Workarounds

See [WORKAROUND.md](../WORKAROUND.md) in the parent directory.

## Alternative Approaches to Try

1. **Fresh Python Environment** (without Anaconda)
2. **Docker Container** with proper dependencies
3. **Different camera SDK** (Vimba, Pylon, etc.)
4. **C++ Implementation** using Aravis directly