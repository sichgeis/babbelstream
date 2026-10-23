import Darwin
import Foundation

/// Real URLSession redirect delivery cannot be faithfully simulated by URLProtocol.
/// This server binds only an ephemeral loopback port and handles synthetic fixtures.
final class LoopbackHTTPFixture: @unchecked Sendable {
    private let socketFD: Int32
    private let lock = NSLock()
    private var stopped = false
    private var received = 0
    private let finished = DispatchGroup()
    let port: UInt16
    var count: Int { lock.lock(); defer { lock.unlock() }; return received }
    var baseURL: URL { URL(string: "http://127.0.0.1:\(port)")! }

    init(response: @escaping @Sendable (Data) -> (Int, [String: String], Data)) throws {
        let fd = socket(AF_INET, SOCK_STREAM, 0)
        socketFD = fd
        guard fd >= 0 else { throw URLError(.cannotConnectToHost) }
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        let bindResult = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { Darwin.bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
        }
        guard bindResult == 0, listen(fd, 4) == 0 else {
            Darwin.close(fd); throw URLError(.cannotConnectToHost)
        }
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        _ = withUnsafeMutablePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(fd, $0, &length) }
        }
        port = UInt16(bigEndian: address.sin_port)
        finished.enter()
        DispatchQueue.global().async { [self] in
            defer { finished.leave() }
            while true {
                let client = accept(socketFD, nil, nil)
                lock.lock(); let shouldStop = stopped; lock.unlock()
                if shouldStop { if client >= 0 { Darwin.close(client) }; return }
                guard client >= 0 else { continue }
                var noPipe: Int32 = 1
                _ = setsockopt(client, SOL_SOCKET, SO_NOSIGPIPE, &noPipe, socklen_t(MemoryLayout<Int32>.size))
                var timeout = timeval(tv_sec: 3, tv_usec: 0)
                _ = setsockopt(client, SOL_SOCKET, SO_RCVTIMEO, &timeout, socklen_t(MemoryLayout<timeval>.size))
                var request = Data()
                var buffer = [UInt8](repeating: 0, count: 8192)
                while request.count < 2_000_000 {
                    let bytes = recv(client, &buffer, buffer.count, 0)
                    if bytes <= 0 { break }
                    request.append(contentsOf: buffer.prefix(bytes))
                    if let end = request.range(of: Data("\r\n\r\n".utf8)) {
                        let headers = String(decoding: request[..<end.lowerBound], as: UTF8.self)
                        let contentLength = headers.components(separatedBy: "\r\n").first { $0.lowercased().hasPrefix("content-length:") }.flatMap { Int($0.split(separator: ":").last!.trimmingCharacters(in: .whitespaces)) } ?? 0
                        if request.count >= end.upperBound + contentLength { break }
                    }
                }
                lock.lock(); received += 1; lock.unlock()
                let (status, headers, body) = response(request)
                let headerText = headers.map { "\($0.key): \($0.value)\r\n" }.joined()
                var bytes = Data("HTTP/1.1 \(status) Fixture\r\n\(headerText)Content-Length: \(body.count)\r\nConnection: close\r\n\r\n".utf8)
                bytes.append(body)
                bytes.withUnsafeBytes { pointer in
                    var sent = 0
                    while sent < bytes.count {
                        let amount = Darwin.send(client, pointer.baseAddress!.advanced(by: sent), bytes.count - sent, 0)
                        if amount <= 0 { break }
                        sent += amount
                    }
                }
                Darwin.close(client)
            }
        }
    }

    func stop() {
        lock.lock(); stopped = true; lock.unlock()
        // Darwin does not reliably wake a listening accept with shutdown alone.
        let wake = socket(AF_INET, SOCK_STREAM, 0)
        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_addr.s_addr = inet_addr("127.0.0.1")
        address.sin_port = port.bigEndian
        _ = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(wake, $0, socklen_t(MemoryLayout<sockaddr_in>.size)) }
        }
        Darwin.close(wake)
        check(finished.wait(timeout: .now() + 4) == .success, "Loopback fixture must stop within its deadline.")
        Darwin.close(socketFD)
    }
}
