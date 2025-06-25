#!/usr/bin/env python3
"""
View GigE camera by direct IP address
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

from src.gige_camera_aravis import GigECameraAravis
import cv2
import time
import numpy as np

def main():
    # Your camera's IP
    camera_ip = "169.254.90.244"
    
    print(f"Connecting to GigE camera at {camera_ip}")
    print("-" * 50)
    
    # Create camera instance
    camera = GigECameraAravis()
    
    # Connect directly to IP
    if not camera.connect(ip_address=camera_ip):
        print("Failed to connect to camera!")
        print("\nTry running:")
        print("  sudo ifconfig en0 alias 169.254.1.1 netmask 255.255.0.0")
        return
    
    print("Connected successfully!")
    
    # Get camera info
    width, height = camera.get_resolution()
    fps = camera.get_frame_rate()
    print(f"Resolution: {width}x{height} @ {fps} FPS")
    
    # Start acquisition
    if not camera.start_acquisition():
        print("Failed to start acquisition!")
        camera.disconnect()
        return
    
    print("Press 'q' to quit, 's' to save snapshot")
    
    # Create window
    cv2.namedWindow("GigE Camera", cv2.WINDOW_NORMAL)
    cv2.resizeWindow("GigE Camera", 1280, 720)
    
    frame_count = 0
    start_time = time.time()
    
    try:
        while True:
            # Grab frame
            frame = camera.grab_frame(timeout_ms=1000)
            
            if frame is not None:
                frame_count += 1
                
                # Calculate FPS
                elapsed = time.time() - start_time
                if elapsed > 0:
                    current_fps = frame_count / elapsed
                    
                    # Add FPS text
                    cv2.putText(frame, f"FPS: {current_fps:.1f}", (10, 30),
                               cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
                
                # Display frame
                cv2.imshow("GigE Camera", frame)
            
            # Handle key press
            key = cv2.waitKey(1) & 0xFF
            if key == ord('q'):
                break
            elif key == ord('s'):
                filename = f"snapshot_{int(time.time())}.png"
                cv2.imwrite(filename, frame)
                print(f"Saved: {filename}")
    
    except KeyboardInterrupt:
        print("\nInterrupted")
    finally:
        # Cleanup
        camera.stop_acquisition()
        camera.disconnect()
        cv2.destroyAllWindows()
        print("Done!")


if __name__ == "__main__":
    main()