#!/usr/bin/env python3
"""
Test GigE camera with OpenCV directly
"""

import cv2
import numpy as np

def test_opencv_camera():
    print("Testing GigE camera with OpenCV...")
    print("-" * 50)
    
    # Try different camera indices
    for index in range(5):
        print(f"\nTrying camera index {index}...")
        
        # Try to open camera with GigE-specific backend
        cap = cv2.VideoCapture(index, cv2.CAP_ARAVIS)
        
        if cap.isOpened():
            print(f"✓ Camera {index} opened successfully!")
            
            # Get properties
            width = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
            height = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)
            fps = cap.get(cv2.CAP_PROP_FPS)
            
            print(f"  Resolution: {int(width)}x{int(height)}")
            print(f"  FPS: {fps}")
            
            # Try to grab a frame
            ret, frame = cap.read()
            if ret:
                print(f"  ✓ Successfully grabbed frame: {frame.shape}")
                cv2.imwrite(f"opencv_test_frame_{index}.png", frame)
                print(f"  Saved to: opencv_test_frame_{index}.png")
            else:
                print("  ✗ Failed to grab frame")
            
            cap.release()
            return True
        else:
            print(f"  ✗ Could not open camera {index}")
    
    print("\nNo cameras found with OpenCV + Aravis backend")
    return False

def main():
    # Check OpenCV build info
    print("OpenCV Build Information:")
    print("-" * 50)
    build_info = cv2.getBuildInformation()
    
    # Look for GigE/Aravis support
    for line in build_info.split('\n'):
        if any(keyword in line.lower() for keyword in ['gige', 'aravis', 'pvapi', 'video']):
            print(line.strip())
    
    print("\n")
    
    # Test camera
    if test_opencv_camera():
        print("\n✓ Successfully connected to GigE camera via OpenCV!")
    else:
        print("\n✗ Could not connect to GigE camera")
        print("\nTroubleshooting:")
        print("1. Make sure your camera is connected and powered on")
        print("2. Check if you need to configure network settings for GigE camera")
        print("3. You might need OpenCV compiled with Aravis support")

if __name__ == "__main__":
    main()