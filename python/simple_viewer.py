#!/usr/bin/env python3
"""
Simple GigE camera viewer using OpenCV with direct camera index
"""

import cv2
import numpy as np
import time
from datetime import datetime
from pathlib import Path
import sys

# Create recordings directory
recordings_dir = Path("recordings")
recordings_dir.mkdir(exist_ok=True)

def main():
    print("Simple GigE Camera Viewer")
    print("-" * 50)
    print("Trying to connect to camera...")
    
    # Try different approaches to open the camera
    cap = None
    
    # Method 1: Try with CAP_ARAVIS backend explicitly
    for index in range(5):
        print(f"\nTrying index {index} with Aravis backend...")
        cap = cv2.VideoCapture(index, cv2.CAP_ARAVIS)
        if cap.isOpened():
            print(f"✓ Opened camera at index {index}")
            break
        cap.release()
    
    # Method 2: Try with default backend
    if not cap or not cap.isOpened():
        for index in range(5):
            print(f"\nTrying index {index} with default backend...")
            cap = cv2.VideoCapture(index)
            if cap.isOpened():
                print(f"✓ Opened camera at index {index}")
                break
            cap.release()
    
    if not cap or not cap.isOpened():
        print("\n✗ Could not open camera with OpenCV")
        print("\nSince arv-viewer-0.8 works, you can use that instead.")
        print("Or try installing OpenCV with Aravis support:")
        print("  brew install opencv --with-aravis")
        return
    
    # Get camera properties
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = cap.get(cv2.CAP_PROP_FPS)
    
    print(f"\nCamera opened successfully!")
    print(f"Resolution: {width}x{height}")
    print(f"FPS: {fps}")
    
    print("\nControls:")
    print("  q - Quit")
    print("  s - Save snapshot")
    print("  r - Start/Stop recording")
    print("  f - Toggle fullscreen")
    
    # Create window
    window_name = "GigE Camera"
    cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
    cv2.resizeWindow(window_name, min(width, 1280), min(height, 720))
    
    # Recording variables
    recording = False
    video_writer = None
    frame_count = 0
    start_time = time.time()
    
    try:
        while True:
            ret, frame = cap.read()
            
            if not ret:
                print("Failed to grab frame")
                continue
            
            # Calculate FPS
            frame_count += 1
            elapsed = time.time() - start_time
            if elapsed > 0:
                current_fps = frame_count / elapsed
            else:
                current_fps = 0
            
            # Create display frame
            display_frame = frame.copy()
            
            # Add overlays
            font = cv2.FONT_HERSHEY_SIMPLEX
            
            # FPS counter
            cv2.putText(display_frame, f"FPS: {current_fps:.1f}", (10, 30),
                       font, 0.7, (0, 255, 0), 2)
            
            # Recording indicator
            if recording:
                cv2.circle(display_frame, (width - 30, 30), 10, (0, 0, 255), -1)
                cv2.putText(display_frame, "REC", (width - 80, 35),
                           font, 0.7, (0, 0, 255), 2)
            
            # Timestamp
            timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            cv2.putText(display_frame, timestamp, (10, height - 10),
                       font, 0.5, (255, 255, 255), 1)
            
            # Show frame
            cv2.imshow(window_name, display_frame)
            
            # Write frame if recording
            if recording and video_writer:
                video_writer.write(frame)
            
            # Handle keyboard
            key = cv2.waitKey(1) & 0xFF
            
            if key == ord('q'):
                break
            elif key == ord('s'):
                # Save snapshot
                filename = recordings_dir / f"snapshot_{datetime.now().strftime('%Y%m%d_%H%M%S')}.png"
                cv2.imwrite(str(filename), frame)
                print(f"Saved snapshot: {filename}")
            elif key == ord('r'):
                # Toggle recording
                if not recording:
                    # Start recording
                    filename = recordings_dir / f"recording_{datetime.now().strftime('%Y%m%d_%H%M%S')}.mp4"
                    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
                    video_writer = cv2.VideoWriter(str(filename), fourcc, 20.0, (width, height))
                    recording = True
                    print(f"Started recording: {filename}")
                else:
                    # Stop recording
                    recording = False
                    if video_writer:
                        video_writer.release()
                        video_writer = None
                    print("Stopped recording")
            elif key == ord('f'):
                # Toggle fullscreen
                current = cv2.getWindowProperty(window_name, cv2.WND_PROP_FULLSCREEN)
                if current == cv2.WINDOW_NORMAL:
                    cv2.setWindowProperty(window_name, cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_FULLSCREEN)
                else:
                    cv2.setWindowProperty(window_name, cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_NORMAL)
    
    except KeyboardInterrupt:
        print("\nInterrupted by user")
    finally:
        # Cleanup
        if recording and video_writer:
            video_writer.release()
        cap.release()
        cv2.destroyAllWindows()
        print("Done!")


if __name__ == "__main__":
    main()