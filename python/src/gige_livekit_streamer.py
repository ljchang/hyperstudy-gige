"""
GigE Camera to LiveKit WebRTC Streamer
Stream GigE camera feed to LiveKit room
"""

import asyncio
import cv2
import numpy as np
import logging
import sys
from pathlib import Path
from typing import Optional
import os
from dotenv import load_dotenv
import yaml

from livekit import rtc

# Add parent directory to path for imports
sys.path.append(str(Path(__file__).parent.parent))

from src.gige_camera import GigECamera

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class GigELiveKitStreamer:
    """Stream GigE camera to LiveKit WebRTC"""
    
    def __init__(self, config_path: Optional[str] = None):
        """
        Initialize streamer
        
        Args:
            config_path: Path to configuration file
        """
        self.camera = None
        self.room = None
        self.video_source = None
        self.video_track = None
        self.is_streaming = False
        
        # Load configuration
        self.config = self._load_config(config_path)
        
    def _load_config(self, config_path: Optional[str] = None) -> dict:
        """Load configuration from file or environment"""
        config = {
            'livekit': {
                'url': os.getenv('LIVEKIT_URL', 'ws://localhost:7880'),
                'api_key': os.getenv('LIVEKIT_API_KEY', ''),
                'api_secret': os.getenv('LIVEKIT_API_SECRET', ''),
                'room_name': os.getenv('LIVEKIT_ROOM_NAME', 'gige-camera-room'),
                'participant_name': os.getenv('LIVEKIT_PARTICIPANT_NAME', 'gige-camera')
            },
            'camera': {
                'width': 1280,
                'height': 720,
                'fps': 30,
                'device_index': 0,
                'gentl_producer': os.getenv('GENTL_PRODUCER_PATH', None)
            }
        }
        
        # Load from config file if provided
        if config_path and os.path.exists(config_path):
            with open(config_path, 'r') as f:
                file_config = yaml.safe_load(f)
                # Merge configurations
                for key in file_config:
                    if key in config:
                        config[key].update(file_config[key])
                    else:
                        config[key] = file_config[key]
        
        return config
    
    async def connect_camera(self) -> bool:
        """Connect to GigE camera"""
        try:
            # Initialize camera
            self.camera = GigECamera(self.config['camera'].get('gentl_producer'))
            
            # List devices
            devices = self.camera.list_devices()
            if not devices:
                logger.error("No GigE cameras found!")
                return False
            
            logger.info(f"Found {len(devices)} camera(s)")
            
            # Connect to camera
            device_index = self.config['camera'].get('device_index', 0)
            if not self.camera.connect(device_index):
                logger.error("Failed to connect to camera")
                return False
            
            # Configure camera
            width = self.config['camera']['width']
            height = self.config['camera']['height']
            fps = self.config['camera']['fps']
            
            self.camera.set_resolution(width, height)
            self.camera.set_frame_rate(fps)
            
            # Start acquisition
            if not self.camera.start_acquisition():
                logger.error("Failed to start acquisition")
                return False
            
            logger.info(f"Camera connected: {width}x{height} @ {fps} FPS")
            return True
            
        except Exception as e:
            logger.error(f"Camera connection error: {e}")
            return False
    
    async def connect_livekit(self) -> bool:
        """Connect to LiveKit room"""
        try:
            # Create room
            self.room = rtc.Room()
            
            # Generate token if needed
            token = await self._get_access_token()
            
            # Connect to room
            await self.room.connect(
                self.config['livekit']['url'],
                token
            )
            
            logger.info(f"Connected to LiveKit room: {self.config['livekit']['room_name']}")
            return True
            
        except Exception as e:
            logger.error(f"LiveKit connection error: {e}")
            return False
    
    async def _get_access_token(self) -> str:
        """Generate or retrieve LiveKit access token"""
        # If token is provided in config, use it
        if 'token' in self.config['livekit']:
            return self.config['livekit']['token']
        
        # Otherwise, generate token using API key/secret
        from livekit import api
        
        token = api.AccessToken(
            self.config['livekit']['api_key'],
            self.config['livekit']['api_secret']
        )
        
        token.with_identity(self.config['livekit']['participant_name'])
        token.with_name(self.config['livekit']['participant_name'])
        token.with_grants(
            api.VideoGrants(
                room_join=True,
                room=self.config['livekit']['room_name'],
                can_publish=True,
                can_subscribe=True
            )
        )
        
        return token.to_jwt()
    
    async def start_streaming(self):
        """Start streaming camera to LiveKit"""
        try:
            # Create video source and track
            width = self.config['camera']['width']
            height = self.config['camera']['height']
            
            self.video_source = rtc.VideoSource(width, height)
            self.video_track = rtc.LocalVideoTrack.create_video_track(
                "gige-camera",
                self.video_source
            )
            
            # Publish track
            options = rtc.TrackPublishOptions()
            options.source = rtc.TrackSource.SOURCE_CAMERA
            
            publication = await self.room.local_participant.publish_track(
                self.video_track,
                options
            )
            
            self.is_streaming = True
            logger.info("Started streaming to LiveKit")
            
            # Start frame capture task
            await self._capture_frames()
            
        except Exception as e:
            logger.error(f"Streaming error: {e}")
            self.is_streaming = False
    
    async def _capture_frames(self):
        """Capture frames from camera and send to LiveKit"""
        fps = self.config['camera']['fps']
        frame_interval = 1.0 / fps
        
        while self.is_streaming:
            try:
                # Grab frame from camera
                frame = self.camera.grab_frame()
                if frame is None:
                    await asyncio.sleep(0.001)
                    continue
                
                # Ensure frame is in RGB format
                if len(frame.shape) == 2:
                    frame = cv2.cvtColor(frame, cv2.COLOR_GRAY2RGB)
                
                # Convert to RGBA for LiveKit
                rgba_frame = cv2.cvtColor(frame, cv2.COLOR_RGB2RGBA)
                
                # Create VideoFrame
                frame_data = rgba_frame.tobytes()
                video_frame = rtc.VideoFrame(
                    self.config['camera']['width'],
                    self.config['camera']['height'],
                    rtc.VideoBufferType.RGBA,
                    frame_data
                )
                
                # Send frame to LiveKit
                self.video_source.capture_frame(video_frame)
                
                # Control frame rate
                await asyncio.sleep(frame_interval)
                
            except Exception as e:
                logger.error(f"Frame capture error: {e}")
                await asyncio.sleep(0.1)
    
    async def stop_streaming(self):
        """Stop streaming"""
        self.is_streaming = False
        
        # Unpublish track
        if self.video_track:
            await self.room.local_participant.unpublish_track(self.video_track.sid)
        
        logger.info("Stopped streaming")
    
    async def disconnect(self):
        """Disconnect from camera and LiveKit"""
        # Stop streaming
        if self.is_streaming:
            await self.stop_streaming()
        
        # Disconnect from LiveKit
        if self.room:
            await self.room.disconnect()
            self.room = None
        
        # Disconnect camera
        if self.camera:
            self.camera.disconnect()
            self.camera = None
        
        logger.info("Disconnected")
    
    async def run(self):
        """Main run loop"""
        try:
            # Connect to camera
            if not await self.connect_camera():
                return
            
            # Connect to LiveKit
            if not await self.connect_livekit():
                self.camera.disconnect()
                return
            
            # Start streaming
            await self.start_streaming()
            
        except KeyboardInterrupt:
            logger.info("Interrupted by user")
        except Exception as e:
            logger.error(f"Runtime error: {e}")
        finally:
            await self.disconnect()


async def main():
    """Main entry point"""
    import argparse
    
    # Load environment variables
    load_dotenv()
    
    parser = argparse.ArgumentParser(description="GigE Camera LiveKit Streamer")
    parser.add_argument(
        "--config",
        type=str,
        help="Path to configuration file"
    )
    
    args = parser.parse_args()
    
    # Create and run streamer
    streamer = GigELiveKitStreamer(args.config)
    await streamer.run()


if __name__ == "__main__":
    asyncio.run(main())