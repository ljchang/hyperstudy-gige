

# **A Developer's Guide to Building a macOS Virtual Camera with CMIO Extensions**

This report provides an exhaustive, expert-level guide to developing a virtual camera for macOS using the modern Core Media I/O (CMIO) Camera Extension framework. It addresses the specific challenge of creating a dual-stream architecture, where a host application (e.g., one capturing from a GigE network camera) sends video frames to a sandboxed extension, which in turn exposes this stream as a selectable camera to all other applications on the system, such as FaceTime, Zoom, or QuickTime Player.

The analysis covers the complete development lifecycle, from initial project and entitlement configuration to the detailed implementation of source and sink streams, inter-process communication (IPC), and high-performance frame data management. It includes explicit Swift code examples for both the camera extension and the host application, demystifying the framework's architecture and confirming that its design handles much of the underlying complexity, allowing for focused and minimal application code.

## **The Modern Virtual Camera: Project and Entitlement Setup**

The foundation of a stable and secure CMIO Camera Extension lies not in complex code, but in a meticulous and correct project configuration. The entire framework is built upon the System Extension security model, which establishes a verifiable chain of trust from the user to the extension's running code. An error in this foundational setup is a primary cause of extensions failing to load or activate, often silently.

### **Creating the Core Project Structure**

The process begins by establishing the fundamental relationship between the main application, which will control the virtual camera, and the extension itself, which runs as a separate system process.

1. **Create a New macOS App Project:** In Xcode, start by creating a new project using the "macOS App" template. This will serve as the container and controller for the extension.  
2. **Add the Camera Extension Target:** With the main project open, add a new target by navigating to File \> New \> Target. In the macOS section, scroll to the bottom and select the "Camera Extension" template.1 Name the extension (e.g., "GigECamExtension") and ensure that the "Embed in Application" option is set to your main app. This step physically places the extension's code inside the main application's bundle, which is a requirement for installation.2

Xcode will generate a new group for the extension containing several key files, including a pre-populated \[ExtensionName\]Provider.swift file, which contains the complete boilerplate for a functional software camera, and an Info.plist file that identifies the target as a CMIO extension.1

### **Configuring Capabilities and Entitlements: The Chain of Trust**

Entitlements are not merely settings; they are declarations of intent that the macOS security system uses to grant specific permissions. Misconfiguration here will break the chain of trust and prevent the extension from running.

#### **Host App Configuration**

Select the main application target and navigate to the "Signing & Capabilities" pane. Add the following capabilities:

* **System Extension:** This is the most critical capability. It grants the application the right to submit requests to the system to activate or deactivate its embedded extension.3 Without this, any calls to  
  OSSystemExtensionManager will fail.  
* **App Groups:** This capability is essential for communication between the app and its extension. It creates a shared data container that both sandboxed processes can access.1 The system uses this shared group identity as a prerequisite for establishing the high-performance communication channel needed to pass video frames. When adding this capability, create a new app group with a unique identifier, typically in the format  
  group.com.yourcompany.yourapp. This identifier must be precisely copied for use in the extension's entitlements.  
* **Camera (for Debugging):** While the host app's primary role might be to send frames to the extension, adding the Camera entitlement can be useful for debugging or if the app needs to access other camera hardware.

#### **Extension Configuration**

Select the newly created extension target and navigate to its "Signing & Capabilities" pane.

* **App Groups:** Add the App Groups capability and ensure the identifier is *identical* to the one created for the host app.3 A mismatch is a common and fatal configuration error that prevents communication.  
* **Camera (Avoid for this Use Case):** It is strongly recommended *not* to add the com.apple.security.device.camera entitlement to the extension for a pure software camera that receives frames from its host app. Adding this entitlement signals to the system that the extension itself needs to access physical camera hardware. This can have undesirable side effects, such as causing the extension to appear with a generic icon in the Dock and making its process appear as "Not Responding" in Activity Monitor because it is not a standard UI application.4

During initial development, it is often helpful to temporarily disable the "Hardened Runtime" capability for both the app and extension targets. This can relax some security restrictions and make debugging easier, but it must be re-enabled for any distribution builds, especially for the App Store.

### **Info.plist Manifest Deep Dive**

The Info.plist files for both the app and extension contain metadata that is critical for the system to correctly identify and manage the virtual camera.

#### **Extension Info.plist**

