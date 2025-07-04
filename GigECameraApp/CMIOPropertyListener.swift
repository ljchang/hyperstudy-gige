//
//  CMIOPropertyListener.swift
//  GigECameraApp
//
//  CMIO property listener for detecting sink stream availability
//

import Foundation
import CoreMediaIO
import os.log

// MARK: - Notifications

extension Notification.Name {
    // CMIO Stream Discovery Notifications
    static let cmioSinkStreamDiscovered = Notification.Name("CMIOSinkStreamDiscovered")
    static let cmioSinkStreamRemoved = Notification.Name("CMIOSinkStreamRemoved")
    static let cmioDeviceDiscovered = Notification.Name("CMIODeviceDiscovered")
    static let cmioDeviceRemoved = Notification.Name("CMIODeviceRemoved")
}

// MARK: - CMIO Property Listener

class CMIOPropertyListener {
    
    // MARK: - Types
    
    enum ListenerError: Error {
        case failedToAddListener
        case failedToRemoveListener
        case invalidDevice
        case invalidStream
    }
    
    struct StreamInfo {
        let streamID: CMIOStreamID
        let deviceID: CMIODeviceID
        let name: String
        let direction: CMIOExtensionStream.Direction
    }
    
    // MARK: - Properties
    
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera", category: "CMIOPropertyListener")
    
    // Callbacks
    var onSinkStreamDiscovered: ((StreamInfo) -> Void)?
    var onSinkStreamRemoved: ((CMIOStreamID) -> Void)?
    var onDeviceDiscovered: ((CMIODeviceID, String) -> Void)?
    var onDeviceRemoved: ((CMIODeviceID) -> Void)?
    
    // Listener state
    private var isListening = false
    private var deviceListeners: [CMIODeviceID: Bool] = [:]
    private var knownSinkStreams: Set<CMIOStreamID> = []
    
    // Target device info
    private let targetDeviceUID: String
    private var targetDeviceID: CMIODeviceID?
    
    // MARK: - Initialization
    
    init(targetDeviceUID: String) {
        self.targetDeviceUID = targetDeviceUID
        logger.info("CMIOPropertyListener initialized for device UID: \(targetDeviceUID)")
    }
    
    deinit {
        stopListening()
    }
    
    // MARK: - Public Interface
    
    func startListening() throws {
        guard !isListening else {
            logger.info("Already listening for CMIO property changes")
            return
        }
        
        logger.info("Starting CMIO property listeners...")
        
        // Register for device list changes
        try registerDeviceListListener()
        
        // Check for existing devices
        checkExistingDevices()
        
        isListening = true
        logger.info("CMIO property listeners started successfully")
    }
    
    func stopListening() {
        guard isListening else { return }
        
        logger.info("Stopping CMIO property listeners...")
        
        // Remove device list listener
        removeDeviceListListener()
        
        // Remove all device stream listeners
        for deviceID in deviceListeners.keys {
            removeStreamListListener(for: deviceID)
        }
        deviceListeners.removeAll()
        
        isListening = false
        logger.info("CMIO property listeners stopped")
    }
    
    // MARK: - Private Methods
    
    private func registerDeviceListListener() throws {
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        let result = CMIOObjectAddPropertyListener(
            CMIOObjectID(kCMIOObjectSystemObject),
            &property,
            deviceListChangedCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard result == kCMIOHardwareNoError else {
            logger.error("Failed to add device list listener: \(result)")
            throw ListenerError.failedToAddListener
        }
        
        logger.info("Successfully registered device list listener")
    }
    
    private func removeDeviceListListener() {
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        let result = CMIOObjectRemovePropertyListener(
            CMIOObjectID(kCMIOObjectSystemObject),
            &property,
            deviceListChangedCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )
        
        if result != kCMIOHardwareNoError {
            logger.error("Failed to remove device list listener: \(result)")
        }
    }
    
    private func registerStreamListListener(for deviceID: CMIODeviceID) throws {
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyStreams),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        let result = CMIOObjectAddPropertyListener(
            deviceID,
            &property,
            streamListChangedCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard result == kCMIOHardwareNoError else {
            logger.error("Failed to add stream list listener for device \(deviceID): \(result)")
            throw ListenerError.failedToAddListener
        }
        
        deviceListeners[deviceID] = true
        logger.info("Successfully registered stream list listener for device \(deviceID)")
    }
    
    private func removeStreamListListener(for deviceID: CMIODeviceID) {
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyStreams),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        let result = CMIOObjectRemovePropertyListener(
            deviceID,
            &property,
            streamListChangedCallback,
            Unmanaged.passUnretained(self).toOpaque()
        )
        
        if result != kCMIOHardwareNoError {
            logger.error("Failed to remove stream list listener for device \(deviceID): \(result)")
        }
    }
    
