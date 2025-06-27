# GigE Virtual Camera - Debugging Guide

## Quick Debugging Checklist

### 1. Virtual Camera Not Appearing

**Check if extension is loaded:**
```bash
ps aux | grep -i GigECameraExtension
```

**Check Console.app for errors:**
```bash
log stream --predicate 'subsystem == "com.lukechang.GigEVirtualCamera.Extension"' --debug
```

**Verify CMIO registration:**
```bash
system_profiler SPCameraDataType | grep -i gige
```

### 2. No Camera Frames

**Check Aravis can see cameras:**
```bash
arv-camera-test-0.8 --list-devices
```

**Monitor frame distribution:**
```bash
log stream --predicate 'process == "GigEVirtualCamera" && eventMessage CONTAINS "frame"' --style compact
```

### 3. Extension Loading Issues

**Requirements:**
- App MUST be in `/Applications`
- App and extension must be properly signed
- Entitlements must match (check with `codesign -d --entitlements -`)

**Reset if needed:**
```bash
# Reset all extensions (use carefully)
systemextensionsctl reset

# Kill camera daemon
sudo killall -9 appleh13camerad
```

### 4. Common Issues and Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| Extension not loading | App not in /Applications | Move app to /Applications |
| No cameras found | Network/firewall blocking GigE | Check network settings, disable firewall temporarily |
| Frames not appearing | Camera not streaming | Check preview works in main app first |
| Build errors | Missing Aravis | Run `brew install aravis` |

### 5. Useful Commands

**Check entitlements:**
```bash
# App entitlements
codesign -d --entitlements - /Applications/GigEVirtualCamera.app

# Extension entitlements
codesign -d --entitlements - /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/GigECameraExtension.systemextension
```

**Monitor all related logs:**
```bash
# Combined log monitoring
log stream --predicate '(subsystem == "com.lukechang.GigEVirtualCamera") || (subsystem == "com.lukechang.GigEVirtualCamera.Extension") || (process == "appleh13camerad" && eventMessage CONTAINS "GigE")' --style compact
```

**Test scripts:**
```bash
# Test extension installation
./Scripts/test_extension.sh

# Test Aravis functionality
./Scripts/test_aravis.sh
```

### 6. Architecture Notes

The app uses a simplified architecture:
- **No XPC needed** - Extension directly accesses GigECameraManager
- **No System Extension** - Uses CMIOExtension (automatic loading)
- **Shared instance** - Both app and extension use same camera manager

This means most issues are related to:
1. Code signing / entitlements
2. App location (/Applications required)
3. Network access to GigE camera
4. Aravis library configuration