* **Privacy \- System Extension Usage Description (NSSystemExtensionUsageDescriptionKey):** This key is mandatory. The string value provided here is what the system displays to the user in the final confirmation dialog, explaining why the extension needs to be installed and what it does.3  
* **CMIOExtension Dictionary:** This dictionary is the primary identifier that marks the bundle as a CMIO Camera Extension.3 It contains a crucial key:  
  * **CMIOExtensionMachServiceName:** This defines a unique Mach service name that launchd (the system's service manager) uses to find and start the extension's daemon process. This name must be unique across the system. A common convention is to base it on the App Group identifier, such as $(TeamIdentifierPrefix)com.yourcompany.yourapp.cameraextension.3 It is important to understand that this is a system-level loading mechanism and is not intended for developer-level XPC communication.5

#### **Host App Info.plist**

* **Privacy \- Camera Usage Description (NSCameraUsageDescription):** While the extension handles the virtual camera, it is good practice to include this key in the host app, especially if it will be used to discover other cameras or for debugging.  
* **App Category (LSApplicationCategoryType):** Setting this to a value like public.app-category.utilities can prevent Xcode from issuing warnings during the build process.

### **The /Applications Folder Requirement and Debugging Workflow**

For security reasons, macOS requires that any application attempting to install a persistent system component like a Camera Extension must reside in the /Applications folder. This is a non-negotiable security measure to prevent transient or untrusted applications from modifying the system.6 This requirement necessitates a specific development workflow.

1. **Automate Copying to /Applications:** To streamline debugging, configure a "Post-action" script in the host application's build scheme. This script will run after every successful build.  
   * Edit the scheme (Product \> Scheme \> Edit Scheme...).  
   * Select the "Build" phase in the left pane and open the "Post-actions" disclosure triangle.  
   * Add a new "Run Script Action" and set the shell to /bin/sh.  
   * Use the following script to copy the built application bundle to the /Applications folder:  
     Bash  
     ditto "${CODESIGNING\_FOLDER\_PATH}" "/Applications/${FULL\_PRODUCT\_NAME}"

     This command correctly copies the bundle and preserves its signature.  
2. **Configure the Debugger:** By default, Xcode's debugger will attach to the app built in the derived data folder. To debug the copy in /Applications (which is the one that has permission to install the extension), the scheme's "Run" action must be modified.  
   * Edit the scheme again.  
   * Select the "Run" phase in the left pane.  
   * On the "Info" tab, change the "Executable" dropdown to "Other...".  
   * Navigate to the /Applications folder in the file dialog and select your application.

With this workflow, every time the project is built and run, the latest version is copied to /Applications, and the debugger correctly attaches to that instance, allowing for a seamless development cycle. The entire project setup process is a multi-stage security handshake that establishes a chain of trust. The developer first declares the relationship between the app and extension via matching App Group IDs and embedding.3 The user then signals trust by moving the app to the

/Applications folder.7 The app, now in a trusted location, uses its

System Extension entitlement to request activation.1 The system verifies this entire chain before finally presenting the usage description to the user for final, explicit consent in System Settings.3 A failure at any link in this chain typically results in the extension silently failing to load, as it is a security rejection, not a code crash.

The following table provides a consolidated checklist of the essential configuration keys to prevent common errors.

| Key Name | Target | File | Value / Type | Purpose |
| :---- | :---- | :---- | :---- | :---- |
| com.apple.security.app-sandbox | App & Extension | .entitlements | Boolean (YES) | Enables the app/extension sandbox, a mandatory security feature. |
| com.apple.security.system-extension | App | .entitlements | Boolean (YES) | Grants the host app permission to request the installation and management of its embedded system extension.3 |
| com.apple.security.application-groups | App & Extension | .entitlements | Array\<String\> | Establishes a shared sandbox container and a verifiable identity link between the app and extension. The value must be identical in both targets and is a prerequisite for system-brokered IPC.3 |
| CMIOExtensionMachServiceName | Extension | Info.plist | String | A unique Mach service name used by the system's launchd process to start the extension's daemon. Not for direct developer use.3 |
| NSSystemExtensionUsageDescriptionKey | Extension | Info.plist | String | The user-facing description displayed in the system alert, explaining why the extension needs permission to be installed.3 |

## **Architectural Blueprint of a CMIO Extension**

To effectively implement a virtual camera, it is crucial to understand the framework's object-oriented architecture. CMIO Extensions are designed with a clear separation of concerns, delegating system-level complexity to framework objects and allowing the developer to focus on providing custom behavior and data.

### **The Three Pillars of a CMIO Extension**

The architecture is built upon a hierarchy of three primary classes, each with a distinct role:

* **CMIOExtensionProvider:** This is the top-level object and the main entry point for the extension. It acts as a singleton manager for the entire service, representing the virtual camera "driver" as a whole. Its primary responsibility is to manage the lifecycle of all virtual camera devices that the extension publishes to the system. The provider is created once when the extension's service is started by the OS.1  
* **CMIOExtensionDevice:** This class represents a single, selectable camera that appears in the camera lists of applications like FaceTime or Zoom. An extension can, in theory, publish multiple distinct devices (e.g., "GigECam \- Raw" and "GigECam \- Effects"). Each device is responsible for managing its own set of data streams.1  
* **CMIOExtensionStream:** This is the object that does the heavy lifting. It represents a single, directional flow of data—either out of the device (a source stream) or into the device (a sink stream). The stream object is where video formats, frame rates, and the actual passing of CMSampleBuffer objects occur.1

### **The Power of Protocols: The ...Source Delegation Pattern**

The CMIO framework employs a powerful delegation pattern. For each of the three core classes, there is a corresponding protocol that the developer must implement:

* CMIOExtensionProviderSource  
* CMIOExtensionDeviceSource  
* CMIOExtensionStreamSource

All of the custom logic for the virtual camera resides within classes that conform to these ...Source protocols. The system-provided CMIOExtension... objects handle the complex, low-level tasks of inter-process communication, sandboxing, and integration with the Core Media stack. They then delegate to the developer's ...Source objects to provide the specific behavior and data needed—such as the device's name, the stream's video format, or the actual pixel buffers to display.3 The default Xcode template provides a complete, working skeleton with classes conforming to all three protocols.1

### **Data Flow and Process Boundaries**

Understanding the process architecture is key to grasping how communication works. The camera extension does not run inside the host application or the client application (e.g., FaceTime). Instead, it runs as its own dedicated, sandboxed daemon process, typically as a non-privileged role user for security.2

A system proxy service, registerassistantservice, sits as an intermediary between the extension's daemon and any client applications. This proxy is responsible for enforcing macOS's Transparency, Consent, and Control (TCC) policies—for example, handling the user prompt that asks for permission to use the camera. It also handles power attribution, ensuring that the CPU and energy usage of the extension's daemon is correctly attributed to the client app that is actively using the camera.2

This architecture means there are two distinct communication paths, both brokered by the system:

1. Host App to Extension: The developer's main application communicates with the extension's daemon to send it video frames.  
2. Extension to Client App: The extension's daemon communicates with client applications (FaceTime, Zoom, etc.) to provide the virtual video feed.

A crucial aspect of developing a CMIO extension is recognizing that it requires working in two different API paradigms simultaneously. The extension itself is built using the modern, object-oriented, Swift-native CMIOExtension framework. The code within the extension target, as seen in the Xcode template and various examples, is pure Swift, using classes like CMIOExtensionDevice and protocols like CMIOExtensionStreamSource.1 This is the "modern world."

However, when the host application needs to discover and send data to the extension's sink stream, the CMIOExtension framework does not provide a high-level Swift API for this client-side interaction. Instead, the host application must use the older, more complex, C-style CoreMediaIO APIs.2 This involves working directly with

CMIOObjectIDs, CMIOObjectPropertyAddress structs, and C functions like CMIOObjectGetPropertyData and CMIOStreamCopyBufferQueue.8 This is the "old world." Consequently, a developer must be functionally bilingual, writing modern Swift for the extension's internal logic while wrapping the legacy C-API within their Swift-based host application to communicate with it. This duality explains why the code in the host app looks fundamentally different from the code in the extension.

The following table delineates the separation of concerns within the framework, helping to place logic in the correct source protocol.

| Component | Manages | Key Responsibilities |
| :---- | :---- | :---- |
| CMIOExtensionProviderSource | The entire extension | Defines provider-level properties (e.g., manufacturer name). Manages the lifecycle of all CMIOExtensionDevice objects the extension publishes. Handles connection and disconnection of client applications.1 |
| CMIOExtensionDeviceSource | A single CMIOExtensionDevice | Defines device-level properties (e.g., model name, isSuspended). Manages the lifecycle of its associated streams. Acts as the central hub to route data from sink streams to source streams.1 |
| CMIOExtensionStreamSource | A single CMIOExtensionStream | Defines stream properties (e.g., formats, frame rates). Implements the core logic for starting and stopping the stream. For source streams, provides the mechanism to send buffers. For sink streams, provides the mechanism to consume buffers.1 |

## **Implementing the Dual-Stream Model: The Heart of the Extension**

This section provides a complete, commented code walkthrough for the \[ExtensionName\]Provider.swift file. The goal is to build a device with two streams: a source stream to broadcast video to client apps and a sink stream to receive video frames from the host application.

The structure will follow the standard Xcode template, which organizes the provider, device, and stream source implementations into a single file.

### **The Provider and Device Source Setup**

The Provider is the entry point, and its source's main job is to create and manage the Device. The DeviceSource will, in turn, create and manage the SourceStreamSource and SinkStreamSource.

Swift

// \[ExtensionName\]Provider.swift

import Foundation  
import CoreMediaIO  
import os.log

// MARK: \- Provider  
class Provider: NSObject, CMIOExtensionProviderSource {

    private(set) var provider: CMIOExtensionProvider\!  
    private var deviceSource: DeviceSource\!

    // The system calls this initializer.  
    init(clientQueue: DispatchQueue?) {  
        super.init()  
        provider \= CMIOExtensionProvider(source: self, clientQueue: clientQueue)  
        deviceSource \= DeviceSource(localizedName: "GigECam (Virtual)")

        do {  
            // Add the device to the provider. The system will now be aware of it.  
            try provider.addDevice(deviceSource.device)  
        } catch {  
            fatalError("Failed to add device: \\(error.localizedDescription)")  
        }  
    }

    func connect(to client: CMIOExtensionClient) throws {  
        // Handle client connections. For this simple case, we allow all connections.  
        os\_log("Client connected: \\(client.description)")  
    }

    func disconnect(from client: CMIOExtensionClient) {  
        // Handle client disconnections.  
        os\_log("Client disconnected: \\(client.description)")  
    }

    // The provider's properties. We'll define a manufacturer name.  
    var availableProperties: Set\<CMIOExtensionProperty\> {  
        return \[.providerManufacturer\]  
    }

    func providerProperties(forProperties properties: Set\<CMIOExtensionProperty\>) throws \-\> CMIOExtensionProviderProperties {  
        let providerProperties \= CMIOExtensionProviderProperties(dictionary: \[:\])  
        if properties.contains(.providerManufacturer) {  
            providerProperties.manufacturer \= "GigECam Solutions"  
        }  
        return providerProperties  
    }

    func setProviderProperties(\_ providerProperties: CMIOExtensionProviderProperties) throws {  
        // Handle property changes if needed.  
    }  
}

// MARK: \- Device Source  
class DeviceSource: NSObject, CMIOExtensionDeviceSource {

    private(set) var device: CMIOExtensionDevice\!  
    private var sourceStreamSource: SourceStreamSource\!  
    private var sinkStreamSource: SinkStreamSource\!

    // A counter to track how many clients are streaming from the source.  
    private var streamingCounter: Int \= 0  
      
    // A flag to indicate if the sink stream is active.  
    private(set) var isSinking: Bool \= false

    init(localizedName: String) {  
        super.init()  
        let deviceID \= UUID() // A unique ID for our virtual device.  
        self.device \= CMIOExtensionDevice(localizedName: localizedName, deviceID: deviceID, source: self)

        // Define the video format we will support.  
        // Using 32BGRA is highly recommended for maximum compatibility with client apps like FaceTime and QuickTime. \[13\]  
        let dims \= CMVideoDimensions(width: 1920, height: 1080)  
        let videoFormatDescription \= try\! CMVideoFormatDescription(  
            videoCodecType:.\_32BGRA,  
            width: dims.width,  
            height: dims.height)  
        let videoFormat \= CMIOExtensionStreamFormat(  
            formatDescription: videoFormatDescription,  
            maxFrameDuration: CMTime(value: 1, timescale: 30), // 30 FPS  
            minFrameDuration: CMTime(value: 1, timescale: 60), // 60 FPS  
            validFrameDurations: nil)

        // Create the source and sink streams.  
        self.sourceStreamSource \= SourceStreamSource(localizedName: "GigECam.Video.Source", streamID: UUID(), streamFormat: videoFormat, device: self.device)  
        self.sinkStreamSource \= SinkStreamSource(localizedName: "GigECam.Video.Sink", streamID: UUID(), streamFormat: videoFormat, device: self.device)  
          
        // Add the streams to the device. \[8\]  
        do {  
            try device.addStream(sourceStreamSource.stream)  
            try device.addStream(sinkStreamSource.stream)  
        } catch {  
            fatalError("Failed to add streams: \\(error.localizedDescription)")  
        }  
    }

    var availableProperties: Set\<CMIOExtensionProperty\> {  
        return \[.deviceModel\]  
    }

    func deviceProperties(forProperties properties: Set\<CMIOExtensionProperty\>) throws \-\> CMIOExtensionDeviceProperties {  
        let deviceProperties \= CMIOExtensionDeviceProperties(dictionary: \[:\])  
        if properties.contains(.deviceModel) {  
            deviceProperties.model \= "GigECam Model-1"  
        }  
        return deviceProperties  
    }

    func setDeviceProperties(\_ deviceProperties: CMIOExtensionDeviceProperties) throws {  
        // Handle property changes if needed.  
    }  
      
    // This is where the magic happens: bridging the sink to the source.  
    func startSinkStreaming() {  
        os\_log("Device source told to start sinking.")  
        isSinking \= true  
          
        // Provide a closure to the SinkStreamSource. This closure will be executed  
        // every time a buffer is received from the host app. \[8\]  
        sinkStreamSource.consumeSampleBuffer \= { \[weak self\] buffer in  
            guard let self \= self else { return }  
              
            // If at least one client is watching the source stream, forward the buffer.  
            if self.streamingCounter \> 0 {  
                // The buffer from the sink is sent directly to the source stream.  
                self.sourceStreamSource.stream.send(buffer, discontinuity:.all, hostTimeInNanoseconds: CMClockGetTime(CMClockGetHostTimeClock()).seconds \* 1\_000\_000\_000)  
            }  
        }  
    }  
      
    func stopSinkStreaming() {  
        os\_log("Device source told to stop sinking.")  
        isSinking \= false  
        sinkStreamSource.consumeSampleBuffer \= nil  
    }

    // Called by the SourceStreamSource when a client starts/stops streaming.  
    func startStreaming() {  
        streamingCounter \+= 1  
        os\_log("Source stream started. Counter: \\(self.streamingCounter)")  
    }

    func stopStreaming() {  
        streamingCounter \-= 1  
        os\_log("Source stream stopped. Counter: \\(self.streamingCounter)")  
    }  
}

### **Implementing the Source Stream: Broadcasting to the System**

The SourceStreamSource is responsible for defining the output stream that client applications connect to. Its main role is to provide the CMIOExtensionStream object that the DeviceSource will use to send frames.

Swift

// MARK: \- Source Stream Source  
class SourceStreamSource: NSObject, CMIOExtensionStreamSource {

    private(set) var stream: CMIOExtensionStream\!  
    private let device: CMIOExtensionDevice  
    private let streamFormat: CMIOExtensionStreamFormat  
      
    // A simple default frame to show when the host app isn't sending anything.  
    private var blackFrame: CVPixelBuffer?  
    private var timer: DispatchSourceTimer?

    init(localizedName: String, streamID: UUID, streamFormat: CMIOExtensionStreamFormat, device: CMIOExtensionDevice) {  
        self.device \= device  
        self.streamFormat \= streamFormat  
        super.init()  
        // Initialize the stream with direction.source \[14\]  
        self.stream \= CMIOExtensionStream(localizedName: localizedName, streamID: streamID, direction:.source, clockType:.hostTime, source: self)  
          
        // Create a black pixel buffer to use as a default frame.  
        let attributes \= as CFDictionary  
        let width \= Int(streamFormat.formatDescription.dimensions.width)  
        let height \= Int(streamFormat.formatDescription.dimensions.height)  
        CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType\_32BGRA, attributes, &blackFrame)  
    }

    var formats: {  
        return \[streamFormat\]  
    }

    var activeFormatIndex: Int \= 0 {  
        didSet {  
            if activeFormatIndex \>= 1 {  
                fatalError("Invalid format index")  
            }  
        }  
    }

    func streamProperties(forProperties properties: Set\<CMIOExtensionProperty\>) throws \-\> CMIOExtensionStreamProperties {  
        let streamProperties \= CMIOExtensionStreamProperties(dictionary: \[:\])  
        if properties.contains(.streamActiveFormatIndex) {  
            streamProperties.activeFormatIndex \= activeFormatIndex  
        }  
        if properties.contains(.streamFrameDuration) {  
            streamProperties.frameDuration \= streamFormat.maxFrameDuration  
        }  
        return streamProperties  
    }

    func setStreamProperties(\_ streamProperties: CMIOExtensionStreamProperties) throws {  
        if let activeFormatIndex \= streamProperties.activeFormatIndex {  
            self.activeFormatIndex \= activeFormatIndex  
        }  
    }

    func authorizedToStartStream(for client: CMIOExtensionClient) \-\> Bool {  
        // Allow all clients to start the stream.  
        return true  
    }

    func startStream() throws {  
        guard let deviceSource \= device.source as? DeviceSource else {  
            fatalError("Unexpected device source type")  
        }  
        deviceSource.startStreaming()  
          
        // Start a timer to send a default black frame periodically if the sink is not active.  
        // This ensures client apps always receive a valid video feed.  
        timer \= DispatchSource.makeTimerSource(queue:.main)  
        timer?.schedule(deadline:.now(), repeating:.milliseconds(1000 / 30))  
        timer?.setEventHandler { \[weak self\] in  
            guard let self \= self, let deviceSource \= self.device.source as? DeviceSource else { return }  
              
            // Only send the default frame if the sink is not active. \[8\]  
            if\!deviceSource.isSinking, let buffer \= self.blackFrame {  
                var sampleBuffer: CMSampleBuffer?  
                var timingInfo \= CMSampleTimingInfo(duration:.invalid, presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()), decodeTimeStamp:.invalid)  
                var formatDesc: CMVideoFormatDescription?  
                CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: buffer, formatDescriptionOut: &formatDesc)  
                CMSampleBufferCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: buffer, dataReady: true, makeDataReadyCallback: nil, refcon: nil, formatDescription: formatDesc\!, sampleTiming: &timingInfo, sampleBufferOut: &sampleBuffer)  
                  
                if let sampleBuffer \= sampleBuffer {  
                    self.stream.send(sampleBuffer, discontinuity:.all, hostTimeInNanoseconds: timingInfo.presentationTimeStamp.seconds \* 1\_000\_000\_000)  
                }  
            }  
        }  
        timer?.resume()  
    }

    func stopStream() throws {  
        timer?.cancel()  
        timer \= nil  
          
        guard let deviceSource \= device.source as? DeviceSource else {  
            fatalError("Unexpected device source type")  
        }  
        deviceSource.stopStreaming()  
    }  
}

