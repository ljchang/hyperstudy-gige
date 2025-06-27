# CMIOExtension vs System Extension

## Important Discovery

Your extension is a **CMIOExtension** (Camera Media I/O Extension), not a traditional System Extension. This is a special type of extension that:

1. Has `CFBundlePackageType = SYSX` 
2. Contains CMIOExtension dictionary in Info.plist
3. Doesn't require system extension installation prompts
4. Automatically registers with the system when the app is launched

## How CMIOExtensions Work

CMIOExtensions are automatically discovered and loaded by the system when:
1. The app is properly signed
2. The app is in /Applications
3. The extension is in Contents/Library/SystemExtensions/

## Verification Steps

1. Check if the camera is available in system:
```bash
# List all video devices
system_profiler SPCameraDataType

# Or check in any camera app like Photo Booth, Zoom, etc.
```

2. Check if the extension is loaded:
```bash
# Look for your extension in running processes
ps aux | grep GigECameraExtension

# Check CMIO subsystem logs
log stream --predicate 'subsystem == "com.apple.cmio"' --level debug
```

## The Issue

The provisioning profile for the extension may need specific entitlements for CMIOExtension. However, CMIOExtensions don't trigger the system extension installation prompt - they're loaded automatically.

## What You Should See

1. When you launch the app, the CMIOExtension should automatically register
2. The virtual camera should appear in apps like Photo Booth, Zoom, Teams, etc.
3. No system extension prompt is needed

## Next Steps

1. Open Photo Booth or another camera app
2. Check if "GigE Virtual Camera" appears in the camera list
3. If not, check Console.app for CMIO errors