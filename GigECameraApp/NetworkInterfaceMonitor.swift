//
//  NetworkInterfaceMonitor.swift
//  GigEVirtualCamera
//
//  Monitors network interface changes to detect GigE camera connections
//

import Foundation
import Network
import SystemConfiguration
import os.log

class NetworkInterfaceMonitor: NSObject {
    private let logger = Logger(subsystem: "com.lukechang.GigEVirtualCamera", category: "NetworkMonitor")
    private let queue = DispatchQueue(label: "com.lukechang.networkmonitor")
    private var pathMonitor: NWPathMonitor?
    private var scDynamicStore: SCDynamicStore?
    
    // Callbacks
    var onNetworkChange: (() -> Void)?
    
    // Track last known interfaces to detect changes
    private var lastKnownInterfaces: Set<String> = []
    
    override init() {
        super.init()
        setupNetworkMonitoring()
        setupSystemConfigurationMonitoring()
    }
    
    deinit {
        stop()
    }
    
    // MARK: - Network Framework Monitoring (for general network changes)
    
    private func setupNetworkMonitoring() {
        pathMonitor = NWPathMonitor()
        
        pathMonitor?.pathUpdateHandler = { [weak self] path in
            self?.handleNetworkPathUpdate(path)
        }
        
        pathMonitor?.start(queue: queue)
    }
    
    private func handleNetworkPathUpdate(_ path: NWPath) {
        // Check for interface changes
        let currentInterfaces = Set(path.availableInterfaces.map { $0.name })
        
        if currentInterfaces != lastKnownInterfaces {
            logger.info("Network interfaces changed: \(currentInterfaces)")
            
            // Check if this looks like a GigE camera interface change
            let addedInterfaces = currentInterfaces.subtracting(lastKnownInterfaces)
            let removedInterfaces = lastKnownInterfaces.subtracting(currentInterfaces)
            
            if !addedInterfaces.isEmpty {
                logger.info("New interfaces: \(addedInterfaces)")
            }
            if !removedInterfaces.isEmpty {
                logger.info("Removed interfaces: \(removedInterfaces)")
            }
            
            lastKnownInterfaces = currentInterfaces
            
            // Trigger camera discovery after a short delay to let the interface stabilize
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.onNetworkChange?()
            }
        }
    }
    
    // MARK: - System Configuration Monitoring (for more detailed network events)
    
    private func setupSystemConfigurationMonitoring() {
        // Create a dynamic store to monitor network configuration changes
        let callback: SCDynamicStoreCallBack = { (store, changedKeys, info) in
            guard let info = info else { return }
            let monitor = Unmanaged<NetworkInterfaceMonitor>.fromOpaque(info).takeUnretainedValue()
            monitor.handleConfigurationChange(changedKeys: changedKeys as? [String] ?? [])
        }
        
        var context = SCDynamicStoreContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        guard let store = SCDynamicStoreCreate(nil, "GigECameraNetworkMonitor" as CFString, callback, &context) else {
            logger.error("Failed to create SCDynamicStore")
            return
        }
        
        // Monitor IPv4 configuration changes (GigE cameras typically use IPv4)
        let keys = ["State:/Network/Global/IPv4", "State:/Network/Interface/.*/IPv4"] as CFArray
        let patterns = ["State:/Network/Interface/.*/IPv4", "State:/Network/Interface/.*/Link"] as CFArray
        
        SCDynamicStoreSetNotificationKeys(store, keys, patterns)
        
        // Add to run loop
        let runLoopSource = SCDynamicStoreCreateRunLoopSource(nil, store, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        
        scDynamicStore = store
    }
    
    private func handleConfigurationChange(changedKeys: [String]) {
        // Filter for relevant changes
        let relevantChanges = changedKeys.filter { key in
            key.contains("IPv4") || key.contains("Link")
        }
        
        if !relevantChanges.isEmpty {
            logger.info("Network configuration changed: \(relevantChanges)")
            
            // Debounce multiple rapid changes
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(triggerDiscovery), object: nil)
            self.perform(#selector(triggerDiscovery), with: nil, afterDelay: 0.5)
        }
    }
    
    @objc private func triggerDiscovery() {
        onNetworkChange?()
    }
    
    // MARK: - Public Methods
    
    func start() {
        // Already started in init
    }
    
    func stop() {
        pathMonitor?.cancel()
        pathMonitor = nil
        
        if let store = scDynamicStore {
            SCDynamicStoreSetNotificationKeys(store, nil, nil)
            scDynamicStore = nil
        }
    }
}