### **Implementing the Sink Stream: The Funnel for Your App's Frames**

The SinkStreamSource is the entry point for frames coming from the host application. Its core responsibility is to set up a listener that consumes CMSampleBuffer objects from a system-provided queue.

Swift

// MARK: \- Sink Stream Source  
class SinkStreamSource: NSObject, CMIOExtensionStreamSource {

    private(set) var stream: CMIOExtensionStream\!  
    private let device: CMIOExtensionDevice  
    private let streamFormat: CMIOExtensionStreamFormat  
    private var client: CMIOExtensionClient?  
      
    // This closure will be set by the DeviceSource. It's the bridge.  
    var consumeSampleBuffer: ((CMSampleBuffer) \-\> Void)?

    init(localizedName: String, streamID: UUID, streamFormat: CMIOExtensionStreamFormat, device: CMIOExtensionDevice) {  
        self.device \= device  
        self.streamFormat \= streamFormat  
        super.init()  
        // Initialize the stream with direction.sink \[8, 14, 15\]  
        self.stream \= CMIOExtensionStream(localizedName: localizedName, streamID: streamID, direction:.sink, clockType:.hostTime, source: self)  
    }

    var formats: {  
        return \[streamFormat\]  
    }

    var activeFormatIndex: Int \= 0 {  
        didSet {  
            if activeFormatIndex \>= 1 {  
                fatalError("Invalid format index")  
            }  
        }  
    }

