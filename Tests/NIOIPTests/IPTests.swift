import NIO
@testable import NIOIP
import XCTest


final class IPTests: XCTestCase {
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var byteBuffer: ByteBuffer!
    
    
    override func setUp() {
        super.setUp()
        
        byteBuffer = ByteBufferAllocator().buffer(capacity: Sample.ipsByteSum)
    }
    
    override func tearDown() {
        super.tearDown()
        
        byteBuffer = nil
    }
    
    
    func testInitialization() throws {
        for (description, ip, _) in Sample.ips {
            XCTAssertTrue(try IP(description) == ip)
        }
        
        XCTAssertThrowsError(try IP(""))
        XCTAssertThrowsError(try IP("1234.123.123.123"))
        XCTAssertThrowsError(try IP("..."))
        XCTAssertThrowsError(try IP("0.0.0"))
        XCTAssertThrowsError(try IP("1::1::1"))
    }
    
    func testDescription() throws {
        for (description, _, _) in Sample.ips {
            XCTAssertTrue(try IP(description).description == description)
        }
    }
    
    func testByteBufferWrite() throws {
        for (_, ip, byteRepresentation) in Sample.ips {
            let currentWriterIndex = byteBuffer.writerIndex
            byteBuffer.write(ip: ip)
            XCTAssertTrue(byteBuffer.writerIndex == currentWriterIndex + byteRepresentation.count)
            XCTAssertTrue(byteBuffer.getBytes(at: currentWriterIndex, length: byteRepresentation.count) == byteRepresentation)
        }
    }
    
    func testByteBufferSet() throws {
        var currentIndex = byteBuffer.writerIndex
        for (_, ip, byteRepresentation) in Sample.ips {
            currentIndex += byteBuffer.set(ip: ip, at: currentIndex)
            byteBuffer.moveWriterIndex(forwardBy: byteRepresentation.count)
            XCTAssertTrue(byteBuffer.getBytes(at: currentIndex - byteRepresentation.count, length: byteRepresentation.count) == byteRepresentation)
            byteBuffer.moveReaderIndex(forwardBy: byteRepresentation.count)
        }
    }
    
    func testByteBufferGet() throws {
        XCTAssertNil(byteBuffer.getIPv4(at: byteBuffer.readerIndex))
        XCTAssertNil(byteBuffer.getIPv6(at: byteBuffer.readerIndex))
        
        var currentIndex = byteBuffer.writerIndex
        for (_, ip, byteRepresentation) in Sample.ips {
            byteBuffer.setBytes(byteRepresentation, at: currentIndex)
            byteBuffer.moveWriterIndex(forwardBy: byteRepresentation.count)
            let gotIP: IP
            switch ip {
            case .ipv4:
                let ipv4 = try XCTUnwrap(byteBuffer.getIPv4(at: currentIndex))
                currentIndex += MemoryLayout<IPv4>.size
                gotIP = .ipv4(ipv4)
            case .ipv6:
                let ipv6 = try XCTUnwrap(byteBuffer.getIPv6(at: currentIndex))
                currentIndex += MemoryLayout<IPv4>.size
                gotIP = .ipv6(ipv6)
            }
            XCTAssertTrue(ip == gotIP)
        }
        XCTAssertTrue(byteBuffer.readerIndex == 0)
    }
    
    func testByteBufferRead() throws {
        XCTAssertNil(byteBuffer.readIPv4())
        XCTAssertNil(byteBuffer.readIPv6())
        
        for (_, ip, byteRepresentation) in Sample.ips {
            let currentReaderIndex = byteBuffer.readerIndex
            byteBuffer.writeBytes(byteRepresentation)
            let gotIP: IP
            switch ip {
            case .ipv4:
                let ipv4 = try XCTUnwrap(byteBuffer.readIPv4())
                gotIP = .ipv4(ipv4)
                XCTAssertTrue(byteBuffer.readerIndex == currentReaderIndex + MemoryLayout<IPv4>.size)
            case .ipv6:
                let ipv6 = try XCTUnwrap(byteBuffer.readIPv6())
                gotIP = .ipv6(ipv6)
                XCTAssertTrue(byteBuffer.readerIndex == currentReaderIndex + MemoryLayout<IPv6>.size)
            }
            XCTAssertTrue(ip == gotIP)
        }
        XCTAssertTrue(byteBuffer.writerIndex == byteBuffer.readerIndex)
    }
}
