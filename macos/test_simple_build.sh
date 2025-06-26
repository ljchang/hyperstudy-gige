#!/bin/bash

echo "Testing Simple Build Without Extension"
echo "======================================"

# Create a minimal test app
cat > /tmp/test_app.swift << 'EOF'
import SwiftUI

@main
struct TestApp: App {
    var body: some Scene {
        WindowGroup {
            Text("GigE Camera Test")
                .padding()
        }
    }
}
EOF

# Compile it
echo "Compiling test app..."
swiftc /tmp/test_app.swift -o /tmp/test_app -framework SwiftUI -target arm64-apple-macos12.0

if [ -f /tmp/test_app ]; then
    echo "✅ Swift compilation works!"
    echo ""
    echo "The issue is with the Xcode project configuration."
    echo "Please use Xcode UI to set up automatic signing."
else
    echo "❌ Swift compilation failed"
fi