    func streamProperties(forProperties properties: Set\<CMIOExtensionProperty\>) throws \-\> CMIOExtensionStreamProperties {  
        let streamProperties \= CMIOExtensionStreamProperties(dictionary: \[:\])  
        if properties.contains(.streamActiveFormatIndex) {  
            streamProperties.activeFormatIndex \= activeFormatIndex  
        }  
        return streamProperties  
    }

    func setStreamProperties(\_ streamProperties: CMIOExtensionStreamProperties) throws {  
        if let activeFormatIndex \= streamProperties.activeFormatIndex {  
            self.activeFormatIndex \= activeFormatIndex  
        }  
    }

    func authorizedToStartStream(for client: CMIOExtensionClient) \-\> Bool {  
        // Store the client that is starting the stream.  
        self.client \= client  
        return true  
    }

    func startStream() throws {  
        guard let deviceSource \= device.source as? DeviceSource else {  
            fatalError("Unexpected device source type")  
        }  
        // Tell the device source that the sink is starting.  
        deviceSource.startSinkStreaming()  
        // Begin listening for buffers.  
        try subscribe()  
    }

    func stopStream() throws {  
        guard let deviceSource \= device.source as? DeviceSource else {  
            fatalError("Unexpected device source type")  
        }  
        // Tell the device source that the sink is stopping.  
        deviceSource.stopSinkStreaming()  
    }  
      
