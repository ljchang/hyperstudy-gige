"""
GigE Camera Viewer with Recording Capabilities
View live feed from GigE camera and record video/snapshots
"""

import cv2
import numpy as np
import logging
import time
from datetime import datetime
import os
import sys
from pathlib import Path
from typing import Optional

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

from src.gige_camera import GigECamera

# Try to import Aravis backend
try:
    from src.gige_camera_aravis import GigECameraAravis
    ARAVIS_AVAILABLE = True
except ImportError:
    ARAVIS_AVAILABLE = False

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class GigEViewer:
    """Viewer application for GigE cameras with recording capabilities"""
    
    def __init__(self, gentl_producer_path: Optional[str] = None, use_aravis: bool = False):
        """Initialize viewer with optional GenTL producer path"""
        if use_aravis and ARAVIS_AVAILABLE:
            logger.info("Using Aravis backend")
            self.camera = GigECameraAravis()
        else:
            if use_aravis and not ARAVIS_AVAILABLE:
                logger.warning("Aravis backend requested but not available, falling back to Harvesters")
            self.camera = GigECamera(gentl_producer_path)
        self.recording = False
        self.video_writer = None
        self.recording_start_time = None
        self.fps_counter = FPSCounter()
        
        # Recording settings
        self.output_dir = Path(__file__).parent.parent / "recordings"
        self.output_dir.mkdir(exist_ok=True)
        
    def run(self, device_index: int = 0):
        """Main viewer loop"""
        # List available devices
        devices = self.camera.list_devices()
        if not devices:
            logger.error("No GigE cameras found!")
            logger.info("Make sure your camera is connected and GenTL producer is properly installed")
            return
            
        logger.info(f"Found {len(devices)} camera(s):")
        for i, device in enumerate(devices):
            logger.info(f"  [{i}] {device['vendor']} {device['model']} (Serial: {device['serial']})")
        
        # Connect to camera
        if not self.camera.connect(device_index):
            logger.error("Failed to connect to camera")
            return
            
        # Get camera info
        width, height = self.camera.get_resolution()
        fps = self.camera.get_frame_rate()
        logger.info(f"Camera resolution: {width}x{height} @ {fps:.1f} FPS")
        
        # Start acquisition
        if not self.camera.start_acquisition():
            logger.error("Failed to start acquisition")
            self.camera.disconnect()
            return
            
        # Create window
        window_name = "GigE Camera Viewer"
        cv2.namedWindow(window_name, cv2.WINDOW_NORMAL)
        cv2.resizeWindow(window_name, 1280, 720)
        
        logger.info("\nControls:")
        logger.info("  q - Quit")
        logger.info("  r - Start/Stop Recording")
        logger.info("  s - Save Snapshot")
        logger.info("  f - Toggle Fullscreen")
        
        try:
            while True:
                # Grab frame
                frame = self.camera.grab_frame()
                if frame is None:
                    continue
                    
                # Update FPS counter
                fps_actual = self.fps_counter.update()
                
                # Add overlay information
                display_frame = self._add_overlay(frame, fps_actual)
                
                # Display frame
                cv2.imshow(window_name, display_frame)
                
                # Handle recording
                if self.recording and self.video_writer:
                    self.video_writer.write(frame)
                
                # Handle keyboard input
                key = cv2.waitKey(1) & 0xFF
                
                if key == ord('q'):
                    break
                elif key == ord('r'):
                    self._toggle_recording(width, height, fps)
                elif key == ord('s'):
                    self._save_snapshot(frame)
                elif key == ord('f'):
                    self._toggle_fullscreen(window_name)
                    
        except KeyboardInterrupt:
            logger.info("\nInterrupted by user")
        finally:
            # Cleanup
            if self.recording:
                self._stop_recording()
            cv2.destroyAllWindows()
            self.camera.disconnect()
    
    def _add_overlay(self, frame: np.ndarray, fps: float) -> np.ndarray:
        """Add overlay information to frame"""
        overlay_frame = frame.copy()
        
        # Text settings
        font = cv2.FONT_HERSHEY_SIMPLEX
        font_scale = 0.7
        thickness = 2
        
        # FPS counter
        fps_text = f"FPS: {fps:.1f}"
        cv2.putText(overlay_frame, fps_text, (10, 30), font, font_scale, 
                   (0, 255, 0), thickness)
        
        # Recording indicator
        if self.recording:
            # Red recording dot
            cv2.circle(overlay_frame, (frame.shape[1] - 30, 30), 10, (0, 0, 255), -1)
            
            # Recording time
            if self.recording_start_time:
                duration = time.time() - self.recording_start_time
                time_text = f"REC {int(duration//60):02d}:{int(duration%60):02d}"
                cv2.putText(overlay_frame, time_text, (frame.shape[1] - 150, 35), 
                           font, font_scale, (0, 0, 255), thickness)
        
        # Timestamp
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        cv2.putText(overlay_frame, timestamp, (10, frame.shape[0] - 10), 
                   font, font_scale * 0.7, (255, 255, 255), 1)
        
        return overlay_frame
    
    def _toggle_recording(self, width: int, height: int, fps: float):
        """Toggle video recording"""
        if not self.recording:
            self._start_recording(width, height, fps)
        else:
            self._stop_recording()
    
    def _start_recording(self, width: int, height: int, fps: float):
        """Start recording video"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = self.output_dir / f"recording_{timestamp}.mp4"
        
        # Use H264 codec if available, fallback to MJPEG
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        
        self.video_writer = cv2.VideoWriter(
            str(filename), fourcc, fps, (width, height)
        )
        
        if self.video_writer.isOpened():
            self.recording = True
            self.recording_start_time = time.time()
            logger.info(f"Started recording: {filename}")
        else:
            logger.error("Failed to start recording")
            self.video_writer = None
    
    def _stop_recording(self):
        """Stop recording video"""
        if self.video_writer:
            self.video_writer.release()
            self.video_writer = None
            
        self.recording = False
        self.recording_start_time = None
        logger.info("Stopped recording")
    
    def _save_snapshot(self, frame: np.ndarray):
        """Save current frame as image"""
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = self.output_dir / f"snapshot_{timestamp}.png"
        
        cv2.imwrite(str(filename), frame)
        logger.info(f"Saved snapshot: {filename}")
    
    def _toggle_fullscreen(self, window_name: str):
        """Toggle fullscreen mode"""
        current = cv2.getWindowProperty(window_name, cv2.WND_PROP_FULLSCREEN)
        if current == cv2.WINDOW_NORMAL:
            cv2.setWindowProperty(window_name, cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_FULLSCREEN)
        else:
            cv2.setWindowProperty(window_name, cv2.WND_PROP_FULLSCREEN, cv2.WINDOW_NORMAL)


class FPSCounter:
    """Simple FPS counter using moving average"""
    
    def __init__(self, window_size: int = 30):
        self.window_size = window_size
        self.timestamps = []
        
    def update(self) -> float:
        """Update counter and return current FPS"""
        now = time.time()
        self.timestamps.append(now)
        
        # Keep only recent timestamps
        self.timestamps = [t for t in self.timestamps if now - t < 1.0]
        
        # Calculate FPS
        if len(self.timestamps) > 1:
            return len(self.timestamps) / (self.timestamps[-1] - self.timestamps[0])
        return 0.0


def main():
    """Main entry point"""
    import argparse
    
    parser = argparse.ArgumentParser(description="GigE Camera Viewer")
    parser.add_argument(
        "--producer", 
        type=str,
        help="Path to GenTL producer CTI file"
    )
    parser.add_argument(
        "--device", 
        type=int, 
        default=0,
        help="Device index to connect to (default: 0)"
    )
    parser.add_argument(
        "--aravis",
        action="store_true",
        help="Use Aravis backend instead of Harvesters"
    )
    
    args = parser.parse_args()
    
    # Create and run viewer
    viewer = GigEViewer(args.producer, use_aravis=args.aravis)
    viewer.run(args.device)


if __name__ == "__main__":
    main()