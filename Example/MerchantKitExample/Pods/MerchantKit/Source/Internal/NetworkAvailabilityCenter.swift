import SystemConfiguration

/// Observe notifications to network availability.
internal final class NetworkAvailabilityCenter {
    public var onConnectivityChanged: (() -> Void)?
    
    private var reachability: SCNetworkReachability?
    private let queue = DispatchQueue(label: "networkAvailabilityCenter")
    
    private var _lastObservedIsConnectedToNetwork: Bool?
    private var isObserving: Bool = false
    
    public init() {
        self.reachability = self.newReachability(for: self.zeroAddress)
    }
    
    public var isConnectedToNetwork: Bool {
        if let lastObservation = self._lastObservedIsConnectedToNetwork { // return cached value if available
            return lastObservation
        }
        
        guard let reachability = self.reachability else { return false }
        
        var flags: SCNetworkReachabilityFlags = []
        guard SCNetworkReachabilityGetFlags(reachability, &flags) else { return false }
        
        return self.isConnectedToNetwork(resolving: flags)
    }
    
    public func observeChanges() {
        guard !self.isObserving else { return }
        
        let didSucceed = self.attemptObserveChanges()
        
        self.isObserving = didSucceed
    }
    
    public func stopObservingChanges() {
        guard self.isObserving else { return }
        
        self._lastObservedIsConnectedToNetwork = nil
        self.isObserving = false
        
        guard let reachability = self.reachability else { return }
        
        SCNetworkReachabilitySetCallback(reachability, nil, nil)
        SCNetworkReachabilitySetDispatchQueue(reachability, nil)
    }
    
    deinit {
        self.stopObservingChanges()
    }
}

extension NetworkAvailabilityCenter {
    private func attemptObserveChanges() -> Bool {
        guard let reachability = self.reachability else { return false }
        
        let callback: SCNetworkReachabilityCallBack = { _, flags, context in
            let reference = Unmanaged<NetworkAvailabilityCenter>.fromOpaque(context!)// context!.assumingMemoryBound(to: NetworkAvailabilityCenter.self)
            let networkAvailabilityCenter = reference.takeUnretainedValue()
            
            networkAvailabilityCenter.didObserve(changesTo: flags)
        }
        
        let selfReference = Unmanaged.passUnretained(self)
        
        var context = SCNetworkReachabilityContext(version: 0, info: selfReference.toOpaque(), retain: nil, release: nil, copyDescription: nil)
        
        let didSetCallback = SCNetworkReachabilitySetCallback(reachability, callback, &context)
        let didSetQueue = SCNetworkReachabilitySetDispatchQueue(reachability, self.queue)
        
        let isObserving = didSetQueue && didSetCallback
        
        return isObserving
    }
    
    private func didObserve(changesTo flags: SCNetworkReachabilityFlags) {
        let isConnectedToNetwork = self.isConnectedToNetwork(resolving: flags)
        
        if self._lastObservedIsConnectedToNetwork != isConnectedToNetwork {
            self._lastObservedIsConnectedToNetwork = isConnectedToNetwork
            
            self.queue.async {
                self.onConnectivityChanged?()
            }
        }
    }
    
    private func newReachability<T>(for address: T) -> SCNetworkReachability? {
        var address = address
        
        return withUnsafePointer(to: &address) { pointer in
            pointer.withMemoryRebound(to: sockaddr.self, capacity: MemoryLayout<sockaddr>.size) { reboundAddress in
                SCNetworkReachabilityCreateWithAddress(nil, reboundAddress)
            }
        }
    }
    
    private var zeroAddress: sockaddr_in {
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        
        return address
    }
    
    private func isConnectedToNetwork(resolving flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.contains(.reachable) && !flags.contains(.connectionRequired)
    }
}