    private func subscribe() throws {  
        guard let client \= self.client else { return }  
          
        // This is the core of the sink. We ask the stream to consume buffers from the client.  
        // The handler will be called for each buffer received. \[2, 8\]  
        stream.consumeSampleBuffer(from: client) { \[weak self\] (sampleBuffer, sequenceNumber, discontinuity, hasMoreSampleBuffers, error) in  
              
            // Re-subscribe to continue receiving buffers. This pattern is crucial. \[8\]  
            defer {  
                if let self \= self, self.stream.state \==.running {  
                    try? self.subscribe()  
                }  
            }

            if let error \= error {  
                os\_log("Error consuming sample buffer: \\(error.localizedDescription)")  
                return  
            }  
              
            if let sampleBuffer \= sampleBuffer {  
                // Execute the closure provided by the DeviceSource, passing the buffer up.  
                self?.consumeSampleBuffer?(sampleBuffer)  
            }  
        }  
    }  
}

The data transfer from the sink to the source is not a direct, synchronous pipe. It is an asynchronous bridge built with closures, with the DeviceSource acting as the central coordinating pier. When the sink stream starts, it informs the DeviceSource. The DeviceSource responds by providing a closure to the sink, effectively saying, "When you receive a buffer, execute this code." The sink then registers this closure with the system via consumeSampleBuffer and waits. When the host app enqueues a buffer, the system delivers it to the sink's handler, which executes the provided closure. The DeviceSource, now in possession of the buffer, checks if the source stream is active and, if so, sends the buffer on its way. This decoupled, asynchronous design is highly robust, allowing the source and sink streams to start and stop independently while the DeviceSource manages the stateful connection between them.

## **The Host Application: Driving the Virtual Camera**

With the extension fully implemented, the focus shifts to the main macOS application. Its role is to discover the virtual camera's sink stream, connect to it, and feed it video frames captured from the GigE camera. This requires using the legacy CoreMediaIO C-APIs, which can be wrapped in Swift for cleaner integration.

### **Discovering Your Virtual Camera: The C-API in Swift**

The first step is to programmatically find the CMIODeviceID and CMIOStreamID that correspond to the virtual camera and its sink stream.

Swift

// In your host application's code (e.g., a ViewModel or Controller)  
import AVFoundation  
import CoreMediaIO

class VirtualCameraManager {

    private var sinkQueue: CMSimpleQueue?  
    private let virtualCameraUID \= "GigECam (Virtual)" // Must match the localizedName in the extension

    func connect() {  
        guard let deviceID \= findDeviceID(for: virtualCameraUID) else {  
            print("Error: Could not find virtual camera device.")  
            return  
        }  
          
        guard let streamIDs \= getStreamIDs(for: deviceID), streamIDs.count \== 2 else {  
            print("Error: Could not find streams for the device.")  
            return  
        }  
          
        // In our simple two-stream setup, the sink is the second stream. \[8\]  
        let sinkStreamID \= streamIDs\[3\]  
          
        // Start the stream and get the queue for sending buffers.  
        startStream(deviceID: deviceID, streamID: sinkStreamID)  
    }

    // Finds the CMIODeviceID for our virtual camera by its name (UID in this context).  
    private func findDeviceID(for name: String) \-\> CMIODeviceID? {  
        var property \= CMIOObjectPropertyAddress(  
            mSelector: kCMIOHardwarePropertyDevices,  
            mScope: kCMIOObjectPropertyScopeGlobal,  
            mElement: kCMIOObjectPropertyElementMain)

        var dataSize: UInt32 \= 0  
        CMIOObjectGetPropertyDataSize(CMIOObjectPropertySelector(kCMIOObjectSystemObject), &property, 0, nil, &dataSize)  
          
        let deviceCount \= Int(dataSize) / MemoryLayout\<CMIODeviceID\>.size  
        var deviceIDs \=(repeating: 0, count: deviceCount)  
          
        CMIOObjectGetPropertyData(CMIOObjectPropertySelector(kCMIOObjectSystemObject), &property, 0, nil, dataSize, &dataSize, &deviceIDs)  
          
        for deviceID in deviceIDs {  
            property.mSelector \= kCMIODevicePropertyDeviceUID  
            var nameDataSize: UInt32 \= 0  
            CMIOObjectGetPropertyDataSize(deviceID, &property, 0, nil, &nameDataSize)  
              
            var deviceName: CFString \= "" as CFString  
            CMIOObjectGetPropertyData(deviceID, &property, 0, nil, nameDataSize, &nameDataSize, &deviceName)  
              
            if (deviceName as String) \== name {  
                return deviceID  
            }  
        }  
          
        return nil  
    }

    // Gets the stream IDs for a given device.  
    private func getStreamIDs(for deviceID: CMIODeviceID) \-\>? {  
        var property \= CMIOObjectPropertyAddress(  
            mSelector: kCMIODevicePropertyStreams,  
            mScope: kCMIOObjectPropertyScopeGlobal,  
            mElement: kCMIOObjectPropertyElementMain)

        var dataSize: UInt32 \= 0  
        CMIOObjectGetPropertyDataSize(deviceID, &property, 0, nil, &dataSize)  
          
        let streamCount \= Int(dataSize) / MemoryLayout\<CMIOStreamID\>.size  
        var streamIDs \=(repeating: 0, count: streamCount)  
          
        CMIOObjectGetPropertyData(deviceID, &property, 0, nil, dataSize, &dataSize, &streamIDs)  
          
        return streamIDs.isEmpty? nil : streamIDs  
    }  
      
