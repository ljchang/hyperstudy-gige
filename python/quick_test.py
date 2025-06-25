#!/usr/bin/env python3
"""Quick test to capture and save a frame"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

from src.gige_camera_aravis import GigECameraAravis
import cv2
import numpy as np

def main():
    print("Quick Camera Test - Will capture and save one frame")
    print("-" * 50)
    
    camera = GigECameraAravis()
    
    # List devices
    devices = camera.list_devices()
    print(f"Found {len(devices)} camera(s)")
    
    if not devices:
        print("No cameras found!")
        return
        
    # Connect
    print("\nConnecting to camera...")
    if not camera.connect(0):
        print("Failed to connect!")
        return
        
    print("Connected!")
    
    # Get info
    width, height = camera.get_resolution()
    print(f"Resolution: {width}x{height}")
    
    # Start acquisition
    print("\nStarting acquisition...")
    if not camera.start_acquisition():
        print("Failed to start acquisition!")
        camera.disconnect()
        return
        
    print("Acquisition started!")
    
    # Grab a frame
    print("\nGrabbing frame...")
    frame = camera.grab_frame(timeout_ms=5000)
    
    if frame is not None:
        print(f"Got frame! Shape: {frame.shape}")
        
        # Save the frame
        output_file = "test_frame.png"
        cv2.imwrite(output_file, frame)
        print(f"Saved frame to: {output_file}")
        
        # Show basic statistics
        print(f"Frame stats:")
        print(f"  Min pixel value: {np.min(frame)}")
        print(f"  Max pixel value: {np.max(frame)}")
        print(f"  Mean pixel value: {np.mean(frame):.1f}")
    else:
        print("Failed to grab frame!")
    
    # Cleanup
    camera.stop_acquisition()
    camera.disconnect()
    print("\nDone!")

if __name__ == "__main__":
    main()