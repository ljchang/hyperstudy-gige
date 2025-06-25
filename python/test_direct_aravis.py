#!/usr/bin/env python3
"""
Direct Aravis test with better error handling
"""

import os
os.environ['GI_TYPELIB_PATH'] = '/opt/homebrew/lib/girepository-1.0'

import gi
gi.require_version('Aravis', '0.8')
from gi.repository import Aravis, GLib
import numpy as np
import cv2

def main():
    print("Direct Aravis Camera Test")
    print("=" * 50)
    
    # Initialize Aravis
    Aravis.enable_interface("Fake")
    
    # Update device list
    Aravis.update_device_list()
    n_devices = Aravis.get_n_devices()
    
    print(f"Found {n_devices} device(s)")
    
    if n_devices == 0:
        print("No devices found!")
        return
    
    # Show device info
    for i in range(n_devices):
        print(f"\nDevice {i}:")
        print(f"  ID: {Aravis.get_device_id(i)}")
        print(f"  Physical ID: {Aravis.get_device_physical_id(i)}")
        print(f"  Address: {Aravis.get_device_address(i)}")
        print(f"  Vendor: {Aravis.get_device_vendor(i)}")
        print(f"  Model: {Aravis.get_device_model(i)}")
        print(f"  Serial: {Aravis.get_device_serial_nbr(i)}")
    
    # Try to connect to first real camera (not Fake)
    device_id = None
    for i in range(n_devices):
        if "Fake" not in str(Aravis.get_device_id(i)):
            device_id = Aravis.get_device_id(i)
            break
    
    if not device_id:
        print("\nNo real camera found (only Fake devices)")
        return
    
    print(f"\nConnecting to: {device_id}")
    
    try:
        # Create camera
        camera = Aravis.Camera.new(device_id)
        
        if not camera:
            print("Failed to create camera object")
            return
            
        print("✓ Camera created")
        
        # Get and print current settings
        pixel_format = camera.get_pixel_format_as_string()
        print(f"  Pixel format: {pixel_format}")
        
        x, y, width, height = camera.get_region()
        print(f"  Region: {width}x{height} at ({x},{y})")
        
        # Set frame rate if possible
        try:
            camera.set_frame_rate(10.0)
            print(f"  Frame rate: {camera.get_frame_rate()}")
        except:
            print("  Frame rate: (could not set)")
        
        # Create stream
        stream = camera.create_stream()
        if not stream:
            print("Failed to create stream")
            return
            
        print("✓ Stream created")
        
        # Set stream parameters
        stream.set_emit_signals(False)
        
        # Push buffers
        payload = camera.get_payload()
        print(f"  Payload size: {payload} bytes")
        
        for i in range(5):
            stream.push_buffer(Aravis.Buffer.new(payload, None))
        
        print("✓ Buffers allocated")
        
        # Start acquisition
        camera.start_acquisition()
        print("✓ Acquisition started")
        
        # Capture frames
        print("\nCapturing frames...")
        success_count = 0
        
        for i in range(10):
            buffer = stream.timeout_pop_buffer(1000000)  # 1 second timeout
            
            if buffer:
                status = buffer.get_status()
                if status == Aravis.BufferStatus.SUCCESS:
                    # Get frame data
                    data = buffer.get_data()
                    width = buffer.get_image_width()
                    height = buffer.get_image_height()
                    pixel_format = buffer.get_image_pixel_format()
                    
                    print(f"  Frame {i}: {width}x{height}, format: {pixel_format}")
                    
                    # Save first successful frame
                    if success_count == 0:
                        # Convert to numpy array
                        if pixel_format == Aravis.PIXEL_FORMAT_MONO_8:
                            image = np.frombuffer(data, dtype=np.uint8).reshape(height, width)
                            image = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
                        else:
                            # Assume it's some form of 8-bit data
                            image = np.frombuffer(data, dtype=np.uint8).reshape(height, width)
                            if len(image.shape) == 2:
                                image = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
                        
                        cv2.imwrite("aravis_frame.png", image)
                        print("  ✓ Saved first frame to aravis_frame.png")
                    
                    success_count += 1
                else:
                    print(f"  Frame {i}: Error - {status}")
                
                stream.push_buffer(buffer)
            else:
                print(f"  Frame {i}: Timeout")
        
        print(f"\n✓ Captured {success_count}/10 frames successfully")
        
        # Stop acquisition
        camera.stop_acquisition()
        print("✓ Acquisition stopped")
        
    except Exception as e:
        print(f"\nError: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    main()