    // Starts the sink stream and retrieves its buffer queue.  
    private func startStream(deviceID: CMIODeviceID, streamID: CMIOStreamID) {  
        var queueUnmanaged: Unmanaged\<CMSimpleQueue\>?  
          
        // This C-API call is the key to getting the buffer queue. \[2, 8\]  
        let resultQueue \= CMIOStreamCopyBufferQueue(streamID, { streamID, refcon in  
            // This callback is for queue alterations, not needed for simple enqueuing.  
        }, nil, &queueUnmanaged)  
          
        guard resultQueue \== kCMIOHardwareNoError, let queue \= queueUnmanaged?.takeRetainedValue() else {  
            print("Error: Failed to get stream buffer queue.")  
            return  
        }  
          
        self.sinkQueue \= queue  
          
        // Tell the extension we are starting the stream.  
        let resultStart \= CMIODeviceStartStream(deviceID, streamID)  
        if resultStart \== kCMIOHardwareNoError {  
            print("Successfully connected to sink stream.")  
        } else {  
            print("Error: Failed to start sink stream.")  
        }  
    }  
}

### **Frame Preparation and Enqueueing**

Once connected, the application enters its main loop: receiving a frame from the GigE camera, wrapping it in a CMSampleBuffer, and enqueuing it.

Swift

// Continuing the VirtualCameraManager class...  
extension VirtualCameraManager {

    // This function takes a CVPixelBuffer (e.g., from a camera SDK) and sends it to the extension.  
    public func sendPixelBuffer(\_ pixelBuffer: CVPixelBuffer) {  
        guard let queue \= self.sinkQueue else {  
            // Not connected yet.  
            return  
        }  
          
        // 1\. Create a format description for the buffer.  
        var formatDescription: CMVideoFormatDescription?  
        CMVideoFormatDescriptionCreateForImageBuffer(  
            allocator: kCFAllocatorDefault,  
            imageBuffer: pixelBuffer,  
            formatDescriptionOut: &formatDescription)  
              
        guard let format \= formatDescription else {  
            print("Error: Could not create format description.")  
            return  
        }

        // 2\. Create timing info. The presentation timestamp is critical. \[13\]  
        var timingInfo \= CMSampleTimingInfo(  
            duration:.invalid,  
            presentationTimeStamp: CMClockGetTime(CMClockGetHostTimeClock()),  
            decodeTimeStamp:.invalid)

        // 3\. Create the CMSampleBuffer.  
        var sampleBuffer: CMSampleBuffer?  
        CMSampleBufferCreateForImageBuffer(  
            allocator: kCFAllocatorDefault,  
            imageBuffer: pixelBuffer,  
            dataReady: true,  
            makeDataReadyCallback: nil,  
            refcon: nil,  
            formatDescription: format,  
            sampleTiming: &timingInfo,  
            sampleBufferOut: &sampleBuffer)  
              
        // 4\. Enqueue the buffer to be sent to the extension. \[8\]  
        if let buffer \= sampleBuffer {  
            CMSimpleQueueEnqueue(queue, element: Unmanaged.passRetained(buffer).toOpaque())  
        }  
    }  
}

A common misconception is that the App Group entitlement is the transport mechanism for video frames, perhaps by writing them to a shared file. This is incorrect. The App Group's true role is that of a security prerequisite. System Extensions are heavily sandboxed, and an arbitrary application cannot simply connect to their services.2 The shared App Group entitlement acts as a cryptographic proof of relationship between the host app and the extension.1 When the host app attempts to connect to the sink stream, the system's security services verify that both processes belong to the same App Group. Only if this check passes does the system consider the connection legitimate and vend the

CMSimpleQueue reference to the app. In essence, the App Group is the "permission slip" that authorizes the creation of the high-performance, system-brokered IPC connection; it is not the "delivery truck" itself. The actual transport relies on a much more efficient, zero-copy mechanism.

## **Mastering Frame Data for High-Performance IPC**

The performance of a virtual camera, especially one handling a high-framerate GigE stream, hinges on the efficient transfer of frame data between processes. The CMIO framework is designed for this, leveraging underlying macOS technologies to achieve zero-copy IPC.

### **Anatomy of a CMSampleBuffer**

A CMSampleBuffer is the universal container for timed media data in Apple's frameworks. It is more than just a wrapper for pixels. It encapsulates three critical pieces of information:

1. **The Image Data:** Typically held in a CVPixelBuffer.  
2. **The Format Description:** A CMVideoFormatDescription that describes the data (dimensions, pixel format, color space, etc.).  
3. **The Timing Information:** A CMSampleTimingInfo struct that gives the frame a presentation timestamp, which is essential for client applications to play the video smoothly and in sync.8

### **CVPixelBuffer and IOSurface: The Key to Zero-Copy IPC**

The magic of high-performance IPC in this context comes from the interaction between CVPixelBuffer and IOSurface.

* **CVPixelBuffer:** This is the fundamental object for holding uncompressed pixel data in main memory.17  
* **IOSurface:** This is a kernel-level object representing a sharable memory region for graphics data. It is explicitly designed for efficient, zero-copy sharing of framebuffers and textures across process boundaries.17

When the host application enqueues a CMSampleBuffer containing a CVPixelBuffer that is backed by an IOSurface, the system does not perform a memory copy of the pixel data. Instead, it securely passes a reference to the IOSurface (via a mach\_port\_t) from the host app's process to the extension's process.19 Both processes are then able to map the exact same region of physical RAM into their own virtual address spaces. This is a true zero-copy transfer and is the core reason for the framework's high performance.2

The CMIO Extension framework is masterfully designed to abstract away this complexity. The developer interacts with high-level Swift objects like CMSampleBuffer and CVPixelBuffer. Nowhere in the high-level code is there an explicit creation or management of an IOSurface or a Mach port. The system handles this transparently when the CMSimpleQueue is used for transport.2 This confirms the initial assumption that the framework handles the difficult parts, allowing the developer to focus on providing the data, not engineering the transport layer.

### **Practical Considerations**

* **Pixel Formats:** For maximum compatibility with a wide range of client applications (FaceTime, QuickTime, Photo Booth, etc.), it is strongly recommended that the source stream's CMVideoFormatDescription declares the pixel format as kCVPixelFormatType\_32BGRA. Even if the buffers being sent from the host app are in a different format (e.g., a YUV variant), many clients are more robust if the stream advertises this common RGB format.13  
* **Buffer Pools (CVPixelBufferPool):** For high-resolution and high-framerate streams, creating and destroying a CVPixelBuffer for every single frame can become a performance bottleneck. To mitigate this, CVPixelBufferPool can be used. A pool pre-allocates a number of buffers that can be reused, avoiding the overhead of memory allocation on the critical rendering path.21

