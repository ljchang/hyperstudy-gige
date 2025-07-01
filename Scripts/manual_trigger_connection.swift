#!/usr/bin/swift

import Foundation

// Send notification to trigger frame sender connection
let notification = NSNotification.Name("TriggerFrameSenderConnection")
DistributedNotificationCenter.default().post(name: notification, object: nil)

print("Sent trigger notification")

// Also try to trigger via AppleScript
let script = """
tell application "GigEVirtualCamera"
    activate
end tell
"""

var error: NSDictionary?
if let scriptObject = NSAppleScript(source: script) {
    scriptObject.executeAndReturnError(&error)
    if let error = error {
        print("AppleScript error: \(error)")
    } else {
        print("Activated GigEVirtualCamera")
    }
}