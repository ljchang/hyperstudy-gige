# hyperstudy-gige

Python applications for viewing and streaming GigE Vision cameras, with local display/recording and LiveKit WebRTC streaming capabilities.

## Features

- **Local Viewer**: Display GigE camera feed with OpenCV
- **Recording**: Save video files and snapshots
- **LiveKit Streaming**: Stream camera feed via WebRTC
- **Universal Support**: Works with any GigE Vision compliant camera

## Current Status

- ✅ **arv-viewer-0.8** works perfectly for viewing the camera
- ⚠️ **Python Aravis bindings** have segmentation fault issues in Anaconda environment
- ✅ **Camera detected**: MRC Systems GmbH-GVRD-MRC MR-CAM-HR (169.254.90.244)

## Quick Start

### Prerequisites

1. Install a GenTL Producer for your camera:
   - Matrix Vision: `mvGenTLProducer.cti`
   - Basler: `ProducerPylon.cti`
   - Allied Vision: `Vimba_gentl.cti`

2. Install Python dependencies:
```bash
pip install -r requirements.txt
```

### Working Solution

Currently, the most reliable way to view the camera:
```bash
arv-viewer-0.8
```

### Python Implementations (In Development)

The Python implementations are in the `python/` directory but face compatibility issues:

```bash
cd python/

# List cameras (if it works)
python examples/list_cameras.py

# View camera (currently segfaults)
python src/gige_viewer.py --aravis
```

See `python/README.md` for details on Python implementation status.

## Project Structure

```
hyperstudy-gige/
├── python/                    # Python implementations
│   ├── src/                   # Source code
│   ├── config/                # Configuration files
│   ├── examples/              # Example scripts
│   ├── recordings/            # Output directory
│   └── requirements.txt       # Python dependencies
├── WORKAROUND.md              # Solutions for current issues
├── setup_network.sh           # Network setup script
└── gstreamer_viewer.sh        # GStreamer test script
```

## Other Approaches to Try

1. **C++ Implementation** - Use Aravis C API directly
2. **Rust Implementation** - Use aravis-rs bindings
3. **Node.js** - Use node-aravis if available
4. **Different Camera SDK** - Check MRC Systems website

## Configuration

### Environment Variables
- `LIVEKIT_URL`: LiveKit server URL
- `LIVEKIT_API_KEY`: API key for token generation
- `LIVEKIT_API_SECRET`: API secret for token generation
- `GENTL_PRODUCER_PATH`: Path to GenTL producer (optional)

### Configuration File
See `config/livekit_example.yaml` for YAML configuration options.

## License

MIT License