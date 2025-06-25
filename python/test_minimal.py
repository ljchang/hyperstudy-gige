#!/usr/bin/env python3
"""
Minimal test to isolate segfault issue
"""

print("Starting minimal test...")

try:
    print("1. Importing libraries...")
    import gi
    gi.require_version('Aravis', '0.8')
    from gi.repository import Aravis
    print("   ✓ Imports successful")
    
    print("\n2. Updating device list...")
    Aravis.update_device_list()
    n = Aravis.get_n_devices()
    print(f"   ✓ Found {n} devices")
    
    if n > 0:
        print("\n3. Getting device info...")
        device_id = Aravis.get_device_id(0)
        print(f"   Device ID: {device_id}")
        
        print("\n4. Creating camera...")
        camera = Aravis.Camera.new(device_id)
        if camera:
            print("   ✓ Camera created")
            
            print("\n5. Getting camera properties...")
            try:
                region = camera.get_region()
                print(f"   Region: {region}")
            except Exception as e:
                print(f"   Error getting region: {e}")
            
            print("\n6. Testing complete!")
        else:
            print("   ✗ Failed to create camera")
    
except Exception as e:
    print(f"\nError: {e}")
    import traceback
    traceback.print_exc()

print("\nDone!")