    private func checkExistingDevices() {
        logger.info("Checking for existing CMIO devices...")
        
        guard let devices = getAllDevices() else {
            logger.error("Failed to get device list")
            return
        }
        
        for deviceID in devices {
            if let uid = getDeviceUID(deviceID: deviceID) {
                logger.info("Found device: \(uid)")
                
                if uid == targetDeviceUID {
                    logger.info("Found target device with ID: \(deviceID)")
                    targetDeviceID = deviceID
                    onDeviceDiscovered?(deviceID, uid)
                    
                    // Post notification
                    NotificationCenter.default.post(
                        name: .cmioDeviceDiscovered,
                        object: nil,
                        userInfo: ["deviceID": deviceID, "uid": uid]
                    )
                    
                    // Register stream listener for this device
                    do {
                        try registerStreamListListener(for: deviceID)
                        // Check existing streams
                        checkExistingStreams(for: deviceID)
                    } catch {
                        logger.error("Failed to register stream listener: \(error)")
                    }
                }
            }
        }
    }
    
    private func checkExistingStreams(for deviceID: CMIODeviceID) {
        logger.info("Checking for existing streams on device \(deviceID)...")
        
        guard let streams = getStreamIDs(for: deviceID) else {
            logger.error("Failed to get stream list")
            return
        }
        
        for streamID in streams {
            checkStream(streamID, on: deviceID)
        }
    }
    
    private func checkStream(_ streamID: CMIOStreamID, on deviceID: CMIODeviceID) {
        // Get stream direction
        guard let direction = getStreamDirection(streamID: streamID) else {
            logger.error("Failed to get stream direction for stream \(streamID)")
            return
        }
        
        let name = getStreamName(streamID: streamID) ?? "Unknown"
        logger.info("Checking stream \(streamID): name='\(name)', direction=\(direction) (\(direction == 0 ? "sink" : "source"))")
        
        // We're interested in sink streams
        if direction == 0 { // Sink = 0, Source = 1
            logger.info("Found sink stream: \(name) (ID: \(streamID))")
            
            if !knownSinkStreams.contains(streamID) {
                knownSinkStreams.insert(streamID)
                
                let info = StreamInfo(
                    streamID: streamID,
                    deviceID: deviceID,
                    name: name,
                    direction: .sink
                )
                
                onSinkStreamDiscovered?(info)
                
                // Post notification
                NotificationCenter.default.post(
                    name: .cmioSinkStreamDiscovered,
                    object: nil,
                    userInfo: [
                        "streamID": streamID,
                        "deviceID": deviceID,
                        "name": name,
                        "streamInfo": info
                    ]
                )
            }
        }
    }
    
    // MARK: - Device List Changed Handler
    
