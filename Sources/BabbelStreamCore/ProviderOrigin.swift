import Foundation

/// Scheme, normalized host and effective port form the credential/redirect boundary.
public struct ProviderOrigin: Equatable, Sendable, CustomStringConvertible {
    public let scheme: String
    public let host: String
    public let port: Int

    public init?(_ url: URL) {
        guard let scheme = url.scheme?.lowercased(), ["https", "http"].contains(scheme),
              let host = url.host?.lowercased(), !host.isEmpty,
              url.user == nil, url.password == nil else { return nil }
        self.scheme = scheme
        self.host = host
        self.port = url.port ?? (scheme == "https" ? 443 : 80)
    }

    public var description: String {
        let displayHost = host.contains(":") && !host.hasPrefix("[") ? "[\(host)]" : host
        return "\(scheme)://\(displayHost):\(port)"
    }

    public static func permitsRedirect(from original: URL?, to proposed: URL?) -> Bool {
        guard let original, let proposed,
              let approved = ProviderOrigin(original), let destination = ProviderOrigin(proposed)
        else { return false }
        return approved == destination
    }
}

/// Per-task policy also covers injected sessions; no session-default redirect can bypass it.
final class ProviderRedirectDelegate: NSObject, URLSessionTaskDelegate, Sendable {
    static let shared = ProviderRedirectDelegate()
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        willPerformHTTPRedirection response: HTTPURLResponse,
        newRequest request: URLRequest,
        completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
        completionHandler(ProviderOrigin.permitsRedirect(from: task.originalRequest?.url, to: request.url) ? request : nil)
    }
}
