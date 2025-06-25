#!/usr/bin/env python3
"""
Example of streaming GigE camera to LiveKit
"""

import asyncio
import sys
from pathlib import Path

# Add parent directory to path
sys.path.append(str(Path(__file__).parent.parent))

from src.gige_livekit_streamer import GigELiveKitStreamer


async def main():
    # Create streamer instance
    # You can specify a config file path
    # streamer = GigELiveKitStreamer("config/livekit.yaml")
    streamer = GigELiveKitStreamer()
    
    # Run the streamer
    await streamer.run()


if __name__ == "__main__":
    asyncio.run(main())