    func handleDeviceListChanged() {
        logger.info("Device list changed")
        
        guard let devices = getAllDevices() else { return }
        
        // Check for new devices
        for deviceID in devices {
            if deviceListeners[deviceID] == nil {
                if let uid = getDeviceUID(deviceID: deviceID), uid == targetDeviceUID {
                    logger.info("Target device appeared: \(deviceID)")
                    targetDeviceID = deviceID
                    onDeviceDiscovered?(deviceID, uid)
                    
                    // Post notification
                    NotificationCenter.default.post(
                        name: .cmioDeviceDiscovered,
                        object: nil,
                        userInfo: ["deviceID": deviceID, "uid": uid]
                    )
                    
                    // Register stream listener
                    do {
                        try registerStreamListListener(for: deviceID)
                        checkExistingStreams(for: deviceID)
                    } catch {
                        logger.error("Failed to register stream listener: \(error)")
                    }
                }
            }
        }
        
        // Check for removed devices
        let currentDeviceIDs = Set(devices)
        for (deviceID, _) in deviceListeners {
            if !currentDeviceIDs.contains(deviceID) {
                logger.info("Device removed: \(deviceID)")
                removeStreamListListener(for: deviceID)
                deviceListeners.removeValue(forKey: deviceID)
                
                if deviceID == targetDeviceID {
                    targetDeviceID = nil
                    onDeviceRemoved?(deviceID)
                    
                    // Post notification
                    NotificationCenter.default.post(
                        name: .cmioDeviceRemoved,
                        object: nil,
                        userInfo: ["deviceID": deviceID]
                    )
                }
            }
        }
    }
    
    // MARK: - Stream List Changed Handler
    
    func handleStreamListChanged(for deviceID: CMIODeviceID) {
        logger.info("Stream list changed for device \(deviceID)")
        
        guard let streams = getStreamIDs(for: deviceID) else { return }
        
        // Remove unused variable
        // let currentStreamIDs = Set(streams)
        var currentSinkStreams = Set<CMIOStreamID>()
        
        // Check all streams
        for streamID in streams {
            if let direction = getStreamDirection(streamID: streamID), direction == 0 { // Sink
                currentSinkStreams.insert(streamID)
                
                if !knownSinkStreams.contains(streamID) {
                    // New sink stream discovered
                    let name = getStreamName(streamID: streamID) ?? "Unknown"
                    logger.info("New sink stream discovered: \(name) (ID: \(streamID))")
                    
                    knownSinkStreams.insert(streamID)
                    
                    let info = StreamInfo(
                        streamID: streamID,
                        deviceID: deviceID,
                        name: name,
                        direction: .sink
                    )
                    
                    onSinkStreamDiscovered?(info)
                    
                    // Post notification
                    NotificationCenter.default.post(
                        name: .cmioSinkStreamDiscovered,
                        object: nil,
                        userInfo: [
                            "streamID": streamID,
                            "deviceID": deviceID,
                            "name": name,
                            "streamInfo": info
                        ]
                    )
                }
            }
        }
        
        // Check for removed sink streams
        let removedStreams = knownSinkStreams.subtracting(currentSinkStreams)
        for streamID in removedStreams {
            logger.info("Sink stream removed: \(streamID)")
            knownSinkStreams.remove(streamID)
            onSinkStreamRemoved?(streamID)
            
            // Post notification
            NotificationCenter.default.post(
                name: .cmioSinkStreamRemoved,
                object: nil,
                userInfo: ["streamID": streamID]
            )
        }
    }
    
    // MARK: - CMIO Helper Methods
    
    private func getAllDevices() -> [CMIODeviceID]? {
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        
        // Get size
        var result = CMIOObjectGetPropertyDataSize(
            CMIOObjectID(kCMIOObjectSystemObject),
            &property,
            0,
            nil,
            &dataSize
        )
        
        guard result == kCMIOHardwareNoError else { return nil }
        
        let deviceCount = Int(dataSize) / MemoryLayout<CMIODeviceID>.size
        var deviceIDs = Array(repeating: CMIODeviceID(0), count: deviceCount)
        
        // Get devices
        result = CMIOObjectGetPropertyData(
            CMIOObjectID(kCMIOObjectSystemObject),
            &property,
            0,
            nil,
            dataSize,
            &dataUsed,
            &deviceIDs
        )
        
        guard result == kCMIOHardwareNoError else { return nil }
        
        return deviceIDs
    }
    
