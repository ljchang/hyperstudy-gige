# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Common Development Commands

### Setup and Installation
```bash
# Install dependencies
pip install -r requirements.txt

# Install GenTL Producer (required for camera access)
# For Matrix Vision cameras:
sudo apt-get install mvimpact-acquire  # Linux
# Or download from manufacturer website

# Copy environment variables
cp .env.example .env
# Edit .env with your LiveKit credentials
```

### Running the Applications

```bash
# List available cameras
python examples/list_cameras.py

# Run camera viewer with recording
python src/gige_viewer.py

# Run LiveKit streamer
python src/gige_livekit_streamer.py

# With custom GenTL producer path
python src/gige_viewer.py --producer /path/to/GenTLProducer.cti

# With config file
python src/gige_livekit_streamer.py --config config/livekit.yaml
```

### Testing
```bash
# Test camera connection
python examples/list_cameras.py

# Test viewer without recording
python examples/basic_viewer.py
```

## Architecture Overview

### Core Components

1. **GigECamera Module** (`src/gige_camera.py`)
   - Wrapper around Harvesters library for GigE Vision cameras
   - Handles camera discovery, connection, and frame acquisition
   - Auto-detects common GenTL producers
   - Provides unified interface for camera control

2. **GigE Viewer** (`src/gige_viewer.py`)
   - Local display of camera feed using OpenCV
   - Recording capabilities (video and snapshots)
   - Keyboard controls for user interaction
   - FPS counter and overlay information

3. **LiveKit Streamer** (`src/gige_livekit_streamer.py`)
   - Streams camera feed to LiveKit WebRTC
   - Async implementation using asyncio
   - Configurable via YAML or environment variables
   - Automatic token generation

### Key Design Decisions

- **Harvesters Library**: Used for universal GigE Vision support instead of camera-specific SDKs
- **Separation of Concerns**: Camera module is separate from viewing/streaming logic
- **Async for LiveKit**: Uses async/await for WebRTC streaming to handle network operations efficiently
- **Configuration**: Supports both file-based (YAML) and environment variable configuration

### Frame Pipeline

1. Camera captures frame as numpy array (via Harvesters)
2. Bayer pattern debayering if needed (handled in GigECamera)
3. For viewer: Direct display with OpenCV
4. For LiveKit: Convert to RGBA format before streaming

### Common Issues and Solutions

- **No cameras found**: Ensure GenTL producer is installed and path is correct
- **Frame format issues**: Camera module handles Bayer to RGB conversion automatically
- **LiveKit connection**: Check URL, credentials, and network connectivity
- **Performance**: Adjust camera FPS and resolution in configuration