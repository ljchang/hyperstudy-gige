#!/usr/bin/env python3
"""
List all available GigE cameras
"""

import sys
from pathlib import Path

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

from src.gige_camera import GigECamera


def main():
    print("Searching for GigE cameras...\n")
    
    # Create camera instance
    camera = GigECamera()
    
    # List all devices
    devices = camera.list_devices()
    
    if not devices:
        print("No GigE cameras found!")
        print("\nMake sure:")
        print("1. Your camera is connected and powered on")
        print("2. You have a GenTL producer installed")
        print("3. The producer path is correct")
        return
    
    print(f"Found {len(devices)} camera(s):\n")
    
    for i, device in enumerate(devices):
        print(f"Camera {i}:")
        print(f"  Vendor: {device['vendor']}")
        print(f"  Model: {device['model']}")
        print(f"  Serial: {device['serial']}")
        print(f"  ID: {device['id']}")
        print(f"  Transport: {device['tl_type']}")
        print()


if __name__ == "__main__":
    main()