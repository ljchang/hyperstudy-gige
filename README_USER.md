# GigE Virtual Camera for macOS

## Overview

GigE Virtual Camera is a native macOS application that transforms GigE Vision industrial cameras into virtual webcams, making them accessible to any Mac application that uses cameras—including Zoom, Teams, OBS, QuickTime, and more.

Whether you're using machine vision cameras for streaming, video conferencing, or content creation, this app bridges the gap between professional GigE cameras and standard macOS applications.

## Key Features

### 🎥 **Virtual Camera Creation**

- Converts any GigE Vision camera into a standard macOS virtual camera
- Compatible with all applications that support macOS cameras
- Zero-configuration for most use cases—just connect and stream

### 📷 **Comprehensive Camera Controls**

Additional controls may be available if supported by your camera

- **Exposure Control**: Fine-tune exposure time with microsecond precision
- **Gain Adjustment**: Control sensor gain for optimal image brightness
- **Frame Rate Selection**: Choose from multiple frame rate options
- **Resolution Options**: Select from various resolutions including:
  - Native camera resolution (Auto)
  - 1920×1080 @ 30fps (Full HD)
  - 1280×720 @ 30fps (HD)
  - 640×480 @ 30fps
  - 512×512 @ 30fps
- **Pixel Format Support**: Auto, Bayer patterns (GR8/RG8/GB8/BG8), Mono8, RGB8

### 🔍 **Smart Camera Discovery**

- Automatic detection of all GigE Vision cameras on your network
- Live connection status monitoring
- Network hot-plug support—cameras are detected when connected
- Test camera mode for development and testing

### 👁️ **Live Preview**

- Built-in preview window to monitor your camera feed
- Toggle preview on/off to save system resources
- Real-time display of camera output

### 🔄 **Reliable Connection Management**

- Automatic reconnection on connection failures
- Connection status indicators
- Manual retry options
- Detailed debug output for troubleshooting

## System Requirements

- macOS 12.3 (Monterey) or later
- Apple Silicon (M1/M2/M3/M4)
- GigE Vision compatible camera
- Network connection to camera (Ethernet recommended)

## Installation Instructions

### Step 1: Install the Application

1. Open the downloaded DMG file
2. Drag **GigE Virtual Camera** to your Applications folder
3. Eject the DMG

### Step 2: First Launch & System Extension Approval

The app requires a system extension to create virtual cameras. On first launch:

1. **Open the app** from your Applications folder
2. **Click "Install Camera Extension"** when prompted
3. **System will show an alert** about the system extension:
   - Click "Open System Settings" in the alert
   - Or go to **System Settings → Privacy & Security**
4. **Find the blocked extension** near the bottom of Privacy & Security
5. **Click "Allow"** next to "System software from Luke Chang"
6. **Enter your password** when prompted
7. **Restart the app** if needed

> **Note**: The extension only needs approval once. Future updates will work automatically.

### Step 3: Verify Installation

1. The app should show **"Extension Status: Installed"**
2. Open **QuickTime Player** → File → New Movie Recording
3. Click the dropdown next to the record button
4. You should see **"GigE Virtual Camera"** in the camera list

## How to Use

### Basic Operation

1. **Launch GigE Virtual Camera** from Applications
2. **Select your camera** from the dropdown menu
   - The app will automatically discover cameras on your network
   - Click "Refresh" if your camera doesn't appear
3. **Click "Connect"** to establish connection
4. **Adjust camera settings** as needed:
   - Use sliders for Exposure, Gain, and Frame Rate
   - Select desired resolution from Format dropdown
5. **Open any camera-enabled app** (Zoom, Teams, OBS, etc.)
6. **Select "GigE Virtual Camera"** as your camera source

### Camera Controls

- **Exposure Time**: Adjusts how long the sensor captures light (in microseconds)
- **Gain**: Amplifies the sensor signal (higher = brighter but more noise)
- **Frame Rate**: Sets capture speed (only available with specific formats)
- **Format**: Choose resolution and frame rate preset
- **Pixel Format**: Select color/monochrome encoding

### Preview Window

- Click **"Show Preview"** to see real-time camera output
- Useful for adjusting settings before joining a video call
- Click **"Hide Preview"** to close the preview window

## Troubleshooting FAQ

### Q: The virtual camera doesn't appear in my apps

**A:**

1. Ensure the extension shows as "Installed" in the app
2. Try restarting the application you're trying to use
3. Some apps cache the camera list—quit and relaunch them
4. If still not visible, reinstall the extension:
   - Click "Uninstall Extension" in the app
   - Restart the app
   - Click "Install Extension" again

### Q: I see "Extension Needs Approval" status

**A:**

1. Go to **System Settings → Privacy & Security**
2. Look for a message about blocked software near the bottom
3. Click **"Allow"** next to the software
4. Enter your password and restart the app

### Q: My camera isn't detected

**A:**

1. Ensure your camera is powered on and connected to the network
2. Check that your Mac is on the same network as the camera
3. Try clicking the **"Refresh"** button
4. Verify firewall settings allow GigE Vision traffic
5. Test with another GigE Vision application if available

### Q: The video appears frozen or stutters

**A:**

1. This may indicate Core Media synchronization issues
2. **Restart the GigE Virtual Camera app** completely
3. Ensure no other application is accessing the GigE camera directly
4. Check network connection quality to the camera

### Q: Connection keeps failing

**A:**

1. Check the connection attempt counter—it will retry automatically
2. Verify camera IP address is accessible (shown in camera dropdown)
3. Ensure no other GigE Vision software is controlling the camera
4. Try selecting a lower resolution or frame rate

### Q: Preview works but other apps show black screen

**A:**

1. Make sure the app stays running—the virtual camera only works while the app is open
2. Try toggling "Hide Preview" then "Show Preview"
3. In the target app, switch to another camera and back to GigE Virtual Camera
4. Restart both the GigE Virtual Camera app and the target application

## Known Issues

### Chrome Browser Compatibility

The virtual camera is **not yet compatible with Chrome browser**. The camera will not appear in Chrome's camera selection. This is a known limitation that will be addressed in a future update.

**Workaround**: Use Safari, Firefox, or desktop applications instead of Chrome for now.

### Video Stream Broadcast Failures

If the video stream isn't being broadcast to applications despite showing in preview:

- The Core Media synchronization might have failed
- **Solution**: Completely quit and restart the GigE Virtual Camera app

### General Limitations

- The app must remain running for the virtual camera to work
- Only one instance of the app can run at a time
- Some GigE camera features may not be accessible through the interface

## Tips for Best Performance

1. **Use wired Ethernet** connection to your GigE camera for best reliability
2. **Close the preview window** when not needed to reduce CPU usage
3. **Select appropriate resolution** for your use case—lower resolutions use less bandwidth
4. **Adjust exposure and gain** based on your lighting conditions
5. **Keep the app in the background** while using the virtual camera

## Support

For issues, questions, or feature requests, please contact support or check for updates within the app.

---

**Version**: 1.0  
**Developer**: Luke Chang, PhD
**License**: See LICENSE file
