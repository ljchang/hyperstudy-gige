#!/usr/bin/env python3
"""
Debug script to test camera connection step by step
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

import gi
gi.require_version('Aravis', '0.8')
from gi.repository import Aravis

def main():
    print("Aravis Debug Test")
    print("=" * 50)
    
    # Update device list
    print("Updating device list...")
    Aravis.update_device_list()
    
    # Get number of devices
    n_devices = Aravis.get_n_devices()
    print(f"Found {n_devices} device(s)")
    
    if n_devices == 0:
        print("No devices found!")
        return
    
    # List devices
    for i in range(n_devices):
        print(f"\nDevice {i}:")
        print(f"  ID: {Aravis.get_device_id(i)}")
        print(f"  Model: {Aravis.get_device_model(i)}")
        print(f"  Vendor: {Aravis.get_device_vendor(i)}")
        print(f"  Serial: {Aravis.get_device_serial_nbr(i)}")
        print(f"  Address: {Aravis.get_device_address(i)}")
    
    # Try to connect
    print("\n" + "=" * 50)
    print("Attempting to connect to device 0...")
    
    device_id = Aravis.get_device_id(0)
    camera = Aravis.Camera.new(device_id)
    
    if camera:
        print("✓ Camera created successfully!")
        
        # Get device
        device = camera.get_device()
        if device:
            print("✓ Got device handle")
            
            # Try to get some features
            try:
                vendor = device.get_string_feature_value("DeviceVendorName")
                model = device.get_string_feature_value("DeviceModelName")
                print(f"  Connected to: {vendor} {model}")
            except:
                print("  Could not read device features")
        
        # Get region
        try:
            region = camera.get_region()
            print(f"  Current region: x={region[0]}, y={region[1]}, width={region[2]}, height={region[3]}")
        except Exception as e:
            print(f"  Could not get region: {e}")
        
        # Get pixel formats
        try:
            formats = camera.dup_available_pixel_formats_as_strings()
            print(f"  Available pixel formats: {formats}")
        except Exception as e:
            print(f"  Could not get pixel formats: {e}")
            
    else:
        print("✗ Failed to create camera!")

if __name__ == "__main__":
    main()