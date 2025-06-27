# Camera Extension Permissions - Important Discovery

## You were asked in the RIGHT place!

CMIOExtensions (Camera Media I/O Extensions) appear in:
- **System Settings > Privacy & Security > Camera** ✓ (CORRECT)
- NOT in Login Items & Extensions ✗

## What should happen:

1. When the app launches, macOS should detect the CMIOExtension
2. You should get a prompt asking to allow the camera extension
3. The prompt appears in **Privacy & Security > Camera**
4. After allowing, the virtual camera should appear in all apps

## Current Status:

- ✅ App is properly signed with Release configuration
- ✅ Provisioning profiles have correct entitlements
- ✅ Extension is properly embedded
- ❌ Extension process not running
- ❌ Virtual camera not appearing

## The Issue:

Since you were asked once earlier today in the Camera settings (which is correct!), the system might have already made a decision about your extension. 

## To Fix:

1. **Reset the camera permissions**:
   ```bash
   # Reset camera permissions for your app
   tccutil reset Camera com.lukechang.GigEVirtualCamera
   ```

2. **Check current camera permissions**:
   - Open System Settings > Privacy & Security > Camera
   - Look for "GigE Virtual Camera"
   - If it's there but OFF, turn it ON
   - If it's not there, we need to trigger the prompt again

3. **Force re-prompt**:
   ```bash
   # Kill the app
   killall GigEVirtualCamera
   
   # Reset permissions
   tccutil reset Camera com.lukechang.GigEVirtualCamera
   
   # Restart camera daemon
   sudo killall -9 appleh13camerad
   
   # Relaunch app
   open /Applications/GigEVirtualCamera.app
   ```

The key insight is that CMIOExtensions use Camera permissions, not system extension permissions!