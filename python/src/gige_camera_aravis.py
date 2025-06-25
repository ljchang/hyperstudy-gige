"""
GigE Camera Module using Aravis
Alternative implementation using Aravis for better compatibility
"""

import numpy as np
import logging
from typing import Optional, List, Tuple
import cv2

try:
    import gi
    gi.require_version('Aravis', '0.8')
    from gi.repository import Aravis
except ImportError:
    raise ImportError("Aravis GObject introspection not found. Install with: pip install PyGObject")

logger = logging.getLogger(__name__)


class GigECameraAravis:
    """Wrapper class for GigE Vision cameras using Aravis"""
    
    def __init__(self):
        """Initialize GigE camera interface using Aravis"""
        Aravis.enable_interface("Fake")  # Enable fake camera for testing
        self.camera = None
        self.stream = None
        self.is_acquiring = False
        
    def list_devices(self) -> List[dict]:
        """List all available GigE cameras"""
        Aravis.update_device_list()
        n_devices = Aravis.get_n_devices()
        
        devices = []
        for i in range(n_devices):
            device_id = Aravis.get_device_id(i)
            device_model = Aravis.get_device_model(i)
            device_vendor = Aravis.get_device_vendor(i)
            device_serial = Aravis.get_device_serial_nbr(i)
            device_address = Aravis.get_device_address(i)
            
            devices.append({
                'vendor': device_vendor or 'Unknown',
                'model': device_model or 'Unknown',
                'serial': device_serial or 'Unknown',
                'id': device_id,
                'address': device_address or 'Unknown',
                'index': i
            })
            
        return devices
    
    def connect(self, device_index: int = 0, ip_address: Optional[str] = None) -> bool:
        """
        Connect to a specific camera
        
        Args:
            device_index: Index of device in the device list
            ip_address: Direct IP address of camera (optional)
            
        Returns:
            True if connection successful
        """
        try:
            if ip_address:
                # Direct IP connection
                logger.info(f"Connecting directly to IP: {ip_address}")
                
                # Try method 1: Direct device creation
                try:
                    device = Aravis.GvDevice.new(ip_address, None)
                    if device:
                        self.camera = Aravis.Camera.new_with_device(device)
                except:
                    pass
                
                # Try method 2: Using GV: prefix
                if not self.camera:
                    try:
                        self.camera = Aravis.Camera.new(f"GV:{ip_address}")
                    except:
                        pass
                
                # Try method 3: Just IP as ID
                if not self.camera:
                    try:
                        self.camera = Aravis.Camera.new(ip_address)
                    except:
                        pass
            else:
                # Normal device list connection
                Aravis.update_device_list()
                n_devices = Aravis.get_n_devices()
                
                if n_devices == 0:
                    logger.error("No devices found")
                    return False
                    
                if device_index >= n_devices:
                    logger.error(f"Device index {device_index} out of range (found {n_devices} devices)")
                    return False
                
                # Get device ID and create camera
                device_id = Aravis.get_device_id(device_index)
                self.camera = Aravis.Camera.new(device_id)
            
            if not self.camera:
                logger.error(f"Failed to create camera for device {device_id}")
                return False
            
            # Get device info for logging
            device = self.camera.get_device()
            vendor = device.get_string_feature_value("DeviceVendorName")
            model = device.get_string_feature_value("DeviceModelName")
            
            logger.info(f"Connected to camera: {vendor} {model}")
            
            # Configure basic settings
            self._configure_camera()
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to connect to camera: {e}")
            return False
    
    def _configure_camera(self):
        """Configure camera settings"""
        if not self.camera:
            return
            
        try:
            device = self.camera.get_device()
            
            # Set pixel format to Mono8 if available
            pixel_formats = self.camera.dup_available_pixel_formats_as_strings()
            if pixel_formats:
                if "Mono8" in pixel_formats:
                    self.camera.set_pixel_format(Aravis.PIXEL_FORMAT_MONO_8)
                elif "BayerRG8" in pixel_formats:
                    self.camera.set_pixel_format(Aravis.PIXEL_FORMAT_BAYER_RG_8)
                    
            # Set acquisition mode to continuous
            self.camera.set_acquisition_mode(Aravis.AcquisitionMode.CONTINUOUS)
            
        except Exception as e:
            logger.warning(f"Failed to configure camera: {e}")
    
    def get_resolution(self) -> Tuple[int, int]:
        """Get current camera resolution (width, height)"""
        if not self.camera:
            return (0, 0)
            
        try:
            region = self.camera.get_region()
            return (region[2], region[3])  # width, height
        except:
            return (0, 0)
    
    def set_resolution(self, width: int, height: int) -> bool:
        """Set camera resolution"""
        if not self.camera:
            return False
            
        try:
            # Get current region
            x, y, _, _ = self.camera.get_region()
            
            # Set new resolution
            self.camera.set_region(x, y, width, height)
            
            return True
        except Exception as e:
            logger.error(f"Failed to set resolution: {e}")
            return False
    
    def get_frame_rate(self) -> float:
        """Get current frame rate"""
        if not self.camera:
            return 0.0
            
        try:
            return self.camera.get_frame_rate()
        except:
            return 0.0
    
    def set_frame_rate(self, fps: float) -> bool:
        """Set camera frame rate"""
        if not self.camera:
            return False
            
        try:
            self.camera.set_frame_rate(fps)
            return True
        except Exception as e:
            logger.error(f"Failed to set frame rate: {e}")
            return False
    
    def start_acquisition(self) -> bool:
        """Start image acquisition"""
        if not self.camera or self.is_acquiring:
            return False
            
        try:
            # Create stream
            self.stream = self.camera.create_stream()
            
            if not self.stream:
                logger.error("Failed to create stream")
                return False
            
            # Push some buffers
            payload = self.camera.get_payload()
            for i in range(10):
                self.stream.push_buffer(Aravis.Buffer.new(payload, None))
            
            # Start acquisition
            self.camera.start_acquisition()
            self.is_acquiring = True
            
            logger.info("Started image acquisition")
            return True
            
        except Exception as e:
            logger.error(f"Failed to start acquisition: {e}")
            return False
    
    def stop_acquisition(self):
        """Stop image acquisition"""
        if self.camera and self.is_acquiring:
            try:
                self.camera.stop_acquisition()
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
        if not self.stream or not self.is_acquiring:
            return None
            
        try:
            # Pull buffer from stream
            buffer = self.stream.timeout_pop_buffer(timeout_ms * 1000)  # Convert to microseconds
            
            if not buffer:
                return None
            
            # Get buffer data
            if buffer.get_status() == Aravis.BufferStatus.SUCCESS:
                # Get image data
                width = buffer.get_image_width()
                height = buffer.get_image_height()
                pixel_format = buffer.get_image_pixel_format()
                data = buffer.get_data()
                
                # Convert to numpy array
                if pixel_format == Aravis.PIXEL_FORMAT_MONO_8:
                    image = np.frombuffer(data, dtype=np.uint8).reshape(height, width)
                    # Convert to RGB for consistency
                    image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
                elif pixel_format == Aravis.PIXEL_FORMAT_BAYER_RG_8:
                    image = np.frombuffer(data, dtype=np.uint8).reshape(height, width)
                    # Convert Bayer to RGB
                    image = cv2.cvtColor(image, cv2.COLOR_BAYER_RG2RGB)
                elif pixel_format in [Aravis.PIXEL_FORMAT_RGB_8_PACKED, Aravis.PIXEL_FORMAT_BGR_8_PACKED]:
                    image = np.frombuffer(data, dtype=np.uint8).reshape(height, width, 3)
                else:
                    logger.warning(f"Unsupported pixel format: {pixel_format}")
                    self.stream.push_buffer(buffer)
                    return None
                
                # Push buffer back to stream
                self.stream.push_buffer(buffer)
                
                return image.copy()
            else:
                # Push buffer back even on failure
                self.stream.push_buffer(buffer)
                return None
                
        except Exception as e:
            logger.debug(f"Failed to grab frame: {e}")
            return None
    
    def disconnect(self):
        """Disconnect from camera and cleanup"""
        if self.is_acquiring:
            self.stop_acquisition()
            
        if self.stream:
            self.stream = None
            
        if self.camera:
            self.camera = None
            
        logger.info("Disconnected from camera")
    
    def __del__(self):
        """Cleanup on deletion"""
        self.disconnect()