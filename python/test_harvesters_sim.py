#!/usr/bin/env python3
"""
Test Harvesters with simulator GenTL
"""

import sys
from pathlib import Path
sys.path.append(str(Path(__file__).parent))

from harvesters.core import Harvester
import numpy as np
import cv2

def main():
    print("Testing Harvesters with Simulator GenTL...")
    print("-" * 50)
    
    h = Harvester()
    
    # Add the simulator GenTL we found
    sim_cti = "/opt/anaconda3/lib/python3.11/site-packages/genicam/TLSimu.cti"
    print(f"Adding GenTL producer: {sim_cti}")
    
    try:
        h.add_file(sim_cti)
        print("✓ Successfully added GenTL producer")
    except Exception as e:
        print(f"✗ Failed to add GenTL producer: {e}")
        return
    
    # Update device list
    h.update()
    print(f"\nFound {len(h.device_info_list)} device(s)")
    
    # List devices
    for i, info in enumerate(h.device_info_list):
        print(f"\nDevice {i}:")
        print(f"  Vendor: {info.vendor}")
        print(f"  Model: {info.model}")
        print(f"  TL Type: {info.tl_type}")
        print(f"  ID: {info.id_}")
    
    if len(h.device_info_list) > 0:
        print("\nTrying to connect to first device...")
        
        try:
            ia = h.create(0)
            print("✓ Connected successfully!")
            
            # Start acquisition
            ia.start()
            print("✓ Started acquisition")
            
            # Grab a frame
            with ia.fetch() as buffer:
                component = buffer.payload.components[0]
                print(f"✓ Got frame: {component.width}x{component.height}")
                
                # Convert to image
                image = component.data.reshape(component.height, component.width)
                if len(image.shape) == 2:
                    image = cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
                
                cv2.imwrite("harvesters_test_frame.png", image)
                print("✓ Saved test frame to: harvesters_test_frame.png")
            
            ia.stop()
            ia.destroy()
            print("\n✓ Harvesters is working correctly!")
            
        except Exception as e:
            print(f"✗ Error during acquisition: {e}")
    
    h.reset()

if __name__ == "__main__":
    main()