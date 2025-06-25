"""
GigE Camera Module using Harvesters
Provides a common interface for GigE Vision cameras
"""

import numpy as np
from harvesters.core import Harvester
import logging
from typing import Optional, List, Tuple
import cv2

logger = logging.getLogger(__name__)


class GigECamera:
    """Wrapper class for GigE Vision cameras using Harvesters"""
    
    def __init__(self, gentl_producer_path: Optional[str] = None):
        """
        Initialize GigE camera interface
        
        Args:
            gentl_producer_path: Path to GenTL producer CTI file
                                If None, will try to auto-detect
        """
        self.harvester = Harvester()
        self.ia = None  # Image acquirer
        self.is_acquiring = False
        
        # Add GenTL producer
        if gentl_producer_path:
            self.harvester.add_file(gentl_producer_path)
        else:
            # Try to find producers automatically
            self._auto_detect_producers()
            
        # Update device list
        self.harvester.update()
        
    def _auto_detect_producers(self):
        """Try to automatically detect GenTL producers"""
        # Common GenTL producer locations
        common_paths = [
            # Matrix Vision
            "/opt/mvIMPACT_Acquire/lib/x86_64/mvGenTLProducer.cti",
            # Basler
            "/opt/pylon/lib/gentlproducer/gtl/ProducerPylon.cti",
            # Allied Vision
            "/usr/lib/gentl/producer/Vimba_gentl.cti",
        ]
        
        import os
        for path in common_paths:
            if os.path.exists(path):
                try:
                    self.harvester.add_file(path)
                    logger.info(f"Added GenTL producer: {path}")
                except Exception as e:
                    logger.warning(f"Failed to add producer {path}: {e}")
    
    def list_devices(self) -> List[dict]:
        """List all available GigE cameras"""
        devices = []
        for device in self.harvester.device_info_list:
            devices.append({
                'vendor': device.vendor,
                'model': device.model,
                'serial': device.serial_number,
                'id': device.id_,
                'tl_type': device.tl_type
            })
        return devices
    
    def connect(self, device_index: int = 0) -> bool:
        """
        Connect to a specific camera
        
        Args:
            device_index: Index of device in the device list
            
        Returns:
            True if connection successful
        """
        try:
            if len(self.harvester.device_info_list) == 0:
                logger.error("No devices found")
                return False
                
            # Create image acquirer
            self.ia = self.harvester.create(device_index)
            
            # Configure basic settings
            self._configure_camera()
            
            logger.info(f"Connected to camera: {self.harvester.device_info_list[device_index].model}")
            return True
            
        except Exception as e:
            logger.error(f"Failed to connect to camera: {e}")
            return False
    
    def _configure_camera(self):
        """Configure camera settings"""
        if not self.ia:
            return
            
        try:
            # Access remote device node map
            node_map = self.ia.remote_device.node_map
            
            # Set pixel format to Mono8 or BayerRG8 if available
            pixel_format = node_map.PixelFormat
            if 'Mono8' in pixel_format.symbolics:
                pixel_format.value = 'Mono8'
            elif 'BayerRG8' in pixel_format.symbolics:
                pixel_format.value = 'BayerRG8'
                
            # Set acquisition mode
            if hasattr(node_map, 'AcquisitionMode'):
                node_map.AcquisitionMode.value = 'Continuous'
                
        except Exception as e:
            logger.warning(f"Failed to configure camera: {e}")
    
    def get_resolution(self) -> Tuple[int, int]:
        """Get current camera resolution (width, height)"""
        if not self.ia:
            return (0, 0)
            
        try:
            node_map = self.ia.remote_device.node_map
            width = node_map.Width.value
            height = node_map.Height.value
            return (width, height)
        except:
            return (0, 0)
    
    def set_resolution(self, width: int, height: int) -> bool:
        """Set camera resolution"""
        if not self.ia:
            return False
            
        try:
            node_map = self.ia.remote_device.node_map
            
            # Stop acquisition if running
            was_acquiring = self.is_acquiring
            if was_acquiring:
                self.stop_acquisition()
                
            # Set resolution
            node_map.Width.value = width
            node_map.Height.value = height
            
            # Resume acquisition if it was running
            if was_acquiring:
                self.start_acquisition()
                
            return True
        except Exception as e:
            logger.error(f"Failed to set resolution: {e}")
            return False
    
    def get_frame_rate(self) -> float:
        """Get current frame rate"""
        if not self.ia:
            return 0.0
            
        try:
            node_map = self.ia.remote_device.node_map
            if hasattr(node_map, 'AcquisitionFrameRate'):
                return float(node_map.AcquisitionFrameRate.value)
            return 0.0
        except:
            return 0.0
    
    def set_frame_rate(self, fps: float) -> bool:
        """Set camera frame rate"""
        if not self.ia:
            return False
            
        try:
            node_map = self.ia.remote_device.node_map
            
            # Enable frame rate control
            if hasattr(node_map, 'AcquisitionFrameRateEnable'):
                node_map.AcquisitionFrameRateEnable.value = True
                
            # Set frame rate
            if hasattr(node_map, 'AcquisitionFrameRate'):
                node_map.AcquisitionFrameRate.value = fps
                
            return True
        except Exception as e:
            logger.error(f"Failed to set frame rate: {e}")
            return False
    
    def start_acquisition(self) -> bool:
        """Start image acquisition"""
        if not self.ia or self.is_acquiring:
            return False
            
        try:
            self.ia.start()
            self.is_acquiring = True
            logger.info("Started image acquisition")
            return True
        except Exception as e:
            logger.error(f"Failed to start acquisition: {e}")
            return False
    
    def stop_acquisition(self):
        """Stop image acquisition"""
        if self.ia and self.is_acquiring:
            try:
                self.ia.stop()
                self.is_acquiring = False
                logger.info("Stopped image acquisition")
            except Exception as e:
                logger.error(f"Failed to stop acquisition: {e}")
    
    def grab_frame(self, timeout_ms: int = 1000) -> Optional[np.ndarray]:
        """
        Grab a single frame from the camera
        
        Args:
            timeout_ms: Timeout in milliseconds
            
        Returns:
            Numpy array containing the image or None if failed
        """
        if not self.ia or not self.is_acquiring:
            return None
            
        try:
            # Fetch buffer
            with self.ia.fetch(timeout=timeout_ms/1000.0) as buffer:
                # Get component data
                component = buffer.payload.components[0]
                
                # Convert to numpy array
                image = component.data.reshape(component.height, component.width)
                
                # Handle Bayer pattern if necessary
                if component.data_format == 'BayerRG8':
                    # Convert Bayer to RGB
                    image = cv2.cvtColor(image, cv2.COLOR_BAYER_RG2RGB)
                elif len(image.shape) == 2:
                    # Convert grayscale to RGB for consistency
                    image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
                    
                return image.copy()
                
        except Exception as e:
            logger.debug(f"Failed to grab frame: {e}")
            return None
    
    def disconnect(self):
        """Disconnect from camera and cleanup"""
        if self.is_acquiring:
            self.stop_acquisition()
            
        if self.ia:
            self.ia.destroy()
            self.ia = None
            
        # Reset harvester
        self.harvester.reset()
        logger.info("Disconnected from camera")
    
    def __del__(self):
        """Cleanup on deletion"""
        self.disconnect()