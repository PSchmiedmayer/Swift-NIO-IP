/// Errors that can be thrown when dealing with `ByteBufferError`'s read and get methods.
public enum ByteBufferError: Error {
    /// Thrown if a read operation is trying to read the uninitialized memory of a `ByteBuffer`, reading beyond the writerIndex.
    case uninitializedMemory
    
    /// Thrown if a get operation is trying to get bytes that are not contained in the `ByteBuffer` (e.g. `index` is larger then the capacity).
    case notEnoughBytes
    
    /// Errors that can be thrown when decoding an instance from a `ByteBuffer`.
    case decodingFailed(reason: String?)
}


extension ByteBufferError: Equatable {
    public static func == (lhs: ByteBufferError, rhs: ByteBufferError) -> Bool {
        switch (lhs, rhs) {
        case (.uninitializedMemory, .uninitializedMemory):
            return true
        case (.notEnoughBytes, .notEnoughBytes):
            return true
        case let (.decodingFailed(lhsReason), .decodingFailed(rhsReason)):
            return lhsReason?.lowercased() == rhsReason?.lowercased()
        default:
            return false
        }
    }
}
