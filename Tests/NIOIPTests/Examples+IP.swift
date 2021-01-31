import NIO
@testable import NIOIP

enum Sample {
    static let ipsByteSum = MemoryLayout<IPv4>.size * Sample.numberOfIPv4sInSample + MemoryLayout<IPv6>.size * Sample.numberOfIPv6sInSample
    
    private static let numberOfIPv4sInSample: Int = {
        Sample.ips.reduce(0, {
            if case .ipv4 = $1.ip {
                return $0 + 1
            } else {
                return $0
            }
        })
    }()
    
    private static let numberOfIPv6sInSample: Int = {
        Sample.ips.reduce(0, {
            if case .ipv6 = $1.ip {
                return $0 + 1
            } else {
                return $0
            }
        })
    }()
    
    // swiftlint:disable:next large_tuple
    static let ips: [(description: String, ip: IP, byteRepresentation: [UInt8])] = [
        (
            "0.0.0.0",
            .ipv4(IPv4(in_addr(s_addr: 0))),
            [0, 0, 0, 0]
        ),
        (
            "255.255.255.255",
            .ipv4(IPv4(in_addr(s_addr: UInt32(0xFFFFFFFF as UInt32).bigEndian))),
            [255, 255, 255, 255]
        ),
        (
            "192.168.0.0",
            .ipv4(IPv4(in_addr(s_addr: UInt32(0xC0A80000 as UInt32).bigEndian))),
            [192, 168, 0, 0]
        ),
        (
            "128.237.190.79",
            .ipv4(IPv4(in_addr(s_addr: UInt32(0x80EDBE4F as UInt32).bigEndian))),
            [128, 237, 190, 79]
        ),
        (
            "128.237.176.1",
            .ipv4(IPv4(in_addr(s_addr: UInt32(0x80EDB001 as UInt32).bigEndian))),
            [128, 237, 176, 1]
        ),
        (
            "0:0:0:0:0:0:0:0",
            .ipv6(IPv6(Sample.createIn6Addr((0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)))),
            [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        ),
        (
            "ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff",
            .ipv6(IPv6(Sample.createIn6Addr((0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff)))),
            [0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]
        ),
        (
            "2001:db8:85a3:0:0:8a2e:370:7334",
            .ipv6(IPv6(Sample.createIn6Addr((0x20, 0x01, 0x0d, 0xb8, 0x85, 0xa3, 0x0, 0x0, 0x0, 0x0, 0x8a, 0x2e, 0x03, 0x70, 0x73, 0x34)))),
            [0x20, 0x01, 0x0d, 0xb8, 0x85, 0xa3, 0x0, 0x0, 0x0, 0x0, 0x8a, 0x2e, 0x03, 0x70, 0x73, 0x34]
        ),
        (
            "a458:2bc9:d20f:48c3:2d85:2c9:e1b3:d52",
            .ipv6(IPv6(Sample.createIn6Addr((0xa4, 0x58, 0x2b, 0xc9, 0xd2, 0x0f, 0x48, 0xc3, 0x2d, 0x85, 0x2, 0xc9, 0xe1, 0xb3, 0xd, 0x52)))),
            [0xa4, 0x58, 0x2b, 0xc9, 0xd2, 0x0f, 0x48, 0xc3, 0x2d, 0x85, 0x2, 0xc9, 0xe1, 0xb3, 0xd, 0x52]
        ),
        (
            "ce74:da6:fc56:a377:f1e8:cb09:4f29:b37e",
            .ipv6(IPv6(Sample.createIn6Addr((0xce, 0x74, 0xd, 0xa6, 0xfc, 0x56, 0xa3, 0x77, 0xf1, 0xe8, 0xcb, 0x09, 0x4f, 0x29, 0xb3, 0x7e)))),
            [0xce, 0x74, 0xd, 0xa6, 0xfc, 0x56, 0xa3, 0x77, 0xf1, 0xe8, 0xcb, 0x09, 0x4f, 0x29, 0xb3, 0x7e]
        )
    ]
    
    // swiftlint:disable:next large_tuple
    private static func createIn6Addr(_ tuple: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8,
        UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8)) -> in6_addr {
        #if os(Linux)
        return in6_addr(__in6_u: in6_addr.__Unnamed_union___in6_u(__u6_addr8: tuple))
        #else
        return in6_addr(__u6_addr: in6_addr.__Unnamed_union___u6_addr(__u6_addr8: tuple))
        #endif
    }
}
