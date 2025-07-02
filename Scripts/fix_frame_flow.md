# Fix for Frame Flow Issue

## Current Problem
The app is trying to send frames to a CMIO sink stream, but Photo Booth doesn't consume from sink streams - it only receives from source streams.

## The Correct Architecture
According to the CMIO Extensions Developer Guide:
1. **Sink streams** are for apps to send frames TO the extension (e.g., for effects processing)
2. **Source streams** are for the extension to send frames TO client apps (e.g., Photo Booth)

## Current Issue
- The app connects to the sink stream and tries to enqueue frames
- But Photo Booth never starts consuming from the sink stream
- Result: Queue fills up and all frames are dropped

## Solution
The extension needs to generate its own frames or receive them through a different mechanism:

### Option 1: Direct Frame Generation in Extension
The extension should connect to the GigE camera directly and generate frames internally.

### Option 2: Shared Memory or XPC
Use a custom IPC mechanism to pass frames from the app to the extension.

### Option 3: Use Sink Stream Correctly
The sink stream should only be used when a client app (not our app) wants to send frames to the extension for processing.

## Recommended Fix
Since the extension is sandboxed and can't access the network directly, we should:
1. Have the app capture frames from the GigE camera
2. Pass frames to the extension via shared memory or XPC
3. The extension outputs frames through its source stream to Photo Booth

This matches the architecture shown in the CMIO guide where the extension acts as a bridge between custom hardware/software and macOS apps.