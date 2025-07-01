#!/bin/bash

# Generate App Icons for macOS
# This script creates all required icon sizes from a 1024x1024 source image

SOURCE_ICON="$1"
OUTPUT_DIR="$2"

if [ -z "$SOURCE_ICON" ] || [ -z "$OUTPUT_DIR" ]; then
    echo "Usage: $0 <source_icon_1024x1024.png> <output_directory>"
    echo "Example: $0 icon.png ./Assets.xcassets/AppIcon.appiconset"
    exit 1
fi

if [ ! -f "$SOURCE_ICON" ]; then
    echo "Error: Source icon file not found: $SOURCE_ICON"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Function to create icon
create_icon() {
    local size=$1
    local scale=$2
    local output_size=$(($size * $scale))
    local filename=""
    
    if [ $scale -eq 1 ]; then
        filename="icon_${size}x${size}.png"
    else
        filename="icon_${size}x${size}@${scale}x.png"
    fi
    
    echo "Creating $filename (${output_size}x${output_size})"
    sips -z $output_size $output_size "$SOURCE_ICON" --out "$OUTPUT_DIR/$filename" >/dev/null 2>&1
}

# Generate all required sizes for macOS
# Format: size scale
create_icon 16 1
create_icon 16 2
create_icon 32 1
create_icon 32 2
create_icon 128 1
create_icon 128 2
create_icon 256 1
create_icon 256 2
create_icon 512 1
create_icon 512 2

echo "App icons generated successfully!"

# Create Contents.json for the appiconset
cat > "$OUTPUT_DIR/Contents.json" << EOF
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF

echo "Contents.json created successfully!"