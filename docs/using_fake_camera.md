# Using Aravis Fake Camera for Testing

When you don't have a real GigE Vision camera available, you can use Aravis's built-in fake camera for testing the virtual camera functionality.

## Using the Fake Camera

The fake camera is integrated directly into the app - no separate process needed!

1. Launch the GigE Virtual Camera app
2. In the camera dropdown, you'll see "Test Camera (Aravis Simulator)" listed along with any real cameras
3. Select "Test Camera (Aravis Simulator)" from the dropdown
4. Click "Connect" - this will automatically start the Aravis fake camera internally
5. Click "Start Streaming" to begin receiving test frames
6. The virtual camera will now be available to other macOS applications

When you disconnect or select a different camera, the fake camera automatically stops.

## Fake Camera Features

The Aravis fake camera provides:
- Standard GigE Vision protocol implementation
- Test pattern generation (moving pattern)
- Configurable frame rate and resolution
- Full camera control features

## How It Works

When you select the test camera and click "Connect":
1. The app starts an internal Aravis fake camera instance
2. The fake camera appears on the loopback interface (127.0.0.1)
3. The app discovers and connects to it just like a real GigE camera
4. When you disconnect, the fake camera is automatically stopped

## Troubleshooting

If the fake camera doesn't work:
1. Check the Console.app logs for any error messages
2. Try restarting the app
3. Check firewall settings - GigE Vision uses UDP ports
4. The app bundles its own Aravis library, so no external installation is needed

## Benefits Over Custom Test Pattern

Using Aravis's fake camera instead of a custom test pattern generator has several advantages:
- Tests the full GigE Vision protocol stack
- More realistic simulation of a real camera
- No additional code to maintain
- Supports all standard GigE Vision features
- Can simulate network issues for robustness testing