# Troubleshooting: No Video Feed in Photo Booth

## Current Status

The callback-based CMIO property listener has been implemented and the app builds successfully, but there's still no video feed in Photo Booth.

## Issues Identified

### 1. Extension Not Running
- Photo Booth is running (PID: 6002)
- GigEVirtualCamera app is running (PID: 14076) 
- **GigEVirtualCameraExtension is NOT running**

### 2. Extension Registration Issues
- Multiple old extensions waiting to uninstall
- One extension marked as [activated enabled]
- Extension in app bundle has wrong name: `GigECameraExtension.systemextension` instead of full bundle ID

### 3. No Property Listener Logs
- CMIOPropertyListener initialization logs not appearing
- No sink stream discovery logs
- No connection attempt logs

## Root Causes

### 1. Extension Not Starting
The CMIO extension is not being started by the system when Photo Booth opens. This could be due to:
- System extension database issues (many old versions waiting to uninstall)
- Extension naming/signing issues
- Extension not properly registered with CMIO

### 2. Property Listener Not Running
Even though the code was added, there are no logs showing the property listener is initializing. This suggests:
- The app may need to explicitly start the property listener
- The extension manager may not be triggering installation

## Next Steps to Fix

### 1. Clean Extension Installation
```bash
# Reset system extensions
systemextensionsctl reset

# Remove all old app copies
rm -rf /Applications/GigEVirtualCamera.app

# Rebuild with proper extension naming
./Scripts/build_dev.sh

# Install fresh
cp -R build/Debug/GigEVirtualCamera.app /Applications/

# Run app and approve extension
open /Applications/GigEVirtualCamera.app
```

### 2. Verify Property Listener Initialization
The property listener should be initialized when CMIOSinkConnector is created in CameraManager. Need to verify:
- CameraManager.setupFrameHandler() is called
- CMIOSinkConnector() constructor runs
- setupPropertyListener() is executed

### 3. Debug Extension Loading
Need to check why the extension isn't starting:
- Verify extension Info.plist has correct CMIO keys
- Check if extension bundle ID matches what system expects
- Ensure extension is properly signed

### 4. Manual Testing
Once extension is running:
1. Open Photo Booth
2. Select "GigE Virtual Camera"
3. Monitor logs for:
   - Extension starting
   - Property listener detecting sink stream
   - Automatic connection to sink
   - Frame flow starting

## Key Log Messages to Look For

When working correctly, you should see:
1. `CMIOPropertyListener initialized`
2. `CMIO property listener started successfully`
3. `Found device: 4B59CDEF-BEA6-52E8-06E7-AD1B8E6B29C4`
4. `Sink stream discovered via callback`
5. `Successfully connected to virtual camera sink stream via property listener!`
6. `Starting Aravis streaming after sink connection`
7. `Sent frame #X to sink`

## Current Blockers

1. **Extension not running** - This is the primary blocker. Without the extension running, no virtual camera is available to Photo Booth.
2. **No property listener logs** - Even with the app running, the property listener doesn't appear to be initializing.

The callback implementation is correct but can't function without the extension running and the property listener being properly initialized.