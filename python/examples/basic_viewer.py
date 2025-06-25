#!/usr/bin/env python3
"""
Basic example of using the GigE camera viewer
"""

import sys
from pathlib import Path

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

from src.gige_viewer import GigEViewer


def main():
    # Create viewer instance
    # You can optionally specify the GenTL producer path
    # viewer = GigEViewer("/path/to/your/GenTLProducer.cti")
    viewer = GigEViewer()
    
    # Run the viewer (connects to first available camera)
    viewer.run(device_index=0)


if __name__ == "__main__":
    main()