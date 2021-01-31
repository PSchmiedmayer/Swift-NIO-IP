import NIO


/// An IPv6 address
public struct IPv6 {
    typealias IPv6SocketAddress = sockaddr_in6
    fileprivate let rawIPv6: in6_addr
    
    fileprivate var uint16Split: [UInt16] {
        var uint8Split = Array(repeating: UInt8(0), count: 16)
        #if os(Linux)
        let cTuple = rawIPv6.__in6_u.__u6_addr8
        #else
        let cTuple = rawIPv6.__u6_addr.__u6_addr8
        #endif
        (
            uint8Split[0], uint8Split[1], uint8Split[2], uint8Split[3],
            uint8Split[4], uint8Split[5], uint8Split[6], uint8Split[7],
            uint8Split[8], uint8Split[9], uint8Split[10], uint8Split[11],
            uint8Split[12], uint8Split[13], uint8Split[14], uint8Split[15]
        ) = cTuple
        var uint16Split = Array(repeating: UInt16(0), count: uint8Split.count / 2)
        for index in 0..<uint16Split.count {
            uint16Split[index] = UInt16(uint8Split[(index * 2) + 1]) << 8 | UInt16(uint8Split[index * 2])
        }
        return uint16Split
    }
    
    /// Create an `IPv6` address based on a system address
    /// - Parameter address: The system address used to initailize the `IPv6` address
    public init(_ address: in6_addr) {
        self.rawIPv6 = address
    }
    
    /// Creat an `IPv6` address based on a `String` representation
    /// - Parameter stringRepresentation: The `String` representation to create the `IPv6`
    /// - Throws: Throws an error if the address could not be created based on the `String`.
    public init(_ stringRepresentation: String) throws {
        guard let ipv6Addr = try stringRepresentation.withCString({ cString -> in6_addr? in
            var ipv6Addr = in6_addr()
            guard inet_pton(AF_INET6, cString, &ipv6Addr) == 1 else {
                throw SocketAddressError.failedToParseIPString(stringRepresentation)
            }
            return ipv6Addr
        }) else {
            throw SocketAddressError.failedToParseIPString(stringRepresentation)
        }
        self.init(ipv6Addr)
    }
    
    func socketAddress(withPort port: UInt16) -> IPv6SocketAddress {
        var socketAddress = sockaddr_in6()
        socketAddress.sin6_family = sa_family_t(AF_INET6)
        socketAddress.sin6_port = port.bigEndian
        socketAddress.sin6_flowinfo = 0
        socketAddress.sin6_addr = rawIPv6
        socketAddress.sin6_scope_id = 0
        return socketAddress
    }
}

extension IPv6: CustomStringConvertible {
    public var description: String {
        return uint16Split
            .map { String($0.bigEndian, radix: 16) }
            .joined(separator: ":")
    }
}

extension IPv6: Equatable {
    public static func == (lhs: IPv6, rhs: IPv6) -> Bool {
        #if os(Linux)
        return lhs.rawIPv6.__in6_u.__u6_addr32 == rhs.rawIPv6.__in6_u.__u6_addr32
        #else
        return lhs.rawIPv6.__u6_addr.__u6_addr32 == rhs.rawIPv6.__u6_addr.__u6_addr32
        #endif
    }
}

extension IPv6: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(uint16Split)
    }
}

extension SocketAddress {
    /// Creates a new IPv6 `SocketAddress`.
    ///
    /// - parameters:
    ///   - addr: the `IPv6` that holds the IPv6 address.
    ///   - port: The target port.
    ///   - host: the hostname that resolved to the IPv6 address.
    public init(_ ipv6: IPv6, port: UInt16, host: String) {
        self.init(ipv6.socketAddress(withPort: port), host: host)
    }
}


extension ByteBuffer {
    /// Write an IPv6 address (`ipv6`) into this `ByteBuffer`, moving the writer index forward appropriately.
    ///
    /// - parameters:
    ///   - ipv6: The IPv6 address to write.
    /// - returns: The number of bytes written.
    @discardableResult
    public mutating func write(ipv6: IPv6) -> Int {
        let written = self.set(ipv6: ipv6, at: self.writerIndex)
        self.moveWriterIndex(forwardBy: written)
        return written
    }
    
    /// Write an IPv6 address (`ipv6`) into this `ByteBuffer` at `index`. Does not move the writer index.
    ///
    /// - parameters:
    ///   - ipv6: The IPv6 address to write.
    ///   - index: The index for the first serialized byte.
    /// - returns: The number of bytes written.
    /// - precondition: `index` must not be negative.
    @discardableResult
    public mutating func set(ipv6: IPv6, at index: Int) -> Int {
        precondition(index >= 0, "index must not be negative")
        if capacity - index < MemoryLayout<IPv6>.size {
            reserveCapacity(capacity + MemoryLayout<IPv6>.size)
        }
        
        return ipv6.uint16Split.reduce(index, { $0 + setInteger($1.bigEndian, at: $0, endianness: .big) }) - index
    }
    
    /// Get the IPv6 address at `index` from this `ByteBuffer`. Does not move the reader index.
    /// The selected bytes must be readable or else nil will be returned.
    ///
    /// - note: Please consider using `readIPv6` which is a safer alternative that automatically maintains the
    ///         `readerIndex` and won't allow you to read uninitialized memory.
    /// - warning: This method allows the user to read any of the bytes in the `ByteBuffer`'s storage, including
    ///            _uninitialized_ ones. To use this API in a safe way the user needs to make sure all the requested
    ///            bytes have been written before and are therefore initialized. Note that bytes between (including)
    ///            `readerIndex` and (excluding) `writerIndex` are always initialized by contract and therefore must be
    ///            safe to read.
    /// - parameters:
    ///   - index: The starting index into `ByteBuffer` containing the IPv6 address of interest.
    /// - returns: A `IPv6` address and its byte size deserialized from this `ByteBuffer`  or nil if the bytes of interest are not readable.
    /// - precondition: `index` must not be negative.
    public func getIPv6(at index: Int) -> IPv6? {
        guard index + MemoryLayout<IPv6>.size <= writerIndex else {
            return nil
        }
        
        var in6address = in6_addr()
        withVeryUnsafeBytes { bufferPointer in
            withUnsafeMutableBytes(of: &in6address) { ptr in
                ptr.copyBytes(from: bufferPointer[index ..< index+MemoryLayout<IPv6>.size])
            }
        }
        return IPv6(in6address)
    }
    
    /// Read an `IPv6` address off this `ByteBuffer`.
    ///
    /// Moves the reader index forward by the encoded size of a `IPv6` address.
    ///
    /// - returns: A `IPv6` address deserialized from this `ByteBuffer`  or nil if there aren’t enough bytes readable.
    public mutating func readIPv6() -> IPv6? {
        guard readableBytes >= MemoryLayout<IPv6>.size else {
            return nil
        }
        
        var in6address = in6_addr()
        _ = readWithUnsafeReadableBytes { bufferPointer in
            withUnsafeMutableBytes(of: &in6address) { ptr in
                ptr.copyBytes(from: bufferPointer[0..<MemoryLayout<IPv6>.size])
            }
            return MemoryLayout<IPv6>.size
        }
        return IPv6(in6address)
    }
}