## **The Final Mile: Activation, Permissions, and Troubleshooting**

The final steps involve managing the extension's runtime lifecycle from the host application and understanding how to diagnose common problems.

### **The Activation Flow in Code**

The host application should provide a simple UI, such as a button, to allow the user to activate and deactivate the extension.

Swift

// In a SwiftUI View in the host app.  
import SwiftUI  
import SystemExtensions

struct ContentView: View {  
    @State private var statusMessage \= "Press Activate to install the camera extension."  
    private let extensionIdentifier \= "com.yourcompany.yourapp.GigECamExtension" // Must match your extension's bundle ID.

    var body: some View {  
        VStack(spacing: 20) {  
            Text(statusMessage)  
              
            Button("Activate Extension") {  
                activate()  
            }  
              
            Button("Deactivate Extension") {  
                deactivate()  
            }  
        }  
      .padding()  
    }  
      
    private func activate() {  
        let request \= OSSystemExtensionRequest.activationRequest(  
            forExtensionWithIdentifier: extensionIdentifier,  
            queue:.main)  
        request.delegate \= ExtensionDelegate.shared  
        OSSystemExtensionManager.shared.submitRequest(request)  
        statusMessage \= "Activation request submitted. Please check System Settings to approve."  
    }  
      
    private func deactivate() {  
        let request \= OSSystemExtensionRequest.deactivationRequest(  
            forExtensionWithIdentifier: extensionIdentifier,  
            queue:.main)  
        request.delegate \= ExtensionDelegate.shared  
        OSSystemExtensionManager.shared.submitRequest(request)  
        statusMessage \= "Deactivation request submitted."  
    }  
}

// A simple delegate to handle responses from the system.  
class ExtensionDelegate: NSObject, OSSystemExtensionRequestDelegate {  
    static let shared \= ExtensionDelegate()  
      
    func request(\_ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result) {  
        print("Extension request finished with result: \\(result.rawValue)")  
    }  
      
    func request(\_ request: OSSystemExtensionRequest, didFailWithError error: Error) {  
        print("Extension request failed with error: \\(error.localizedDescription)")  
    }  
      
    func request(\_ request: OSSystemExtensionRequest, actionForReplacingExtension existing: OSSystemExtensionProperties, withExtension ext: OSSystemExtensionProperties) \-\> OSSystemExtensionRequest.ReplacementAction {  
        // Handle updates to the extension.  
        return.replace  
    }  
}

### **Navigating User Permissions and System Settings**

When the activation request is first submitted, the system will present a dialog to the user indicating that the extension is blocked and needs permission. The user must click "Open System Settings" and explicitly allow the extension. On older versions of macOS, this is typically found in System Settings \> Privacy & Security. On newer versions, it may be under System Settings \> General \> Login Items & Extensions.7

### **Troubleshooting Guide**

#### **Problem: My virtual camera doesn't appear in FaceTime/Zoom.**

* **Is the host app in /Applications?** This is a mandatory security requirement.3  
* **Did you click "Activate" in your app?** The installation process must be initiated programmatically.6  
* **Did you "Allow" the extension in System Settings?** The user must give final, explicit consent.3  
* **Are the App Group IDs identical?** Check the .entitlements files for both the app and extension targets for any typos.3  
* **Is the CMIOExtensionMachServiceName correct?** Ensure it is unique and correctly formatted in the extension's Info.plist.3  
* **Check the system logs.** Use the Console app or the command line (log stream \--predicate 'subsystem \== "com.apple.CoreMediaIO.Extension"') to look for errors from registerassistantservice or other related systems.

#### **Problem: The camera appears but only shows a black screen or a static default frame.**

* **Is the host app successfully sending frames?** Add logging to your sendPixelBuffer method to confirm it's being called and that the CMSimpleQueue is not nil.  
* **Is the DeviceSource forwarding buffers?** Add os\_log statements inside the consumeSampleBuffer closure in the DeviceSource to verify that buffers are arriving from the sink and being sent to the source.  
* **Are the CMSampleBuffers valid?** An invalid or missing presentation timestamp (presentationTimeStamp) is a common cause of frames being dropped by client applications. Ensure CMClockGetTime(CMClockGetHostTimeClock()) is being used to generate a valid timestamp for each frame.13  
* **Is the source stream's pixel format compatible?** Ensure the source stream's format description is set to kCVPixelFormatType\_32BGRA for maximum client compatibility.13

## **Conclusion: Beyond the Basics**

This report has detailed the end-to-end process of creating a modern, secure, and high-performance virtual camera on macOS. The key principles are clear: the security model is paramount and requires meticulous configuration; the architecture is decoupled and asynchronous, promoting stability; and the IPC mechanisms are highly specialized for their purpose.

For a production-grade application, the next logical step is to implement a mechanism for low-bandwidth control data—for example, sending a command from the host app to the extension to change a video effect, adjust brightness, or toggle a feature. While the sink/source stream is ideal for high-bandwidth video, it is not suitable for this kind of control data. The Apple-recommended approach for this is to use Custom Properties.

The following table provides clear architectural guidance on choosing the correct IPC method for different types of data when working with CMIO Extensions.

| Method | Use Case | How it Works | Performance & Suitability |
| :---- | :---- | :---- | :---- |
| **Sink/Source Streams** | High-bandwidth, real-time video frames. | The host app obtains a CMSimpleQueue for the sink stream via the C-API and enqueues CMSampleBuffers containing IOSurface-backed buffers. | Extremely high performance (zero-copy). The only appropriate method for video data.2 |
| **Custom Properties** | Low-bandwidth command-and-control data. | The host app uses the C-API to set custom-defined properties on the extension's device or stream objects, which the extension can then read. | Low performance, state-based. Ideal for sending settings, toggles, or simple commands.5 |
| **XPC** | General-purpose IPC. | The extension can make outgoing XPC connections. | Discouraged for video. Less performant than streams and not the intended architecture. Can be used for other complex data but adds complexity.5 |
| **App Group Container** | Shared settings, non-real-time data. | UserDefaults(suiteName:) or writing files to the shared group container directory. | High latency, disk I/O overhead. Unsuitable for video frames. Good for persisting configuration settings.3 |

#### **Works cited**

