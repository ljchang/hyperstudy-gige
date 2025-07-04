# Extension Not Starting Issue

## Current Status

The callback-based CMIO property listener has been implemented successfully, but there's still no video feed in Photo Booth because the extension is not starting.

## Root Cause

The GigEVirtualCameraExtension process is not being launched by the system when Photo Booth selects the virtual camera, even though:

1. ✅ The extension is properly registered with the system (`[activated enabled]`)
2. ✅ The virtual camera is visible to macOS (`system_profiler` shows it)
3. ✅ The extension bundle exists in the app with correct naming
4. ✅ The Info.plist has proper CMIO configuration
5. ✅ The app is running and trying to send frames
6. ❌ The extension process never starts (no NSLog messages appear)
7. ❌ No property listener initialization logs from the app

## Diagnostic Results

### 1. Extension Registration
```
com.lukechang.GigEVirtualCamera.Extension (1.0/1) [activated enabled]
```

### 2. Virtual Camera Visibility
```
GigE Virtual Camera:
  Model ID: GigE Virtual Camera
  Unique ID: 4B59CDEF-BEA6-52E8-06E7-AD1B8E6B29C4
```

### 3. App Logs Show
- Aravis is streaming frames
- CMIOSinkConnector cannot send frames (not connected to sink)
- No CMIOPropertyListener initialization logs

### 4. Extension Process
- Never starts when Photo Booth selects the camera
- No NSLog messages from main.swift appear

## Possible Issues

1. **Mach Service Name Mismatch**: The Info.plist was using a hardcoded mach service name that may not match the actual team ID prefix.

2. **Extension Bundle Naming**: The build process creates `GigECameraExtension.systemextension` but the system expects `com.lukechang.GigEVirtualCamera.Extension.systemextension`. This was manually fixed but may indicate a deeper configuration issue.

3. **Missing Property Listener Logs**: Even though the CMIOSinkConnector should be initialized in CameraManager, we don't see any property listener logs, suggesting the initialization might be failing silently.

## Next Steps to Fix

### 1. Verify Extension Can Start Manually
Test if the extension binary can run at all:
```bash
/Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension/Contents/MacOS/GigECameraExtension
```

### 2. Check System Logs for Launch Failures
```bash
log show --predicate 'process == "launchd" OR process == "kernel"' --last 5m | grep -i "gige"
```

### 3. Verify Code Signing
```bash
codesign -dv --verbose=4 /Applications/GigEVirtualCamera.app/Contents/Library/SystemExtensions/com.lukechang.GigEVirtualCamera.Extension.systemextension
```

### 4. Test with Console.app
Open Console.app, clear the display, then select the virtual camera in Photo Booth to see all system messages.

### 5. Consider Extension Conflicts
The duplicate extensions (`[terminated waiting to uninstall on reboot]`) might be interfering. A reboot might be necessary to clean up.

## Summary

The callback-based property listener implementation is correct, but it cannot function because the extension process never starts. The primary issue is that macOS is not launching the extension when applications try to use the virtual camera, despite it being properly registered with the system.