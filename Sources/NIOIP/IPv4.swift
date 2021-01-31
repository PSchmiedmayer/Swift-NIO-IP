import NIO


/// An IPv4 address
public struct IPv4 {
    typealias IPv4SocketAddress = sockaddr_in
    fileprivate let rawIPv4: in_addr
    
    /// Create an `IPv4` address based on a system address
    /// - Parameter address: The system address used to initailize the `IPv4` address
    public init(_ address: in_addr) {
        self.rawIPv4 = address
    }
    
    /// Creat an `IPv4` address based on a `String` representation
    /// - Parameter stringRepresentation: The `String` representation to create the `IPv4`
    /// - Throws: Throws an error if the address could not be created based on the `String`.
    public init(_ stringRepresentation: String) throws {
        guard let ipv4Addr = try stringRepresentation.withCString({ cString -> in_addr? in
            var ipv4Addr = in_addr()
            guard inet_pton(AF_INET, cString, &ipv4Addr) == 1 else {
                throw SocketAddressError.failedToParseIPString(stringRepresentation)
            }
            return ipv4Addr
        }) else {
            throw SocketAddressError.failedToParseIPString(stringRepresentation)
        }
        self.init(ipv4Addr)
    }
    
    func socketAddress(withPort port: UInt16) -> IPv4SocketAddress {
        var socketAddress = sockaddr_in()
        socketAddress.sin_family = sa_family_t(AF_INET)
        socketAddress.sin_port = port.bigEndian
        socketAddress.sin_addr = rawIPv4
        return socketAddress
    }
}

extension IPv4: CustomStringConvertible {
    public var description: String {
        stride(from: 0, through: 24, by: 8)
            .map {
                UInt8(truncatingIfNeeded: rawIPv4.s_addr >> $0)
            }
            .map {
                String($0, radix: 10)
            }
            .joined(separator: ".")
    }
}

extension IPv4: Equatable {
    public static func == (lhs: IPv4, rhs: IPv4) -> Bool {
        lhs.rawIPv4.s_addr == rhs.rawIPv4.s_addr
    }
}

extension IPv4: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(rawIPv4.s_addr)
    }
}

extension SocketAddress {
    /// Creates a new IPv4 `SocketAddress`.
    ///
    /// - parameters:
    ///   - addr: the `IPv4` that holds the IPv4 address.
    ///   - port: The target port.
    ///   - host: the hostname that resolved to the IPv4 address.
    public init(_ ipv4: IPv4, port: UInt16, host: String) {
        self.init(ipv4.socketAddress(withPort: port), host: host)
    }
}


extension ByteBuffer {
    /// Write an IPv4 address (`ipv4`) into this `ByteBuffer`, moving the writer index forward appropriately.
    ///
    /// - parameters:
    ///   - ipv4: The IPv4 address to write.
    /// - returns: The number of bytes written.
    @discardableResult
    public mutating func write(ipv4: IPv4) -> Int {
        let written = self.set(ipv4: ipv4, at: self.writerIndex)
        self.moveWriterIndex(forwardBy: written)
        return written
    }
    
    /// Write an IPv4 address (`ipv4`) into this `ByteBuffer`at `index`. Does not move the writer index.
    ///
    /// - parameters:
    ///   - ipv4: The IPv4 address to write.
    ///   - index: The index for the first serialized byte.
    /// - returns: The number of bytes written.
    /// - precondition: `index` must not be negative.
    @discardableResult
    public mutating func set(ipv4: IPv4, at index: Int) -> Int {
        precondition(index >= 0, "index must not be negative")
        return setInteger(ipv4.rawIPv4.s_addr.bigEndian, at: index)
    }
    
    /// Get the IPv4 address at `index` from this `ByteBuffer`. Does not move the reader index.
    ///
    /// - note: Please consider using `readIPv4` which is a safer alternative that automatically maintains the
    ///         `readerIndex` and won't allow you to read uninitialized memory.
    /// - warning: This method allows the user to read any of the bytes in the `ByteBuffer`'s storage, including
    ///            _uninitialized_ ones. To use this API in a safe way the user needs to make sure all the requested
    ///            bytes have been written before and are therefore initialized. Note that bytes between (including)
    ///            `readerIndex` and (excluding) `writerIndex` are always initialized by contract and therefore must be
    ///            safe to read.
    /// - parameters:
    ///    - index: The starting index into `ByteBuffer` containing the IPv4 address of interest.
    /// - returns: A `IPv4` address and its byte size deserialized from this `ByteBuffer`
    /// - throws: Throws a `ByteBufferError` if reading or decoding failed.
    /// - precondition: `index` must not be negative.
    public func getIPv4(at index: Int) throws -> (address: IPv4, byteSize: Int) {
        guard let rawIPv4: UInt32 = getInteger(at: index) else {
            throw ByteBufferError.notEnoughBytes
        }
        return (IPv4(in_addr(s_addr: rawIPv4.bigEndian)), MemoryLayout<UInt32>.size)
    }
    
    /// Read an `IPv4` address off this `ByteBuffer`.
    ///
    /// Moves the reader index forward by the encoded size of a `IPv4` address.
    ///
    /// - returns: A `IPv4` address deserialized from this `ByteBuffer`.
    /// - throws: Throws a `ByteBufferError` if reading or decoding failed.
    public mutating func readIPv4() throws -> IPv4 {
        guard let rawIPv4: UInt32 = readInteger() else {
            throw ByteBufferError.notEnoughBytes
        }
        return IPv4(in_addr(s_addr: rawIPv4.bigEndian))
    }
}