1. Creating a camera extension with Core Media I/O | Apple Developer Documentation, accessed July 1, 2025, [https://developer.apple.com/documentation/coremediaio/creating-a-camera-extension-with-core-media-i-o](https://developer.apple.com/documentation/coremediaio/creating-a-camera-extension-with-core-media-i-o)  
2. Create camera extensions with Core Media IO \- WWDC22 \- Videos \- Apple Developer, accessed July 1, 2025, [https://developer.apple.com/videos/play/wwdc2022/10022/](https://developer.apple.com/videos/play/wwdc2022/10022/)  
3. Getting To Grips With The Core Media IO Camera Extension Part 1 of 3: The Basics, accessed July 1, 2025, [https://theoffcuts.org/posts/core-media-io-camera-extensions-part-one/](https://theoffcuts.org/posts/core-media-io-camera-extensions-part-one/)  
4. CMIO Camera Extension user experie… | Apple Developer Forums, accessed July 1, 2025, [https://developer.apple.com/forums/thread/733269](https://developer.apple.com/forums/thread/733269)  
5. is XPC from app to CMIOExtension possible? \- Apple Developer Forums, accessed July 1, 2025, [https://forums.developer.apple.com/forums/thread/706184](https://forums.developer.apple.com/forums/thread/706184)  
6. ldenoue/cameraextension: sample camera extension using coremedia io \- GitHub, accessed July 1, 2025, [https://github.com/ldenoue/cameraextension](https://github.com/ldenoue/cameraextension)  
7. Installing and Activating Virtual Camera Extension | mimoLive®, accessed July 1, 2025, [https://mimolive.com/user-manual/playout-output-destinations/virtual-camera/installing-and-activating-virtual-camera-extension/](https://mimolive.com/user-manual/playout-output-destinations/virtual-camera/installing-and-activating-virtual-camera-extension/)  
8. CoreMediaIOのCamera ExtensionでmacOSの仮想カメラを作る \- Qiita, accessed July 1, 2025, [https://qiita.com/fuziki/items/405c681a0cae702ad092](https://qiita.com/fuziki/items/405c681a0cae702ad092)  
9. Enable video support Camo Camera : r/utarlington \- Reddit, accessed July 1, 2025, [https://www.reddit.com/r/utarlington/comments/1g7r3ju/enable\_video\_support\_camo\_camera/](https://www.reddit.com/r/utarlington/comments/1g7r3ju/enable_video_support_camo_camera/)  
10. CMIOExtensionProvider | Apple Developer Documentation, accessed July 1, 2025, [https://developer.apple.com/documentation/coremediaio/cmioextensionprovider](https://developer.apple.com/documentation/coremediaio/cmioextensionprovider)  
11. CMIOExtensionDevice | Apple Developer Documentation, accessed July 1, 2025, [https://developer.apple.com/documentation/coremediaio/cmioextensiondevice](https://developer.apple.com/documentation/coremediaio/cmioextensiondevice)  
12. CMIOExtensionProviderSource | Apple Developer Documentation, accessed July 1, 2025, [https://developer.apple.com/documentation/coremediaio/cmioextensionprovidersource](https://developer.apple.com/documentation/coremediaio/cmioextensionprovidersource)  
13. CMIOExtensionStreamSource supported pixel formats \- Apple Developer, accessed July 1, 2025, [https://developer.apple.com/forums/thread/725481](https://developer.apple.com/forums/thread/725481)  
14. CMIOExtensionStream.Direction | Apple Developer Documentation, accessed July 1, 2025, [https://developer.apple.com/documentation/coremediaio/cmioextensionstream/direction-swift.enum](https://developer.apple.com/documentation/coremediaio/cmioextensionstream/direction-swift.enum)  
15. CMIOExtensionStream.Direction.sink | Apple Developer Documentation, accessed July 1, 2025, [https://developer.apple.com/documentation/coremediaio/cmioextensionstream/direction-swift.enum/sink](https://developer.apple.com/documentation/coremediaio/cmioextensionstream/direction-swift.enum/sink)  
16. CMIO CameraExtension with Distribu… | Apple Developer Forums, accessed July 1, 2025, [https://developer.apple.com/forums/thread/742513](https://developer.apple.com/forums/thread/742513)  
17. Image properties and efficient processing in iOS, part 2 | Lightricks Tech Blog \- Medium, accessed July 1, 2025, [https://medium.com/lightricks-tech-blog/efficient-image-processing-in-ios-part-2-a96f0343e6f0](https://medium.com/lightricks-tech-blog/efficient-image-processing-in-ios-part-2-a96f0343e6f0)  
18. IOSurface | Apple Developer Documentation, accessed July 1, 2025, [https://developer.apple.com/documentation/iosurface](https://developer.apple.com/documentation/iosurface)  
19. CVPixelBufferCreateWithIOSurfa, accessed July 1, 2025, [https://developer.apple.com/documentation/corevideo/cvpixelbuffercreatewithiosurface(\_:\_:\_:\_:)](https://developer.apple.com/documentation/corevideo/cvpixelbuffercreatewithiosurface\(_:_:_:_:\))  
20. MacOSX-SDKs/MacOSX10.7.sdk/System/Library/Frameworks/CoreVideo.framework/Versions/A/Headers/CVPixelBufferIOSurface.h at master · phracker/MacOSX-SDKs · GitHub, accessed July 1, 2025, [https://github.com/phracker/MacOSX-SDKs/blob/master/MacOSX10.7.sdk/System/Library/Frameworks/CoreVideo.framework/Versions/A/Headers/CVPixelBufferIOSurface.h](https://github.com/phracker/MacOSX-SDKs/blob/master/MacOSX10.7.sdk/System/Library/Frameworks/CoreVideo.framework/Versions/A/Headers/CVPixelBufferIOSurface.h)  
21. Limit of referenced CVPixelBuffer coming from the iOS camera \- Stack Overflow, accessed July 1, 2025, [https://stackoverflow.com/questions/33525025/limit-of-referenced-cvpixelbuffer-coming-from-the-ios-camera](https://stackoverflow.com/questions/33525025/limit-of-referenced-cvpixelbuffer-coming-from-the-ios-camera)  
22. How can you make a CVPixelBuffer directly from a CIImage instead of a UIImage in Swift?, accessed July 1, 2025, [https://stackoverflow.com/questions/54354138/how-can-you-make-a-cvpixelbuffer-directly-from-a-ciimage-instead-of-a-uiimage-in](https://stackoverflow.com/questions/54354138/how-can-you-make-a-cvpixelbuffer-directly-from-a-ciimage-instead-of-a-uiimage-in)  
23. cameraProvider.swift \- GitHub Gist, accessed July 1, 2025, [https://gist.github.com/ldenoue/84210280853f0490c79473b6edd25e9d](https://gist.github.com/ldenoue/84210280853f0490c79473b6edd25e9d)