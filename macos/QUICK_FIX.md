# Quick Solutions for Testing

## Problem
System extensions require special provisioning profiles with the System Extension capability enabled in your Apple Developer account. Without this, you get error code 1.

## Solutions

### 1. Direct LiveKit Integration (Recommended)
Skip the virtual camera entirely:
```bash
cd /Users/lukechang/Github/hyperstudy-gige/python
python gige_livekit_streamer.py
```
This Python script already works and streams directly to LiveKit!

### 2. Test the UI in Simulation Mode
The app now has a test mode. When you click "Install Extension" while running from Xcode, it will simulate a successful connection so you can see the UI.

### 3. Use OBS Virtual Camera Plugin
- Install OBS: `brew install --cask obs`
- Use OBS to capture a window showing your GigE camera
- OBS Virtual Camera appears in all apps immediately

### 4. Fix System Extension (Requires Apple Developer Portal)
1. Log in to https://developer.apple.com
2. Go to Certificates, Identifiers & Profiles
3. Edit your App ID
4. Add "System Extension" capability
5. Create new provisioning profiles
6. Download and install them
7. Update Xcode to use manual signing

## Immediate Testing

Since the Python version already works, you can:
1. Use the Python LiveKit streamer for actual functionality
2. Use the macOS app UI in test mode to see the interface
3. Later, set up proper provisioning for the system extension

The Python implementation at `/Users/lukechang/Github/hyperstudy-gige/python/gige_livekit_streamer.py` is fully functional and can stream your camera to LiveKit right now!