    private func getDeviceUID(deviceID: CMIODeviceID) -> String? {
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceUID),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        
        // Get size
        var result = CMIOObjectGetPropertyDataSize(deviceID, &property, 0, nil, &dataSize)
        guard result == kCMIOHardwareNoError else { return nil }
        
        // Get value
        let uidPtr = UnsafeMutablePointer<CFString?>.allocate(capacity: 1)
        defer { uidPtr.deallocate() }
        
        result = CMIOObjectGetPropertyData(deviceID, &property, 0, nil, dataSize, &dataUsed, uidPtr)
        guard result == kCMIOHardwareNoError, let uid = uidPtr.pointee else { return nil }
        
        return uid as String
    }
    
    private func getStreamIDs(for deviceID: CMIODeviceID) -> [CMIOStreamID]? {
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyStreams),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        
        // Get size
        var result = CMIOObjectGetPropertyDataSize(deviceID, &property, 0, nil, &dataSize)
        guard result == kCMIOHardwareNoError else { return nil }
        
        let streamCount = Int(dataSize) / MemoryLayout<CMIOStreamID>.size
        var streamIDs = Array(repeating: CMIOStreamID(0), count: streamCount)
        
        // Get streams
        result = CMIOObjectGetPropertyData(deviceID, &property, 0, nil, dataSize, &dataUsed, &streamIDs)
        guard result == kCMIOHardwareNoError else { return nil }
        
        return streamIDs
    }
    
    private func getStreamDirection(streamID: CMIOStreamID) -> UInt32? {
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOStreamPropertyDirection),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var direction: UInt32 = 0
        let dataSize = UInt32(MemoryLayout<UInt32>.size)
        var dataUsed: UInt32 = 0
        
        let result = CMIOObjectGetPropertyData(streamID, &property, 0, nil, dataSize, &dataUsed, &direction)
        guard result == kCMIOHardwareNoError else { return nil }
        
        return direction
    }
    
    private func getStreamName(streamID: CMIOStreamID) -> String? {
        // Try to get stream name
        var property = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOObjectPropertyName),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )
        
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        
        // Get size
        var result = CMIOObjectGetPropertyDataSize(streamID, &property, 0, nil, &dataSize)
        guard result == kCMIOHardwareNoError else { return nil }
        
        // Get value
        let namePtr = UnsafeMutablePointer<CFString?>.allocate(capacity: 1)
        defer { namePtr.deallocate() }
        
        result = CMIOObjectGetPropertyData(streamID, &property, 0, nil, dataSize, &dataUsed, namePtr)
        guard result == kCMIOHardwareNoError, let name = namePtr.pointee else { return nil }
        
        return name as String
    }
}

// MARK: - C Callbacks

private func deviceListChangedCallback(
    objectID: CMIOObjectID,
    numberAddresses: UInt32,
    addresses: UnsafePointer<CMIOObjectPropertyAddress>?,
    clientData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let clientData = clientData else { return OSStatus(kCMIOHardwareNoError) }
    
    let listener = Unmanaged<CMIOPropertyListener>.fromOpaque(clientData).takeUnretainedValue()
    
    // Handle on main queue to avoid threading issues
    DispatchQueue.main.async {
        listener.handleDeviceListChanged()
    }
    
    return OSStatus(kCMIOHardwareNoError)
}

private func streamListChangedCallback(
    objectID: CMIOObjectID,
    numberAddresses: UInt32,
    addresses: UnsafePointer<CMIOObjectPropertyAddress>?,
    clientData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let clientData = clientData else { return OSStatus(kCMIOHardwareNoError) }
    
    let listener = Unmanaged<CMIOPropertyListener>.fromOpaque(clientData).takeUnretainedValue()
    
    // The objectID is the deviceID in this case
    let deviceID = objectID
    
    // Handle on main queue
    DispatchQueue.main.async {
        listener.handleStreamListChanged(for: deviceID)
    }
    
    return OSStatus(kCMIOHardwareNoError)
}