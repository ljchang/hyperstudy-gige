#!/usr/bin/env python3
"""
Connect to GigE camera using direct IP address
"""

import os
os.environ['GI_TYPELIB_PATH'] = '/opt/homebrew/lib/girepository-1.0'

import gi
gi.require_version('Aravis', '0.8')
from gi.repository import Aravis
import numpy as np
import cv2

def connect_by_ip(ip_address):
    """Connect to camera using IP address"""
    print(f"Attempting to connect to camera at {ip_address}")
    print("-" * 50)
    
    try:
        # Method 1: Direct device creation
        print("Method 1: Creating device directly from IP...")
        device = Aravis.GvDevice.new(ip_address, None)
        
        if device:
            print("✓ Device created successfully!")
            
            # Get device info
            try:
                vendor = device.get_string_feature_value("DeviceVendorName")
                model = device.get_string_feature_value("DeviceModelName")
                print(f"  Device: {vendor} {model}")
            except:
                print("  Could not read device info")
            
            # Create camera from device
            camera = Aravis.Camera.new_with_device(device)
            if camera:
                print("✓ Camera created from device!")
                return camera
            else:
                print("✗ Failed to create camera from device")
        else:
            print("✗ Failed to create device")
            
    except Exception as e:
        print(f"✗ Method 1 failed: {e}")
    
    try:
        # Method 2: Using camera ID with IP
        print("\nMethod 2: Using IP as camera ID...")
        camera = Aravis.Camera.new(f"GV:{ip_address}")
        
        if camera:
            print("✓ Camera created successfully!")
            return camera
        else:
            print("✗ Failed to create camera")
            
    except Exception as e:
        print(f"✗ Method 2 failed: {e}")
    
    try:
        # Method 3: Force discovery of specific IP
        print("\nMethod 3: Force discovery...")
        
        # This might help discover the camera
        Aravis.gv_discover_socket_list_new()
        
        # Update device list
        Aravis.update_device_list()
        
        # Check if camera appeared
        n_devices = Aravis.get_n_devices()
        print(f"  Found {n_devices} device(s) after forced discovery")
        
        for i in range(n_devices):
            device_id = Aravis.get_device_id(i)
            device_addr = Aravis.get_device_address(i)
            print(f"  Device {i}: {device_id} at {device_addr}")
            
            if device_addr == ip_address:
                print(f"  ✓ Found camera at {ip_address}!")
                camera = Aravis.Camera.new(device_id)
                if camera:
                    return camera
                    
    except Exception as e:
        print(f"✗ Method 3 failed: {e}")
    
    return None


def test_camera(camera):
    """Test camera functionality"""
    try:
        # Get camera info
        x, y, width, height = camera.get_region()
        print(f"\nCamera settings:")
        print(f"  Resolution: {width}x{height}")
        
        # Create stream
        stream = camera.create_stream()
        if not stream:
            print("✗ Failed to create stream")
            return
            
        # Push buffers
        payload = camera.get_payload()
        for i in range(5):
            stream.push_buffer(Aravis.Buffer.new(payload, None))
        
        # Start acquisition
        camera.start_acquisition()
        print("✓ Started acquisition")
        
        # Try to grab a frame
        print("\nGrabbing frame...")
        buffer = stream.timeout_pop_buffer(2000000)  # 2 second timeout
        
        if buffer and buffer.get_status() == Aravis.BufferStatus.SUCCESS:
            data = buffer.get_data()
            width = buffer.get_image_width()
            height = buffer.get_image_height()
            
            print(f"✓ Got frame: {width}x{height}")
            
            # Save frame
            image = np.frombuffer(data, dtype=np.uint8).reshape(height, width)
            if len(image.shape) == 2:
                image = cv2.cvtColor(image, cv2.COLOR_GRAY2BGR)
            
            cv2.imwrite("direct_ip_frame.png", image)
            print("✓ Saved frame to: direct_ip_frame.png")
            
            stream.push_buffer(buffer)
        else:
            print("✗ Failed to grab frame")
            if buffer:
                stream.push_buffer(buffer)
        
        camera.stop_acquisition()
        
    except Exception as e:
        print(f"Error during test: {e}")


def main():
    # Your camera's IP address
    camera_ip = "169.254.90.244"
    
    print("Direct IP Camera Connection Test")
    print("=" * 50)
    
    # Try to connect
    camera = connect_by_ip(camera_ip)
    
    if camera:
        print("\n✓ Successfully connected to camera!")
        test_camera(camera)
    else:
        print("\n✗ Failed to connect to camera")
        print("\nTroubleshooting:")
        print("1. Make sure the camera is powered on")
        print("2. Check if you can ping the camera:")
        print(f"   ping {camera_ip}")
        print("3. You might need to be on the same subnet:")
        print("   sudo ifconfig en0 alias 169.254.1.1 netmask 255.255.0.0")


if __name__ == "__main__":
    main()