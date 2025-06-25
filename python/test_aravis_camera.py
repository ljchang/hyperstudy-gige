#!/usr/bin/env python3
"""
Test script for Aravis camera connection
"""

import sys
from pathlib import Path

# Add parent directory to path
sys.path.append(str(Path(__file__).parent))

from src.gige_camera_aravis import GigECameraAravis
import logging

logging.basicConfig(level=logging.INFO)

def main():
    print("Testing Aravis camera connection...")
    print("-" * 50)
    
    # Create camera instance
    camera = GigECameraAravis()
    
    # List devices
    devices = camera.list_devices()
    
    if not devices:
        print("No cameras found!")
        return
    
    print(f"Found {len(devices)} camera(s):\n")
    
    for i, device in enumerate(devices):
        print(f"Camera {i}:")
        print(f"  Vendor: {device['vendor']}")
        print(f"  Model: {device['model']}")
        print(f"  Serial: {device['serial']}")
        print(f"  ID: {device['id']}")
        print(f"  Address: {device['address']}")
        print()
    
    # Try to connect to first camera
    print("Attempting to connect to camera 0...")
    if camera.connect(0):
        print("✓ Successfully connected!")
        
        # Get camera info
        width, height = camera.get_resolution()
        fps = camera.get_frame_rate()
        print(f"  Resolution: {width}x{height}")
        print(f"  Frame rate: {fps:.1f} FPS")
        
        # Start acquisition
        print("\nTrying to start acquisition...")
        if camera.start_acquisition():
            print("✓ Acquisition started!")
            
            # Try to grab a frame
            print("\nTrying to grab a frame...")
            frame = camera.grab_frame()
            if frame is not None:
                print(f"✓ Successfully grabbed frame: {frame.shape}")
            else:
                print("✗ Failed to grab frame")
            
            camera.stop_acquisition()
        else:
            print("✗ Failed to start acquisition")
        
        camera.disconnect()
    else:
        print("✗ Failed to connect to camera")


if __name__ == "__main__":
    main()