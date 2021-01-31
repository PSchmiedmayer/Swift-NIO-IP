import NIO


/// An Internet Protocol (IP) address
public enum IP {
    /// An IPv4 address
    case ipv4(IPv4)
    /// An IPv4 address
    case ipv6(IPv6)
    
    /// Create an `IP` address based on a system address
    /// - Parameter address: The system address used to initailize the `IP` address
    public init(_ ipv4: in_addr) throws {
        self = .ipv4(IPv4(ipv4))
    }
    
    /// Create an `IP` address based on a system address
    /// - Parameter address: The system address used to initailize the `IP` address
    public init(_ ipv6: in6_addr) throws {
        self = .ipv6(IPv6(ipv6))
    }
    
    /// Creat an `IP` address based on a `String` representation
    /// - Parameter stringRepresentation: The `String` representation to create the `IP`
    /// - Throws: Throws an error if the address could not be created based on the `String`.
    public init(_ string: String) throws {
        if let ipv6 = try? IPv6(string) {
            self = .ipv6(ipv6)
        } else if let ipv4 = try? IPv4(string) {
            self = .ipv4(ipv4)
        } else {
            throw SocketAddressError.failedToParseIPString(string)
        }
    }
}

extension IP: CustomStringConvertible {
    public var description: String {
        switch self {
        case let .ipv4(ipv4):
            return ipv4.description
        case let .ipv6(ipv6):
            return ipv6.description
        }
    }
}

extension IP: Equatable {
    public static func == (lhs: IP, rhs: IP) -> Bool {
        switch (lhs, rhs) {
        case let (.ipv4(lhsIPv4), .ipv4(rhsIPv4)):
            return lhsIPv4 == rhsIPv4
        case let (.ipv6(lhsIPv6), .ipv6(rhsIPv6)):
            return lhsIPv6 == rhsIPv6
        default:
            return false
        }
    }
}


extension IP: Hashable { }


extension SocketAddress {
    /// Create an `IP` address based on the `SocketAddress`.
    public var ip: IP? {
        switch self {
        case let .v4(ipv4Address):
            return try? IP(ipv4Address.address.sin_addr)
        case let .v6(ipv6Address):
            return try? IP(ipv6Address.address.sin6_addr)
        default:
            return nil
        }
    }
    
    
    /// Creates a new `SocketAddress`.
    ///
    /// - parameters:
    ///   - addr: the IP ip of type `IP`.
    ///   - port: the target port.
    ///   - host: the hostname that resolved to the IP ip.
    public init(_ ip: IP, port: UInt16, host: String) {
        switch ip {
        case let .ipv4(ipv4):
            self.init(ipv4, port: port, host: host)
        case let .ipv6(ipv6):
            self.init(ipv6, port: port, host: host)
        }
    }
}

extension ByteBuffer {
    /// Write `ip` into this `ByteBuffer`, moving the writer index forward appropriately.
    ///
    /// - parameters:
    ///   - ip: The IP ip to write.
    ///   - returns: The number of bytes written.
    @discardableResult
    public mutating func write(ip: IP) -> Int {
        let written = self.set(ip: ip, at: self.writerIndex)
        self.moveWriterIndex(forwardBy: written)
        return written
    }
    
    /// Write `ip` into this `ByteBuffer` at `index`. Does not move the writer index.
    ///
    ///  - parameters:
    ///    - ip: The IPv4 ip to write.
    ///    - index: The index for the first serialized byte.
    ///  - returns: The number of bytes written.
    ///  - precondition: `index` must not be negative.
    @discardableResult
    public mutating func set(ip: IP, at index: Int) -> Int {
        precondition(index >= 0, "index must not be negative")
        switch ip {
        case let .ipv4(ipv4): return set(ipv4: ipv4, at: index)
        case let .ipv6(ipv6): return set(ipv6: ipv6, at: index)
        }
    }
}
