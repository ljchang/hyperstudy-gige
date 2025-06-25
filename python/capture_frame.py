#!/usr/bin/env python3
"""
Capture frames from GigE camera using arv-camera-test
"""

import subprocess
import time
from datetime import datetime
from pathlib import Path

def capture_frames(duration=10, output_dir="captures"):
    """
    Capture frames using arv-camera-test command
    """
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)
    
    print(f"Capturing frames for {duration} seconds...")
    print("Output directory:", output_path.absolute())
    
    # Use arv-camera-test to capture frames
    cmd = [
        "arv-camera-test-0.8",
        f"-d", str(duration),
        "-n", "100",  # buffer count
        "--auto-exposure",
        "--make-realtime"
    ]
    
    try:
        print(f"Running: {' '.join(cmd)}")
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✓ Capture completed successfully!")
            print("\nOutput:")
            print(result.stdout)
        else:
            print("✗ Capture failed!")
            print("Error:", result.stderr)
            
    except Exception as e:
        print(f"Error running arv-camera-test: {e}")


def capture_single_frame():
    """
    Capture a single frame using arv-tool
    """
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"frame_{timestamp}.png"
    
    print(f"Capturing single frame to {filename}...")
    
    # First, check if camera is available
    check_cmd = ["arv-tool-0.8"]
    result = subprocess.run(check_cmd, capture_output=True, text=True)
    
    if "MRC Systems" in result.stdout:
        print("✓ Camera detected")
        
        # Note: arv-tool doesn't directly save images, but we can get camera info
        print("\nCamera info:")
        info_cmd = ["arv-tool-0.8", "control", "Width", "Height", "PixelFormat"]
        result = subprocess.run(info_cmd, capture_output=True, text=True)
        print(result.stdout)
        
        print("\nFor continuous capture with GUI, use:")
        print("  arv-viewer-0.8")
        
        print("\nFor programmatic access, consider:")
        print("1. Using a different Python environment without Anaconda")
        print("2. Installing pypylon or vimba Python SDK")
        print("3. Using gstreamer with aravis plugin")
        
    else:
        print("✗ Camera not detected")


def main():
    print("GigE Camera Capture Tool")
    print("=" * 50)
    
    # Check camera availability
    capture_single_frame()
    
    print("\n" + "=" * 50)
    print("\nTo use the GUI viewer:")
    print("  arv-viewer-0.8")
    
    print("\nTo stream with gstreamer:")
    print("  gst-launch-1.0 aravissrc ! videoconvert ! autovideosink")


if __name__ == "__main__":
    main()